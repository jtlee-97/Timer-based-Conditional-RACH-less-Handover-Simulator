function [order, score, detail] = rank_candidates_tscho(cand, weights)
%RANK_CANDIDATES_TSCHO Rank TS-CHO candidates with configurable scoring.
% cand fields (vectors, same length):
%   rsrp, pred_stay, exec_time, t_exit_serving, prepared_mask(optional)
% weights fields:
%   w_rsrp, w_stay, w_time

    if nargin < 2 || isempty(weights)
        weights = struct('w_rsrp', 0.4, 'w_stay', 0.4, 'w_time', 0.2);
    end
    n = numel(cand.rsrp);

    rsrp_n = normalize01(cand.rsrp);
    stay_n = normalize01(cand.pred_stay);
    dt = abs(cand.exec_time - cand.t_exit_serving);
    dt_n = normalize01(dt);

    score = weights.w_rsrp * rsrp_n + ...
            weights.w_stay * stay_n - ...
            weights.w_time * dt_n;

    [~, order] = sort(score, 'descend');

    detail = struct();
    detail.rsrp_n = rsrp_n;
    detail.stay_n = stay_n;
    detail.dt_n = dt_n;

    if isfield(cand, 'prepared_mask')
        top = order(1);
        detail.candidate_miss = ~cand.prepared_mask(top);
    else
        detail.candidate_miss = false;
    end
end

function x = normalize01(x)
    x = x(:).';
    xmin = min(x);
    xmax = max(x);
    if abs(xmax - xmin) < 1e-12
        x = zeros(size(x));
    else
        x = (x - xmin) / (xmax - xmin);
    end
end
