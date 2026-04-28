function fit = fit_ellipse_from_points(points)
%FIT_ELLIPSE_FROM_POINTS Robust PCA/covariance-based ellipse approximation.
% Input:
%   points: Nx2 boundary points sampled from an ellipse-like contour.
% Output struct:
%   A, B, theta, center, Q, method
%
% Method:
%   1) center = mean(points)
%   2) PCA eigenvectors => orientation theta
%   3) Rotate points to principal axis
%   4) Set semi-axes from max absolute extents in principal coordinates
% This is numerically stable and avoids fragile algebraic conic fitting.

    if size(points,2) ~= 2 || size(points,1) < 5
        error('points must be Nx2 with N>=5');
    end

    ctr = mean(points, 1);
    X = points - ctr;

    C = cov(X);
    [V, D] = eig(C);
    [~, idx] = sort(diag(D), 'descend');
    V = V(:, idx);

    theta = atan2(V(2,1), V(1,1));
    Xp = (V' * X')';

    A = max(abs(Xp(:,1)));
    B = max(abs(Xp(:,2)));

    A = max(A, 1e-6);
    B = max(B, 1e-6);

    if B > A
        tmp = A; A = B; B = tmp;
        theta = theta + pi/2;
    end

    fit = struct();
    fit.A = A;
    fit.B = B;
    fit.theta = theta;
    fit.center = ctr(:);
    fit.Q = make_ellipse_Q(A, B, theta);
    fit.method = 'pca_extent';
end
