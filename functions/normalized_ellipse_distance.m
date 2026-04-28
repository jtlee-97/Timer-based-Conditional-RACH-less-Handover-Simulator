function [dEll, dEll2] = normalized_ellipse_distance(p, c, A, B, theta)
%NORMALIZED_ELLIPSE_DISTANCE Normalized ellipse distance and its squared form.
%   Euclidean distance is NOT used here.
%   dEll2 = (p-c)'*Q*(p-c)
%   dEll  = sqrt(dEll2)
%   Boundary condition is dEll = 1.

    if nargin < 5 || isempty(theta)
        theta = 0;
    end

    p = p(:); c = c(:);
    if numel(p) ~= 2 || numel(c) ~= 2
        error('p and c must be 2D vectors.');
    end

    Q = make_ellipse_Q(A, B, theta);
    d = p - c;
    dEll2 = d' * Q * d;
    dEll2 = max(real(dEll2), 0);
    dEll = sqrt(dEll2);
end
