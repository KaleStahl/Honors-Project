clear; 
close all; 
clc

%% Constants and stuff

N     = 101;                                    % number of discretization points for curve
ht    = 2*pi/N;                                 % grid size for curve discretization
t     = 0:ht:2*pi-ht;                           % discretization points for curve parametrization
kappa = 4;                                      % wave number
ffN   = 100;                                    % number of discretization points for curve
hff   = 2*pi/ffN;                               % grid size for curve discretization
tff   = (0:hff:2*pi-hff)-pi;   

%% Shape and Noise Level

name =  'circle';
noise_percent = 0;
%% Run Factorization Method Once

FactorizationMethod(name, noise_percent, N, ht, t, kappa, ffN, hff, tff, false);

%% Loop over all noise levels and shapes

shape_list = ["circle", "kite", "ellipse"];
noise_list = 0:.1:1;

for shape = shape_list
    for noise = noise_list
        FactorizationMethod(shape, noise, N, ht, t, kappa, ffN, hff, tff, true);
        disp(append(name,"_", string(noise), "%noise"))
    end
end
