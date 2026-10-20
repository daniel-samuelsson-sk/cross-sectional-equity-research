function tests = test_stationary_bootstrap
%TEST_STATIONARY_BOOTSTRAP Index generation and paired resampling tests.

tests = functiontests(localfunctions);

end


function setupOnce(testCase) %#ok<INUSD>

    root = ...
        fileparts(fileparts(mfilename('fullpath')));

    addpath(fullfile(root,'src'));

end


function testBlocksWrapCircularly(testCase)
% With a negligible restart probability every path is a single circular
% block: each index follows its predecessor and T is followed by 1.

    T = ...
        7;

    indices = ...
        generate_stationary_bootstrap_indices(T, 20, 1e12, 3);

    for b = 1:size(indices,1)

        expected = ...
            mod(indices(b,1) - 1 + (0:T-1), T) + 1;

        verifyEqual(testCase, ...
            indices(b,:), ...
            expected);

    end

    verifyTrue(testCase, ...
        any(indices(:,1) > 1), ...
        'At least one path must start after month 1 and therefore wrap.');

end


function testBlockStartFrequencyMatchesMeanBlockLength(testCase)
% A new block starts with probability 1/L. A restart can land on the next
% index by chance, so the share of steps that do not continue the current
% block is (1/L)*(1 - 1/T).

    T = ...
        408;

    L = ...
        6;

    indices = ...
        generate_stationary_bootstrap_indices(T, 2000, L, 1);

    continued = ...
        indices(:,2:end) == mod(indices(:,1:end-1), T) + 1;

    observed = ...
        1 - mean(continued(:));

    expected = ...
        (1/L) * (1 - 1/T);

    verifyLessThan(testCase, ...
        abs(observed - expected), ...
        0.002);

end


function testComparisonsArePairedAndCorrectlySigned(testCase)

    [series,T] = ...
        make_series();

    % Identical portfolios must give exactly zero differences on every
    % resampled path. This holds only if all portfolios share each path.

    paired = ...
        series;

    paired.mom_dd = ...
        paired.mom;

    result = ...
        compute_bootstrap_comparison_statistics( ...
            paired, ...
            generate_stationary_bootstrap_indices(T, 300, 4, 7));

    verifyEqual(testCase, result.bootstrap.sharpe(:,1), zeros(300,1));
    verifyEqual(testCase, result.bootstrap.annualized_volatility(:,1), zeros(300,1));
    verifyEqual(testCase, result.bootstrap.cagr(:,1), zeros(300,1));

    % Identity paths reproduce the observed differences.

    result = ...
        compute_bootstrap_comparison_statistics( ...
            series, ...
            repmat(1:T, 5, 1));

    first_path = [ ...
        result.bootstrap.sharpe(1,:); ...
        result.bootstrap.annualized_volatility(1,:); ...
        result.bootstrap.cagr(1,:)];

    verifyEqual(testCase, ...
        first_path(:), ...
        result.summary.observed_difference, ...
        'AbsTol',1e-15);

    % Each comparison is reported as the first-named portfolio minus the
    % second, here MOM+DD minus MOM, computed independently.

    sharpe = ...
        @(ex) sqrt(12) * mean(ex) / std(ex,0);

    expected = ...
        sharpe(series.mom_dd.excess_returns) - ...
        sharpe(series.mom.excess_returns);

    row = ...
        result.summary.comparison == "MOM+DD - MOM" & ...
        result.summary.metric == "sharpe";

    verifyEqual(testCase, ...
        result.summary.observed_difference(row), ...
        expected, ...
        'AbsTol',1e-12);

end


function [series,T] = make_series()
%MAKE_SERIES Six deterministic, distinct monthly return series.

    T = ...
        36;

    t = ...
        (1:T)';

    names = { ...
        'mom', 'mom_dd', 'final', 'ew', 'mom_sigma', 'dd_only'};

    series.portfolio_month = ...
        dateshift((datetime(2015,1,1) + calmonths(0:T-1))', 'end', 'month');

    for j = 1:numel(names)

        r = ...
            0.008 + ...
            0.01 * sin(0.5 * t + j) + ...
            0.02 * cos(0.37 * j * t);

        series.(names{j}).returns = ...
            r;

        series.(names{j}).excess_returns = ...
            r - 0.002;

    end

end
