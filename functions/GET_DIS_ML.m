% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : GET_DIS_ML.m
% Type         : MATLAB function Code
% Author       : Jongtae Lee
% Revision     : v1.2   2026.04.28
% Modified     : 2026.04.28
% =================================================================

% GET_DIS_ML
% - Euclidean mode (legacy, 4 args): physical center distance [m]
% - Ellipse mode   (optional args): normalized footprint distance dEll
%     dEll = sqrt((p-c)'*Q*(p-c)), boundary is dEll = 1
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
            [dEll, ~] = normalized_ellipse_distance([UE_LOC_X; UE_LOC_Y], [BORE_X(i); BORE_Y(i)], A(i), B(i), theta(i));
            ML(i) = dEll;
        end
    else
        for i = 1:num_bores
            ML(i) = sqrt((BORE_X(i) - UE_LOC_X)^2 + (BORE_Y(i) - UE_LOC_Y)^2);
        end
    end
end
