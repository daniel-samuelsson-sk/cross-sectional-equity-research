function cfg = default_config()
%DEFAULT_CONFIG Default research specification.
%
% The configuration defines the economic and methodological rules of the
% research pipeline. Provider-specific implementation details must not be
% stored here.


%% Research periods

cfg.periods.calibration_start = ...
    datetime(1981,1,31);

cfg.periods.calibration_end = ...
    datetime(1989,12,31);

cfg.periods.evaluation_start = ...
    datetime(1990,1,31);

cfg.periods.evaluation_end = ...
    datetime(2023,12,31);


%% Formation universe

cfg.universe.min_observed_history_months = ...
    0;


%% Momentum signal

cfg.signals.momentum.start_lag_months = ...
    12;

cfg.signals.momentum.end_lag_months = ...
    2;

cfg.signals.momentum.require_complete_history = ...
    true;


%% Downside-deviation signal

cfg.signals.downside.start_lag_months = ...
    12;

cfg.signals.downside.end_lag_months = ...
    2;

cfg.signals.downside.min_coverage = ...
    0.80;


%% Idiosyncratic-skewness signal

cfg.signals.idio_skew.start_lag_months = ...
    12;

cfg.signals.idio_skew.end_lag_months = ...
    2;

cfg.signals.idio_skew.min_coverage = ...
    0.80;


%% Size control

cfg.size.n_buckets = ...
    5;


%% Calibration diagnostics

cfg.calibration.momentum_pct = ...
    [60 70 80];

cfg.calibration.downside_pct = ...
    [20 30 40];

cfg.calibration.skew_pct = ...
    [80 90];

cfg.calibration.min_median_holdings = ...
    30;

cfg.calibration.objective = ...
    "sharpe";

cfg.calibration.tie_breakers = ...
    ["turnover_asc", "holdings_desc"];


%% Selected research specification

cfg.selection.momentum_pct = ...
    70;

cfg.selection.downside_pct = ...
    40;

cfg.selection.skew_pct = ...
    90;


%% Portfolio construction

cfg.portfolio.long_only = ...
    true;

cfg.portfolio.fully_invested = ...
    true;

cfg.portfolio.strategy_weighting = ...
    "equal";

cfg.portfolio.empty_month_policy = ...
    "invalid";


%% Turnover

cfg.turnover.method = ...
    "drift_adjusted";

end