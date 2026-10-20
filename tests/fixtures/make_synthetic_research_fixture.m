function [data, cfg] = make_synthetic_research_fixture()
%MAKE_SYNTHETIC_RESEARCH_FIXTURE Build a deterministic research fixture.
%
% The fixture is designed to verify research-pipeline mechanics and timing.
% It is not intended to represent realistic security-level market data or
% realistic strategy performance.
%
% Monthly and daily return series are planted independently. They are not
% constructed so that daily returns compound to the monthly returns.
%
% The fixture contains:
%   - 17 assets
%   - 2 market-cap buckets
%   - 5 calibration months
%   - 5 evaluation months
%   - 3-2 signal windows
%   - a 2 x 1 x 1 calibration grid
%   - one known non-common equity
%   - one unknown security type
%
%
% RESEARCH PERIODS
%
% Monthly source data:
%   Jan 2020 through Jan 2021
%
% Calibration:
%   Apr 2020 through Aug 2020
%
% Evaluation:
%   Sep 2020 through Jan 2021
%
% Reference portfolio month:
%   t* = 30-Nov-2020
%
% Information boundary for t*:
%   31-Oct-2020
%
% With start_lag_months = 3 and end_lag_months = 2, the signal window for
% t* is Aug-Sep 2020. October is the excluded most-recent month and
% November is the realized portfolio month.
%
%
% BASELINE ASSET DESIGN
%
% Asset   Type               Cap   r   d   Residual skew
% A01     common_equity       10   1   7   zero
% A02     common_equity       20   2   8   zero
% A03     common_equity       30   4   2   positive
% A04     common_equity       40   5   3   positive
% A05     common_equity       50   6   4   zero
% A06     unknown             60   3   1   zero
% A07     common_equity       70   7   5   zero
% A08     common_equity       80   8   6   zero
% A09     common_equity      200   1   7   zero
% A10     common_equity      210   2   8   zero
% A11     common_equity      220   4   2   positive
% A12     common_equity      230   5   3   positive
% A13     common_equity      240   6   4   zero
% A14     common_equity      250   3   1   zero
% A15     common_equity      260   7   5   zero
% A16     common_equity      270   8   6   zero
% A17     non_common_equity   15   9   0.5 negative
%
% r controls monthly momentum ordering.
% d controls daily downside-deviation ordering.
% The residual pattern controls idiosyncratic-skewness ordering.
%
% A17 is deliberately constructed to be otherwise attractive: it has the
% highest momentum, lowest downside deviation, and lowest skewness. Its
% baseline exclusion is therefore caused by security type rather than a
% weak signal.
%
%
% KNOWN ANSWER AT t*
%
% Baseline base-eligible assets:
%   A01:A16
%
% A17 is excluded because security_type = "non_common_equity".
%
% Baseline market caps:
%
%    10 20 30 40 50 60 70 80 | 200 210 220 230 240 250 260 270
%
% MATLAB's default percentile definition gives:
%
%   size q50 = (80 + 200) / 2 = 140
%
% Therefore:
%
%   bucket 1 = A01:A08
%   bucket 2 = A09:A16
%
%
% SELECTED SPECIFICATION: 25 / 40 / 50
%
% At t*, Aug and Sep have zero common monthly component. Momentum is:
%
%   MOM(r) = (1 + 0.005*r)^2 - 1
%
% giving, for r = 1,...,8:
%
%   0.010025
%   0.020100
%   0.030225
%   0.040400
%   0.050625
%   0.060900
%   0.071225
%   0.081600
%
% In each size bucket:
%
%   momentum q25
%       = (0.020100 + 0.030225) / 2
%       = 0.0251625
%
% Momentum survivors:
%
%   bucket 1: A06 A03 A04 A05 A07 A08
%   bucket 2: A14 A11 A12 A13 A15 A16
%
% All daily excess returns are negative. Because the factor and residual
% patterns have zero mean, are mutually orthogonal, and have fixed
% quadratic variation:
%
%   DD(d) = sqrt((0.002*d)^2 + 1.2666666666666667e-7)
%
% For the six momentum survivors, d = 1,...,6. The 40th percentile is:
%
%   downside q40 = 0.00581107187018338
%
% Downside survivors:
%
%   bucket 1: A06 A03
%   bucket 2: A14 A11
%
% Theoretical residual skewness values are:
%
%   negative = -sqrt(66)/10
%   zero     = 0
%   positive = +sqrt(66)/10
%
% so the two-name 50th-percentile threshold between zero and positive
% skewness is:
%
%   skew q50 = sqrt(66)/20
%             = 0.406201920231798 approximately
%
% Final selected names:
%
%   A06 A14
%
% Final target weights:
%
%   A06 = 0.5
%   A14 = 0.5
%
%
% SECOND CALIBRATION CELL: 50 / 40 / 50
%
% At t*:
%
%   momentum q50
%       = (0.040400 + 0.050625) / 2
%       = 0.0455125
%
% Momentum survivors:
%
%   bucket 1: A04 A05 A07 A08
%   bucket 2: A12 A13 A15 A16
%
% Their d values are 3,4,5,6. The 40th-percentile DD threshold is:
%
%   downside q40 = 0.00820775461099843
%
% Downside survivors:
%
%   bucket 1: A04 A05
%   bucket 2: A12 A13
%
% The skewness filter leaves:
%
%   A05 A13
%
%
% CALIBRATION RANKING
%
% Calibration monthly common components for Apr-Aug are:
%
%   +0.004  -0.002  +0.003  -0.001  0
%
% Monthly risk-free return is 0.001 throughout the fixture.
%
% The 25/40/50 final portfolio therefore realizes:
%
%   0.019  0.013  0.018  0.014  0.015
%
% and has calibration Sharpe:
%
%   19.8068283114989 approximately
%
% The 50/40/50 final portfolio realizes:
%
%   0.034  0.028  0.033  0.029  0.030
%
% and has calibration Sharpe:
%
%   39.8813164650450 approximately
%
% Expected ranking:
%
%   rank 1: 50 / 40 / 50
%   rank 2: 25 / 40 / 50
%
% cfg.selection deliberately carries 25/40/50 forward to evaluation.
%
%
% MARKET-CAP POSITIVE CONTROL
%
% At t*, A01 has market cap 10 dated 31-Oct-2020.
%
% If that single observation is changed from 10 to 255, the sorted
% eligible cross-section becomes:
%
%   20 30 40 50 60 70 80 200 | 210 220 230 240 250 255 260 270
%
% and:
%
%   new size q50 = (200 + 210) / 2 = 205
%
% Two assignments change:
%
%   A01: bucket 1 -> bucket 2
%   A09: bucket 2 -> bucket 1
%
% The baseline final selected set remains A06 and A14 because A01 and A09
% have the same deliberately weak momentum level r = 1.
%
%
% SECURITY-TYPE COUNTERFACTUAL
%
% If A17 is changed from "non_common_equity" to "common_equity", A17 must
% reach the FINAL selected set.
%
% Do not use that counterfactual to assert the complete selected set or
% complete weight vector. With 17 eligible assets, the median market-cap
% cutoff lands exactly on A08's market cap, and a later skewness percentile
% contains mathematically tied values whose floating-point regression
% estimates can differ at machine precision.
%
% The required positive control is therefore only:
%
%   A17 is selected in FINAL after its type is changed to common_equity.


%% Fixture dimensions and asset parameters

N = ...
    17;

asset_id = ...
    101:117;

asset_ticker = [ ...
    "A01" "A02" "A03" "A04" "A05" "A06" "A07" "A08" ...
    "A09" "A10" "A11" "A12" "A13" "A14" "A15" "A16" ...
    "A17"];

asset_market_cap = [ ...
     10  20  30  40  50  60  70  80 ...
    200 210 220 230 240 250 260 270 ...
     15];

% Monthly momentum level r.
asset_momentum_level = [ ...
    1 2 4 5 6 3 7 8 ...
    1 2 4 5 6 3 7 8 ...
    9];

% Daily downside level d.
asset_downside_level = [ ...
    7 8 2 3 4 1 5 6 ...
    7 8 2 3 4 1 5 6 ...
    0.5];

% Residual-skew class:
%   -1 = negative
%    0 = zero
%   +1 = positive
asset_skew_class = [ ...
    0 0 1 1 0 0 0 0 ...
    0 0 1 1 0 0 0 0 ...
   -1];


%% Assets

data.assets.id = ...
    asset_id;

data.assets.ticker = ...
    asset_ticker;

data.assets.security_type = ...
    repmat("common_equity",1,N);

data.assets.security_type(6) = ...
    "unknown";

data.assets.security_type(17) = ...
    "non_common_equity";


%% Monthly calendar

month_start = ...
    datetime(2020,1,1) + ...
    calmonths((0:12)');

data.monthly.dates = ...
    dateshift( ...
        month_start, ...
        'end', ...
        'month');


%% Monthly returns
%
% Exact common monthly component:
%
%   Jan-2020   +0.001
%   Feb-2020   -0.001
%   Mar-2020   +0.002
%   Apr-2020   +0.004
%   May-2020   -0.002
%   Jun-2020   +0.003
%   Jul-2020   -0.001
%   Aug-2020    0
%   Sep-2020    0
%   Oct-2020   +0.002
%   Nov-2020   -0.003
%   Dec-2020   +0.001
%   Jan-2021   -0.001
%
% Asset i receives:
%
%   monthly_return(t,i)
%       = common_month_component(t)
%       + 0.005 * asset_momentum_level(i)

common_month_component = [ ...
     0.001; ...
    -0.001; ...
     0.002; ...
     0.004; ...
    -0.002; ...
     0.003; ...
    -0.001; ...
     0.000; ...
     0.000; ...
     0.002; ...
    -0.003; ...
     0.001; ...
    -0.001];

data.monthly.returns = ...
    common_month_component + ...
    0.005 * asset_momentum_level;

% Exact monthly risk-free series: 0.001 in every source month.
data.monthly.rf = ...
    0.001 * ones(13,1);


%% Market capitalization
%
% Market-cap values are deliberately constant through time. For portfolio
% month t, build_formation_universe uses the observation dated at the end
% of month t-1.

data.market_cap.dates = ...
    data.monthly.dates;

data.market_cap.values = ...
    repmat( ...
        asset_market_cap, ...
        numel(data.market_cap.dates), ...
        1);

data.market_cap.valid = ...
    true(size(data.market_cap.values));


%% Formation availability
%
% All assets are source-available in every source month. Security-type
% exclusion is handled separately by the formation-universe rule.

data.availability.dates = ...
    data.monthly.dates;

data.availability.available = ...
    true( ...
        numel(data.availability.dates), ...
        N);


%% Daily calendar
%
% There are exactly six synthetic daily observations in each month from
% January through November 2020:
%
%   day of month = 02, 06, 10, 14, 18, 22
%
% Thus the exact date set is:
%
%   2020-mm-{02,06,10,14,18,22}
%
% for mm = 01,...,11.
%
% Every two-month 3-2 signal window therefore contains 12 observations.

daily_day_of_month = ...
    [2; 6; 10; 14; 18; 22];

n_daily_months = ...
    11;

n_days_per_month = ...
    numel(daily_day_of_month);

n_daily = ...
    n_daily_months * n_days_per_month;

daily_dates = ...
    NaT(n_daily,1);

for m = 1:n_daily_months

    rows = ...
        (m-1) * n_days_per_month + ...
        (1:n_days_per_month);

    daily_dates(rows) = ...
        datetime( ...
            2020 * ones(n_days_per_month,1), ...
            m * ones(n_days_per_month,1), ...
            daily_day_of_month);

end

data.daily.dates = ...
    daily_dates;


%% Daily factor and risk-free series
%
% The market factor varies within every month and therefore within every
% two-month signal window.

factor_one_month = ...
    1e-4 * [ ...
        -3; ...
        -2; ...
        -1; ...
         1; ...
         2; ...
         3];

data.daily.market_excess = ...
    repmat( ...
        factor_one_month, ...
        n_daily_months, ...
        1);

data.daily.rf = ...
    zeros(n_daily,1);


%% Daily stock returns
%
% Three residual patterns are used. Each has:
%   - zero mean,
%   - the same sum of squared residual values,
%   - zero inner product with factor_one_month.
%
% They therefore isolate residual-skewness ordering without changing the
% intended downside-deviation ordering.
%
% Theoretical bias-corrected skewness over a two-month window:
%
%   negative pattern -> -sqrt(66)/10
%   zero pattern     -> 0
%   positive pattern -> +sqrt(66)/10

residual_positive = [ ...
    -1; ...
    -1; ...
     2; ...
     2; ...
    -1; ...
    -1];

residual_zero = ...
    sqrt(3) * [ ...
        -1; ...
         0; ...
         1; ...
         1; ...
         0; ...
        -1];

residual_negative = ...
    -residual_positive;

data.daily.returns = ...
    NaN(n_daily,N);

for i = 1:N

    if asset_skew_class(i) == 1

        residual_one_month = ...
            residual_positive;

    elseif asset_skew_class(i) == -1

        residual_one_month = ...
            residual_negative;

    else

        residual_one_month = ...
            residual_zero;

    end

    residual = ...
        repmat( ...
            residual_one_month, ...
            n_daily_months, ...
            1);

    data.daily.returns(:,i) = ...
        -0.002 * asset_downside_level(i) + ...
        data.daily.market_excess + ...
        0.0002 * residual;

end


%% Metadata

data.meta.provider = ...
    "deterministic synthetic research fixture";

data.meta.n_assets = ...
    N;

data.meta.n_months = ...
    numel(data.monthly.dates);

data.meta.n_days = ...
    numel(data.daily.dates);

data.meta.provenance.source_identity = ...
    "deterministic_synthetic_fixture";

data.meta.provenance.market_cap_timing = ...
    "end_of_previous_month";

data.meta.provenance.availability_basis = ...
    "synthetic_fixed_availability";

data.meta.provenance.security_type_knowledge = ...
    "synthetic_planted";

data.meta.provenance.panel_selection_method = ...
    "synthetic_design";

data.meta.provenance.delisting_return_treatment = ...
    "not_applicable";

data.meta.provenance.market_cap_units = ...
    "synthetic_units";


%% Research periods

cfg.periods.calibration_start = ...
    datetime(2020,4,30);

cfg.periods.calibration_end = ...
    datetime(2020,8,31);

cfg.periods.evaluation_start = ...
    datetime(2020,9,30);

cfg.periods.evaluation_end = ...
    datetime(2021,1,31);


%% Formation universe

cfg.universe.min_observed_history_months = ...
    0;


%% Momentum signal

cfg.signals.momentum.start_lag_months = ...
    3;

cfg.signals.momentum.end_lag_months = ...
    2;

cfg.signals.momentum.require_complete_history = ...
    true;


%% Downside-deviation signal

cfg.signals.downside.start_lag_months = ...
    3;

cfg.signals.downside.end_lag_months = ...
    2;

cfg.signals.downside.min_coverage = ...
    0.80;


%% Idiosyncratic-skewness signal

cfg.signals.idio_skew.start_lag_months = ...
    3;

cfg.signals.idio_skew.end_lag_months = ...
    2;

cfg.signals.idio_skew.min_coverage = ...
    0.80;


%% Size control

cfg.size.n_buckets = ...
    2;


%% Calibration grid

cfg.calibration.momentum_pct = ...
    [25 50];

cfg.calibration.downside_pct = ...
    40;

cfg.calibration.skew_pct = ...
    50;

cfg.calibration.min_median_holdings = ...
    1;

cfg.calibration.objective = ...
    "sharpe";

cfg.calibration.tie_breakers = ...
    ["turnover_asc", "holdings_desc"];


%% Selected research specification

cfg.selection.momentum_pct = ...
    25;

cfg.selection.downside_pct = ...
    40;

cfg.selection.skew_pct = ...
    50;


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