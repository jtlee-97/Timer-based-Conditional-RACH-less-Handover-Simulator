% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : GET_DIS_ML.m
% Type         : MATLAB function Code
% Author       : Jongtae Lee
% Revision     : v1.1   2026.04.28
% Modified     : 2026.04.28
% =================================================================

% ML 거리 계산
% 기본: 유클리디안 거리
% 확장: ellipse 인자(A,B,theta) 제공 시 normalized elliptical distance 계산
%   d_ell = sqrt((p-c)^T Q (p-c)), Q = R*diag([1/A^2 1/B^2])*R^T
function ML = GET_DIS_ML(BORE_X, BORE_Y, UE_LOC_X, UE_LOC_Y, A, B, theta)
    num_bores = length(BORE_X);
    ML = zeros(1, num_bores);

    use_ellipse = (nargin >= 7) && ~isempty(A) && ~isempty(B);

    if use_ellipse
        if nargin < 7 || isempty(theta)
            theta = zeros(1, num_bores);
        end

        if isscalar(A), A = repmat(A, 1, num_bores); end
        if isscalar(B), B = repmat(B, 1, num_bores); end
        if isscalar(theta), theta = repmat(theta, 1, num_bores); end

        for i = 1:num_bores
            dx = BORE_X(i) - UE_LOC_X;
            dy = BORE_Y(i) - UE_LOC_Y;
            ang = theta(i);
            Rm = [cos(ang), -sin(ang); sin(ang), cos(ang)];
            Q = Rm * diag([1/(A(i)^2), 1/(B(i)^2)]) * Rm';
            ML(i) = sqrt([dx, dy] * Q * [dx; dy]);
        end
    else
        for i = 1:num_bores
            ML(i) = sqrt((BORE_X(i) - UE_LOC_X)^2 + (BORE_Y(i) - UE_LOC_Y)^2);
        end
    end
end
