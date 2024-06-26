function FactorizationMethod(name, noise_percent, N, ht, t, kappa, ffN, hff, tff, quiet)
    switch name
        case 'circle'
            y1     = 3*cos(t);
            y2     = 3*sin(t);
            dy1    = -3*sin(t);
            dy2    =  3*cos(t);
        case 'kite' 
            y1     = 2*cos(t) + 1.3*cos(2*t)-1.3;
            y2     = 3*sin(t);
            dy1    = -2*sin(t) - 1.3*2*sin(2*t);
            dy2    = 3*cos(t);
       case 'cardioid' 
            y1     = 2*((1-cos(t)).*cos(t)+1);
            y2     = 2*(1-cos(t)).*sin(t);
            dy1    = 2*(2*cos(t)-1).*sin(t);
            dy2    = 2*(sin(t).^2 + (1-cos(t)).*cos(t));
        case 'ellipse'
            y1     = 4*cos(t);
            y2     = 2*sin(t);
            dy1    = -4*sin(t);
            dy2    =  2*cos(t);
        otherwise
            warning('Unexpected scattering object.')
            return
    end
    
    ymat1  = repmat(y1,N,1);                        % matrix version of domain points component 1
    ymat2  = repmat(y2,N,1);                        % matrix version of domain points component 2
    dymat1 = repmat(dy1,N,1);                       % matrix version of domain derivative comp.1
    dymat2 = repmat(dy2,N,1);                       % matrix version of domain derivative comp.2
    eps = ht/3.6;                                   % set cut parameter for singularity
    epsmat=eps*ones(N,N);                           % matrix version of cut parameter
    eta = 1;                                        % weight factors for the Brackhage Werner approach
    tau = 0;                                        % weight factors for the Brackhage Werner approach
    rmat1=ymat1.'-ymat1;                            % matrix of point differences component 1
    rmat2=ymat2.'-ymat2;                            % matrix of point differences component 2
    rmat=max(sqrt(rmat1.^2 + rmat2.^2), epsmat);     % matrix of ||x-y||
    drmat=sqrt(dymat1.^2 + dymat2.^2);
    
    %% Potential Operators
    
    S = 1i/2*besselh(0,1,kappa*rmat).*drmat*ht;     % single-layer operator
    K = 1i*kappa/2*(dymat2.*rmat1-dymat1.*rmat2).*besselh(1,1,kappa*rmat)./rmat*ht;           % double-layer operator
    
    %% Solve integral equation
    
    BWinv = inv(tau*(eye(N,N)+ K)-1i*eta*S);        % Brackhage Werner inverse

    %% far field domain
    
    yff1     = cos(tff);
    yff2     = sin(tff);
    yffmat1  = repmat(yff1.',1,N);
    yffmat2  = repmat(yff2.',1,N);
    yfmat1    = repmat(y1,ffN,1);
    yfmat2    = repmat(y2,ffN,1);
    dyfmat1   = repmat(dy1,ffN,1);
    dyfmat2   = repmat(dy2,ffN,1);
    drfmat = sqrt(dyfmat1.^2 + dyfmat2.^2);
    
    %% V Potential Operators ffS, ffK
    
    fac  = exp(1i*pi/4)/sqrt(8*pi*kappa);
    ffS  = fac*exp(-1i*kappa*(yffmat1.*yfmat1+yffmat2.*yfmat2)).*drfmat*ht;
    ffK  = fac*(-1i)*kappa*(yffmat1.*dyfmat2-yffmat2.*dyfmat1).*exp(-1i*kappa*(yffmat1.*yfmat1+yffmat2.*yfmat2))*ht;
    ffBW = (tau*ffK-1i*eta*ffS);                     % far field of Brackhage-Werner potential
    
    %% Setup and evaluate Herglotz wave operator
    
    hmat1   = repmat(y1.',1,ffN).*repmat(yff1,N,1);
    hmat2   = repmat(y2.',1,ffN).*repmat(yff2,N,1);
    HD     = exp(1i*kappa*(hmat1 + hmat2))*hff;      % Herglotz wave operator
    
    %% Setup farfield operator F
    
    F = -2*ffBW*BWinv*HD;

    %% Adds Noise
    noise = false;
    if(noise_percent ~= 0)
        noise = true;
    end
    if(noise)
        p = normrnd(0, norm(F, 2)*noise_percent/2/sqrt(max(size(F))), size(F));
        F_p = F + p;
        F = F_p;
    end
    
    %%
    M1      = 70;                                   % number of points in x1 direction for evaluation
    M2      = 71;                                   % number of points in x2 direction for evaluation
    M       = M1*M2;                                % total number of evaluation points
    a1      = -10;                                  % left border of cuboid
    b1      = 10;                                   % right border of cuboid
    a2      = -10;                                   % bottom border of cuboid
    b2      = 10;                                    % top border of cuboid
    h1      = (b1-a1)/(M1-1);                       % grid size for x1 direction
    q1      = a1:h1:b1;                             % grid points in x1 direction
    h2      = (b2-a2)/(M2-1);                       % grid size for x2 direction
    q2      = a2:h2:b2;                             % grid points in x2 direction
    q1mat   = repmat(q1,M2,1);                      % preparations for building up grid vector
    q2mat   = repmat(q2.',1,M1);                    %
    pvec1   = reshape(q1mat,M,1);                   % definition of x1 coordinates of grid points
    pvec2   = reshape(q2mat,M,1);                   % definition of x2 coordinates of grid points
    
    %% Setup and evaluate far field pattern term f_z

    hmat1   = repmat(pvec1,1,ffN).*repmat(yff1,M,1);
    hmat2   = repmat(pvec2,1,ffN).*repmat(yff2,M,1);
    Phiinf  = exp(-1i*kappa*(hmat1 + hmat2)).';
    
    alphaLS = 1e-8;                                 % regularization parameter
    [U,S,V]=svd(F);                                 % singular value decomposition of F
    A = U*sqrt(S)*V';                               % (F'*F)^(1/4)
    gLS  = (alphaLS*eye(ffN,ffN) + A'*A)\(A'*Phiinf);  % solve equation
    
    wLS = ( 1./sqrt(sum( abs(gLS).^2 )) ).';        % linear sampling functional
    wmax = max(wLS); ca = 4; wLS = ca*wLS / wmax;   % scaling for display
    wLS = min(abs(wLS),ca);                         % cut for better display

    %% Plotting reconstruction

    fo   = figure;
    if(quiet)
        set(fo, 'Visible', 'off');
    end
    wmat = reshape(wLS,M2,M1);                      % prepare function in the format M2 x M1 points
    so   = surf(q1,q2,abs(wmat));                   % plot surface of real part of potential
    shading interp; 
    %ao = get(so,'Parent');                          % graphics interpolated view
    
    hold on; 
    p = plot3(y1,y2,ca*ones(size(y1)),'black--','MarkerSize', 6, 'Displayname', 'True Shape');
    axis equal;
    view(-20,50);     
    view(2); 
    axis([a1 b1 a2 b2 -2 ca+2]); 
    colorbar('FontSize',14); 
    
    set(0,'defaulttextinterpreter','latex');
    set(0,'defaultLineLineWidth',2);
    set(0,'DefaultAxesFontSize',14);
    set(0,'DefaultLegendInterpreter','latex');
    set(gca,'TickLabelInterpreter','latex')
    legend(p);
    
    %% Saves File
    name_string = name;
    if(noise_percent ~= 0)
        name_string = append(name_string, "-", string(noise_percent*100),  "-noise");
    end
    saveas(fo, append([pwd '/Images/'], name_string, '-reconstructed.png'), 'png'); 

end