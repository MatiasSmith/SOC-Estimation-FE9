
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

% xk1_k1 = (value);
% uk1 = (value);

% Pk1_k1 = (value);
% Aprime_k1 = (matrix);
% Eprime_k1 = (matrix);
% Qk1 = (value or matrix);

%--------------------------------------------------------------------------
% At time k
%--------------------------------------------------------------------------

k = k+1;

% fk(xk1_k1, uk1, 0) = (function definition);

% Cprime_k = (matrix);
% Fprime_k = (matrix);
% Rk = (value);

% yk = (value or matrix);
% uk = (value);
% hk(xk_k1, uk, 0) = (function definition);

Aprime_k1 = [1, 0; 0, -T/(Cc*Rc)]
Eprime_k1 = [1, 0; 0, 1]
Fprime_k1 = [1, 0; 0, 1]

Qk1 = [2.5*10^(-7), 0; 0, 0]


function [xk_k, Pk_k] = EKF(xk1_k1, uk1, Pk1_k1, )

    xk_k1 = fk(xk1_k1, uk1, 0);
    Pk_k1 = Aprime_k1 * Pk1_k1 * transpose(Aprime_k1) + Eprime_k1 * Qk1 * transpose(Eprime_k1);
    Lk = Pk_k1 * transpose(Cprime_k) * inv(Cprime_k * Pk_k1 * transpose(Cprime_k) + Fprime_k * Rk * transpose(Fprime_k));
    xk_k = xk_k1 + Lk * (yk - hk(xk_k1, uk, 0));
    Pk_k = Pk_k1 - Lk * Cprime_k * Pk_k1;
end

function 
