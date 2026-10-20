function size_control = assign_size_buckets(universe, cfg)
%ASSIGN_SIZE_BUCKETS Assign point-in-time market-cap buckets.
%
% For every portfolio month, base-eligible securities are sorted into
% configured market-cap buckets using cross-sectional percentile cutoffs.
%
% With five buckets, the default cutoffs are:
%   20th, 40th, 60th, and 80th percentiles.
%
% Bucket numbering:
%   1 = smallest market-cap group
%   ...
%   B = largest market-cap group
%
% Only market capitalization already contained in the point-in-time
% formation universe is used. No realized portfolio-month information is
% accessed here.
%
% Equal market-cap observations are never split arbitrarily across
% buckets. Values exactly equal to a cutoff enter the higher bucket,
% matching MATLAB discretize-style interval semantics.

%% Validate configuration

assert(isfield(cfg, 'size') && ...
       isfield(cfg.size, 'n_buckets'), ...
    'SizeBuckets:MissingConfiguration', ...
    'cfg.size.n_buckets is required.');

B = cfg.size.n_buckets;

assert(isscalar(B) && ...
       isfinite(B) && ...
       B == floor(B) && ...
       B >= 2, ...
    'SizeBuckets:InvalidBucketCount', ...
    'Number of size buckets must be an integer greater than or equal to 2.');


%% Validate universe interface

required_fields = { ...
    'portfolio_month', ...
    'market_cap', ...
    'base_eligible'};

for k = 1:numel(required_fields)

    assert(isfield(universe, required_fields{k}), ...
        'SizeBuckets:MissingUniverseField', ...
        'Universe is missing required field: %s', ...
        required_fields{k});

end

market_cap    = universe.market_cap;
base_eligible = universe.base_eligible;

M = size(market_cap, 1);
N = size(market_cap, 2);

assert(numel(universe.portfolio_month) == M, ...
    'SizeBuckets:MonthMismatch', ...
    'Portfolio-month count must match market-cap rows.');

assert(isequal(size(base_eligible), [M N]), ...
    'SizeBuckets:EligibilityDimensionMismatch', ...
    'base_eligible must have the same dimensions as market_cap.');

assert(islogical(base_eligible), ...
    'SizeBuckets:InvalidEligibilityType', ...
    'base_eligible must be logical.');

assert(all(isfinite(market_cap(base_eligible))), ...
    'SizeBuckets:InvalidEligibleMarketCap', ...
    'Every base-eligible asset must have finite market capitalization.');

assert(all(market_cap(base_eligible) > 0), ...
    'SizeBuckets:InvalidEligibleMarketCap', ...
    'Every base-eligible asset must have positive market capitalization.');


%% Preallocate

bucket = NaN(M, N);

percentiles = ...
    (1:(B-1)) * (100 / B);

cutoffs = ...
    NaN(M, B-1);

bucket_counts = ...
    zeros(M, B);

n_eligible = ...
    sum(base_eligible, 2);

valid_month = ...
    n_eligible > 0;

all_buckets_populated = ...
    false(M,1);


%% Assign buckets month by month

for t = 1:M

    eligible = ...
        base_eligible(t,:);

    if ~any(eligible)
        continue;
    end

    cap = ...
        market_cap(t, eligible);

    % Cross-sectional percentile thresholds among securities that were
    % eligible at formation.

    q = ...
        prctile(cap, percentiles);

    cutoffs(t,:) = q;

    % Start every eligible security in the smallest bucket.
    %
    % Crossing each percentile threshold moves the security up one
    % bucket. Using >= means observations exactly equal to a cutoff enter
    % the higher bucket.
    %
    % This implementation also remains well-defined when percentile
    % thresholds coincide because of tied market-cap observations.

    assigned = ...
        ones(1, numel(cap));

    for j = 1:(B-1)

        assigned = ...
            assigned + (cap >= q(j));

    end

    bucket(t, eligible) = assigned;

    for b = 1:B

        bucket_counts(t,b) = ...
            sum(assigned == b);

    end

    all_buckets_populated(t) = ...
        all(bucket_counts(t,:) > 0);

end


%% Integrity checks

% Ineligible securities must never receive a bucket.

assert(all(isnan(bucket(~base_eligible))), ...
    'SizeBuckets:IneligibleAssetAssigned', ...
    'An ineligible asset received a size bucket.');

% Every eligible security must receive exactly one valid bucket.

eligible_bucket_values = ...
    bucket(base_eligible);

assert(all(isfinite(eligible_bucket_values)), ...
    'SizeBuckets:EligibleAssetUnassigned', ...
    'A base-eligible asset did not receive a size bucket.');

assert(all( ...
    eligible_bucket_values >= 1 & ...
    eligible_bucket_values <= B & ...
    eligible_bucket_values == floor(eligible_bucket_values)), ...
    'SizeBuckets:InvalidAssignment', ...
    'Size-bucket assignments must be integers between 1 and B.');

% Bucket counts must recover the complete base-eligible universe.

assert(all(sum(bucket_counts,2) == n_eligible), ...
    'SizeBuckets:CountMismatch', ...
    'Size-bucket counts do not match the eligible universe size.');


%% Output

size_control.portfolio_month = ...
    universe.portfolio_month;

size_control.bucket = ...
    bucket;

size_control.cutoffs = ...
    cutoffs;

size_control.percentiles = ...
    percentiles;

size_control.n_buckets = ...
    B;

size_control.bucket_counts = ...
    bucket_counts;

size_control.n_eligible = ...
    n_eligible;

size_control.valid_month = ...
    valid_month;

% Diagnostic only. A bucket may be empty when the cross-section is very
% small or many market-cap observations are tied at percentile boundaries.
size_control.all_buckets_populated = ...
    all_buckets_populated;

end