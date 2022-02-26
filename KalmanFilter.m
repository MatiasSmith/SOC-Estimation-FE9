
clc;
%clear;
%close all;
%formatlatex
format longG
warning('off',  'all')
mkdir('./Figures')
warning('on',  'all')


%--------------------------------------------------------------------------
% At time k-1
%--------------------------------------------------------------------------

%
% Constants
% k = (time value);
% T = (value);
dt = 1;   %Sampling Period
R0 = 0.01;
Rc = 150;        %0.015;
Ccap = 0.15;     %2400;
Cbat = 1;        %18000;
Voc0 = 3.435;
alp = 0.65;

%
%Some random test data I made
%
%Samples = 100;
%actualSOC = ones(1, Samples);
%V = ones(1, Samples);
%I = ones(1, Samples);
%timeSteps = ones(1, Samples);
%for i = 1:Samples
%    actualSOC(i) = actualSOC(i) * (sin(i) - 1*i^0.8 + 0.3*sin(10*i));
%    V(i) = V(i) * (sin(i) + 0.05*i + 0.3*sin(5*i));
%    I(i) = I(i) * (sin(i) + 0.05*i + 0.5*sin(2*i));
%    timeSteps(i) = i*0.1

%end

%
%Simulation Data goes here
%
actualSOC = VarName2.';                  %[0.3, 0.6, 0.5, 0.4, 0.5, 0.3, 0.6, 0.4]  %Actual SOC
V = VarName3.';                          %[0.3, 0.6, 0.5, 0.4, 0.5, 0.3, 0.6, 0.4];         %Measured Voltage
I = VarName4.';                          %Measured Current
timeSteps = VarName1.';                  %Time
totalTime = length(timeSteps);

%xhatk_1 = [SOC; Vc];
%I is measured

%
% Initializing probability matricies
%
Aprime = [1, 0; 0, exp(-dt/(Ccap*Rc))]     %A' 
Cprime = [2.04, 0]                  %VOC(SOC);
Eprime = [1, 0; 0, 1]              %E'
Fprime = [1, 0; 0, 1]              %F'

%
% Coefficients for probability
%
Rk = 1E-4;
Qk1 = [2.5*10^(-7), 0; 0, 0];

%
% Initializing xhat and P (covariance matrix)
%
arrayOfxhats = zeros(2, totalTime);                  
arrayOfxhats(1) = 1;
arrayOfPs = zeros(2, 2, totalTime);
arrayOfPs(1:2, 1:2, 1) = Rk * eye(2);       %P starts of as n 2x2 identity matricies

%--------------------------------------------------------------------------
% At time k
%--------------------------------------------------------------------------

%Variables Qualitatively                          
%     (Constant) VOC: Open circuit voltage
% (Time variant) Vc: Voltage across capacitor in battery circuit model
% (Time variant) V: Voltage we measure (output from battery circuit model)
%     (Constant) Ccap: Capacitor's capacitance
%     (Constant) Rc: Resistor in parallel with capacitor
%     (Constant) R0: Ohmic resistance
%     (Constant) Cbat: Capacity of battery in AmpHours?
% 

%
% Function we need to calculate
%
VOC = @(SOC, Voc0) 0.009*SOC + Voc0; %????               %Need equation for voc in terms of SOC 

yk = @(V, Voc0) V - Voc0;                         %yk: Actual Voltage

hk = @(xhat, I, Voc0) VOC(xhat(1, 1), Voc0) - R0*I;           %hk: Cacluated Voltage?

fk = @(xhatk_1, I, dt, Cbat, Ccap, Rc) xhatk_1 + dt * [-I / Cbat; (I / Ccap)  - (xhatk_1(2, 1) / (Ccap * Rc))];  %xhat = previous xhat + change in xhat in time: dt     %XHAT IS A DERIVATIVEEEE

%
%Iterate for each sample
% t: Time
% totalTime
for t = 1:totalTime-1                                            %Not sure if this I is offset
    [arrayOfxhats(:, t+1), arrayOfPs(:, :, t+1)] = EKF(arrayOfxhats(:, t), arrayOfPs(:, :, t), I(t+1), I(t), V(t+1), Voc0, Rk, Aprime, Cprime, Eprime, Fprime, fk, dt, Cbat, Ccap, Rc, Qk1, yk, hk);

end

%Plotting
figure
plot(timeSteps, actualSOC, 'DisplayName', "Actual SOC")
hold on
plot(timeSteps, arrayOfxhats(1, :), 'DisplayName', "Extended Kalman Filter")
%plot(t, SOCdr, 'DisplayName', "Open Loop")
ylim = ([72-20, 72+20]);
xlim([0, totalTime/10])
legend
title(["SOC Estimate Using Extended Kalman Filter, Open Loop Estimate and", "Actual SOC vs. Time"])

% Page 14
xlabel("time (s)")
ylabel("SOC")
saveas(gcf, "./Figures/2ekf.jpg")

%Vc should change with time??


%Calculate next xhat and P using the previous ones
function [xhatCorrected, PCorrected] = EKF(xhatk_1, Pk_1, I, Ik_1 , V, Voc0, Rk, Aprime, Cprime, Eprime, Fprime, fk, dt, Cbat, Ccap, Rc, Qk1, yk, hk)

    xhat = fk(xhatk_1, Ik_1, dt, Cbat, Ccap, Rc);
    P = Aprime * Pk_1 * Aprime.' + Eprime * Qk1 * Eprime.';
    Lk = P * Cprime.' * (Cprime * P * Cprime.' + Rk)^-1;
    xhatCorrected = xhat + Lk * (yk(V, Voc0) - hk(xhat, I, Voc0));
    PCorrected = P - Lk * Cprime * P;
end


