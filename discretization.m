%% Discretization example for FSAE folks 
clc; clear; close all;

%% Analytical solution

dt = 0.01;
td = 0:dt:10;
ta = 0:0.01:10;

%% PARAMETERS
It = 0.01;
Rc = 150;
Cc = 0.015;
Cbat = 1; % Amp * s

soc = zeros(length(td), 1); % x(1) = 0
v = zeros(length(td), 1); % v(1) = 0
soc(1) = 1;
v(1) = 0;

for i = 1:length(td)
    if mod(i,100) == 0
        if It == 0
            It = 0.01
        else
            It = 0
        end
    end
    if i ~= length(td)
        soc(i+1) = soc_discrete(soc(i), dt, It, Cbat);
        v(i+1) = voltage_discrete(v(i), dt, It, Cc, Rc);
    end
%     error_soc(i) = soc(i) - position_analytical(td(i));
%     error_v(i) = v(i) - velocity_analytical(td(i));
end

figure
subplot(2, 1, 1)
plot(td, soc)
hold on
%plot(ta, position_analytical(ta), '--');
xlabel("Time (s)")
ylabel("SoC (%)")
legend("Discrete")%, "Analytical")
subplot(2, 1, 2)
plot(td, v)
hold on
%plot(ta, velocity_analytical(ta), '--');
xlabel("Time (s)")
ylabel("Voltage (V)")
legend("Discrete")%, "Analytical")

% figure
% plot(td, error_v)
% hold on
% plot(td, error_soc)

%%
clear soc

%for i = 1:length(td)-1
%    x(:, i+1) = forward_euler(@falling_body_equations, x(i), dt);
%end

% figure
% subplot(2, 1, 1)
% plot(td, soc(1, :))
% hold on
% plot(ta, position_analytical(ta), '--');
% xlabel("Time (s)")
% ylabel("Position (m)")
% legend("Discrete", "Analytical")
% subplot(2, 1, 2)
% plot(td, v(2, :))
% hold on
% plot(ta, velocity_analytical(ta), '--');
% xlabel("Time (s)")
% ylabel("Velocity (m/s)")
% legend("Discrete", "Analytical")

%% Discrete solution to d/dt(soc) = - It / Cbat; d/dt(v) = (It / Cc) - v / (Cc * Rc);
% Using finite difference (x_{k+1} - x_{k})/dt approx d/dt(x)

function sockp1 = soc_discrete(sock, dt, It, Cbat)
    sockp1 = sock - dt * (It / Cbat);
end

function vkp1 = voltage_discrete(vk, dt, It, Cc, Rc)
    vkp1 = vk + dt * ((It / Cc) - vk / (Cc * Rc));
end

%% Solution to d/dt(soc) = - It / Cbat; d/dt(v) = (It / Cc) - v / (Cc * Rc);

function x = position_analytical(t)
    x = exp(-t) + 2*t - 1;
end

function v = velocity_analytical(t)
    v = -exp(-t) + 2;
end

%% Falling body equations
function xdot = falling_body_equations(x)
    % x is a vector, x(1) = x, x(2) = v
    v = x(2);
    xdot(1) = x(2);
    xdot(2) = 2 - x(2);
end

%% Forward euler solver
function xkp1 = forward_euler(xdot, xk, dt)
    xkp1 = xdot(xk) * dt + xk;
end