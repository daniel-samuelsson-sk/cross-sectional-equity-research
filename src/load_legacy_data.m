function data = load_legacy_data(monthly_file, daily_file, french_daily_file)
%LOAD_LEGACY_DATA Load and normalize the legacy equity dataset.
%
% Returns a provider-neutral data structure used by the research engine.
%
% INPUTS
%   monthly_file      Path to data_monthly.mat
%   daily_file        Path to data_daily.mat
%   french_daily_file Path to Kenneth French daily factor CSV
%
% OUTPUT
%   data              Standardized research-data structure

%% Load source files

monthly = load(monthly_file);
daily   = load(daily_file);


%% Basic source validation

required_monthly = {'permno','months','rf','ret','me'};
required_daily   = {'permno','dates','dret'};

for k = 1:numel(required_monthly)

    assert(isfield(monthly, required_monthly{k}), ...
        'Missing variable "%s" in monthly file.', ...
        required_monthly{k});

end

for k = 1:numel(required_daily)

    assert(isfield(daily, required_daily{k}), ...
        'Missing variable "%s" in daily file.', ...
        required_daily{k});

end

assert(isequal(monthly.permno(:), daily.permno(:)), ...
    'Asset ordering differs between monthly and daily files.');

N = numel(monthly.permno);

assert(size(monthly.ret,2) == N, ...
    'Monthly return matrix does not match number of assets.');

assert(size(monthly.me,2) == N, ...
    'Market-cap matrix does not match number of assets.');

assert(size(daily.dret,2) == N, ...
    'Daily return matrix does not match number of assets.');


%% Asset identifiers

data.assets.id = monthly.permno(:).';

% The legacy dataset contains permanent CRSP identifiers but no ticker
% information in the supplied matrices.
data.assets.ticker = strings(1,N);

% Security type is not verified in the legacy source data.
data.assets.security_type = ...
    repmat("unknown",1,N);


%% Monthly returns

% months is YYYYMM and identifies the month whose return is stored in ret.

month_start = datetime( ...
    string(monthly.months(:)), ...
    'InputFormat','yyyyMM');

data.monthly.dates = ...
    dateshift(month_start, 'end', 'month');

data.monthly.returns = monthly.ret;
data.monthly.rf      = monthly.rf(:);


%% Market capitalization

% IMPORTANT:
%
% me(t,:) contains market equity observed at the END OF MONTH t-1.
%
% The market-cap observations are therefore assigned their actual
% information dates rather than inheriting the return-month date.

market_cap_dates = dateshift( ...
    month_start - calmonths(1), ...
    'end', ...
    'month');

data.market_cap.dates  = market_cap_dates;
data.market_cap.values = monthly.me;

% Numerical validity of the market-cap observation itself.
data.market_cap.valid = ...
    isfinite(monthly.me) & monthly.me > 0;


%% Formation availability

% In the legacy dataset, me(t,:) corresponds to market equity observed at
% the end of t-1, and the dataset documentation states that the market-value
% observation is missing when a stock is not available for month t.
%
% This field therefore represents source-provided availability for the
% portfolio month. Downstream research code should not infer availability
% from the realized return in month t.

data.availability.dates = data.monthly.dates;

data.availability.available = ...
    isfinite(monthly.me) & monthly.me > 0;


%% Daily equity returns

data.daily.dates = datetime( ...
    string(daily.dates(:)), ...
    'InputFormat','yyyyMMdd');

data.daily.returns = daily.dret;


%% Kenneth French daily factors

ff = readtable( ...
    french_daily_file, ...
    'FileType','text', ...
    'VariableNamingRule','preserve');

% The first column contains YYYYMMDD dates.
ff_dates = datetime( ...
    string(ff{:,1}), ...
    'InputFormat','yyyyMMdd');

% Identify the factor columns robustly even if headers contain spaces,
% hyphens, or underscores.

names = lower(string(ff.Properties.VariableNames));

names_clean = erase(names, "_");
names_clean = erase(names_clean, "-");
names_clean = erase(names_clean, " ");

mkt_col = find(contains(names_clean, "mktrf"), 1);
rf_col  = find(names_clean == "rf", 1);

assert(~isempty(mkt_col), ...
    'Could not identify Mkt-RF column in Kenneth French file.');

assert(~isempty(rf_col), ...
    'Could not identify RF column in Kenneth French file.');


%% Align French factors to the equity trading calendar

[is_match, ff_idx] = ismember(data.daily.dates, ff_dates);

assert(all(is_match), ...
    'Kenneth French data is missing one or more equity trading dates.');

% Kenneth French files report returns in percent.
data.daily.market_excess = ...
    ff{ff_idx, mkt_col} / 100;

data.daily.rf = ...
    ff{ff_idx, rf_col} / 100;


%% Metadata

data.meta.provider = ...
    "legacy equity panel + Kenneth French daily factors";

data.meta.n_assets = N;
data.meta.n_months = size(monthly.ret,1);
data.meta.n_days   = size(daily.dret,1);

data.meta.provenance.source_identity = ...
    "legacy_equity_panel_plus_kenneth_french_daily_factors";

data.meta.provenance.market_cap_timing = ...
    "end_of_previous_month";

data.meta.provenance.availability_basis = ...
    "month_t_trading_convention_ex_post";

data.meta.provenance.security_type_knowledge = ...
    "unknown";

data.meta.provenance.panel_selection_method = ...
    "unknown";

data.meta.provenance.delisting_return_treatment = ...
    "unknown";

data.meta.provenance.market_cap_units = ...
    "unknown";

end