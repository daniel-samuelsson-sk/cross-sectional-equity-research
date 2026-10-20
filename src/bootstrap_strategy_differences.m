function r2 = bootstrap_strategy_differences(series, B, L, seed)
%BOOTSTRAP_STRATEGY_DIFFERENCES
% Quantify uncertainty in paired portfolio-performance differences.
%
% r2 = BOOTSTRAP_STRATEGY_DIFFERENCES(series, B, L, seed)
%
% Uses a paired circular stationary bootstrap to estimate percentile
% confidence intervals for differences in Sharpe ratio, annualized
% volatility and CAGR.
%
% A single bootstrap index matrix is generated and reused across all
% portfolio series. Total and excess returns therefore preserve their
% month-by-month alignment, and every paired comparison is evaluated on
% exactly the same resampled path.


%% Validate input

assert(isstruct(series), ...
    'R2:InvalidSeries', ...
    'series must be the common OOS portfolio-series struct.');

assert(isfield(series, 'portfolio_month'), ...
    'R2:MissingCalendar', ...
    'series.portfolio_month is required.');

T = ...
    numel(series.portfolio_month);

assert(T >= 2, ...
    'R2:InsufficientSample', ...
    'At least two OOS months are required.');


%% Generate common stationary-bootstrap paths

indices = ...
    generate_stationary_bootstrap_indices( ...
        T, ...
        B, ...
        L, ...
        seed);


%% Compute observed and bootstrap statistics

statistics = ...
    compute_bootstrap_comparison_statistics( ...
        series, ...
        indices);


%% Output

r2 = ...
    struct();

r2.observed_levels = ...
    statistics.observed_levels;

r2.summary = ...
    statistics.summary;

r2.bootstrap = ...
    statistics.bootstrap;


%% Method metadata

r2.meta = ...
    struct();

r2.meta.B = ...
    B;

r2.meta.L = ...
    L;

r2.meta.seed = ...
    seed;

r2.meta.T = ...
    T;

r2.meta.method = ...
    "Stationary bootstrap (Politis & Romano, 1994)";

r2.meta.ci_method = ...
    "percentile";

r2.meta.confidence_level = ...
    0.95;

end