function Q = make_ellipse_Q(A, B, theta)
%MAKE_ELLIPSE_Q Build ellipse shape matrix Q for normalized boundary test.
%   Q satisfies (p-c)'*Q*(p-c)=1 on ellipse boundary.
%   A: semi-major axis [m], B: semi-minor axis [m], theta: rotation [rad].

    if nargin < 3 || isempty(theta)
        theta = 0;
    end
    validateattributes(A, {'numeric'}, {'scalar','real','finite','positive'});
    validateattributes(B, {'numeric'}, {'scalar','real','finite','positive'});
    validateattributes(theta, {'numeric'}, {'scalar','real','finite'});

    R = [cos(theta), -sin(theta); sin(theta), cos(theta)];
    Q = R * diag([1/(A^2), 1/(B^2)]) * R';
end
