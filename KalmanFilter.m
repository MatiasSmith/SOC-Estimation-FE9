
%--------------------------------------------------------------------------
% At time k-1
%--------------------------------------------------------------------------

% k = (time value);
% T = (value);
T = 0.1;   %Sampling Period
R0 = 0.01;
Rc = 0.015;
Ccap = 2400;
Cbat = 18000;
Voc0 = 3.435;
alp = 0.65;

V = [0.3, 0.6, 0.5, 0.4, 0.5, 0.3, 0.6, 0.4]
t = [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7]
t = [0:length-1];

xhatk_1 = [SOC; Vc];
%I is measured

Aprime1 = [1, 0; 0, -T/(Cc*Rc)]     %A' 
Cprime = [2.04, 0]                  %VOC(SOC);
Eprime1 = [1, 0; 0, 1]              %E'
Fprime1 = [1, 0; 0, 1]              %F'
Rk = 1E-4;

Qk1 = [2.5*10^(-7), 0; 0, 0]

xhat = zeros(2, n)                  %Initializing 
xhat(1) = 1;
P = zeros(2, 2, n);
P(1:2, 1:2, 1) = Rk * eye(2);       %P starts of as n 2x2 identity matricies

%--------------------------------------------------------------------------
% At time k
%--------------------------------------------------------------------------

VOC = @(SOC)                                      %Need equation for voc in terms of SOC 

yk = @(V, Voc0) V - Voc0;                         %yk: Actual Voltage

hk = @(xhat, I) VOC(xhat(1, 1)) - R0*I;           %hk: Cacluated Voltage?

fk = @(xhatk_1, I) xhatk_1 + dt * [-I / Cbat; (I / Ccap)  - (Vc / (Ccap * Rc))];  %xhat = previous xhat + change in xhat in time: dt     %XHAT IS A DERIVATIVEEEE


%Iterate for each sample
for i = 0:n                                               %Not sure if this I is offset
    [xhat(:, i+1), P(:, :, i+1)] = EKF(xhat(:, i), P(:, :, i), I+1, I, V, Voc0, Rk, Aprime, Cprime, Eprime, Fprime)


end



%Calculate next xhat and P using the previous ones
function [xhatCorrected, PCorrected] = EKF(xhatk_1, Pk_1, I, Ik_1 , V, Voc0, Rk, Aprime, Cprime, Eprime, Fprime)

    xhat = fk(xhatk_1, Ik_1, 0);
    P = Aprime * Pk_1 * Aprime.' + Eprime * Qk1 * Eprime.';
    Lk = P * Cprime.' * inv(Cprime * Pk_1 * Cprime.' + Fprime * Rk * Fprime.');
    xhatCorrected = xhat + Lk * (yk(V, Voc0) - hk(xhat, I));
    PCorrected = P - Lk * Cprime * Pk_1;
end

