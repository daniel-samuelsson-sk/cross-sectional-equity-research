function tests = test_analysis_generality
%TEST_ANALYSIS_GENERALITY Analysis functions on data outside the study.
%
% The synthetic fixture differs from the published study in every study
% constant: other dates, five calibration and five evaluation months, two
% size buckets, a 25/40/50 specification and a two-cell calibration grid.

tests = functiontests(localfunctions);

end


function setupOnce(testCase)

    root = ...
        fileparts(fileparts(mfilename('fullpath')));

    addpath(fullfile(root,'src'));
    addpath(fullfile(root,'tests','fixtures'));

    [data,cfg] = ...
        make_synthetic_research_fixture();

    testCase.TestData.data = ...
        data;

    testCase.TestData.research = ...
        run_research_pipeline(data, cfg);

end


function testAnalysesRunOnSyntheticPanel(testCase)

    data = ...
        testCase.TestData.data;

    research = ...
        testCase.TestData.research;

    oos_months = ...
        research.evaluation.calendar.portfolio_month;

    n = ...
        numel(oos_months);


    % R1 derives its variants from the selected 25/40/50 specification.

    r1 = ...
        compare_downside_total_volatility(data, research);

    verifyEqual(testCase, r1.series.portfolio_month, oos_months);
    verifyEqual(testCase, height(r1.summary), 4);
    verifyTrue(testCase, isfinite(r1.rank_correlation.mean));


    % R2 runs on the R1 panel.

    r2 = ...
        bootstrap_strategy_differences(r1.series, 200, 2, 1);

    verifyEqual(testCase, height(r2.summary), 15);
    verifyTrue(testCase, ...
        all(isfinite(r2.summary.ci_lower)) && ...
        all(isfinite(r2.summary.ci_upper)));


    % R4 splits the five evaluation months into two consecutive halves.

    r4 = ...
        analyze_subperiod_robustness(data, research);

    verifyEqual(testCase, ...
        [r4.meta.h1_months, r4.meta.h2_months], ...
        [floor(n/2), n - floor(n/2)]);


    % R5 uses every admissible candidate of the configured grid.

    r5 = ...
        analyze_calibration_robustness(data, research);

    verifyEqual(testCase, ...
        r5.meta.n_specifications, ...
        height(research.calibration.ranked_candidates));

    verifyEqual(testCase, ...
        r5.meta.reported_calibration_rank, ...
        research.calibration.selected_rank);

end


function testMarketBetaChannelKnownAnswer(testCase)
% Planted betas with residuals orthogonal to [1, m] over the full sample.
% Then var(A) = beta_A^2 var(m) + var(e_A) holds exactly, so the share q of
% the variance reduction associated with lower beta is known in advance.

    T = ...
        48;

    portfolio_month = ...
        dateshift((datetime(2001,1,1) + calmonths(0:T-1))', 'end', 'month');

    t = ...
        (1:T)';

    m = ...
        0.04 * sin(0.45 * t) + 0.02 * cos(1.1 * t);

    X = ...
        [ones(T,1), m];

    raw = ...
        0.01 * sin(0.9 * t + 1) + 0.006 * cos(0.31 * t);

    e = ...
        raw - X * (X \ raw);


    % Every pair used in a difference regression must differ, otherwise the
    % difference portfolio has zero variance.

    beta = struct( ...
        'mom', 1.20, 'dd_only', 0.70, 'sigma_only', 0.72, 'mom_dd', 0.80, ...
        'mom_sigma', 0.79, 'final', 0.82, 'ew', 1.00, 'vw', 0.98);

    scale = struct( ...
        'mom', 1.0, 'dd_only', 0.6, 'sigma_only', 0.6, 'mom_dd', 0.5, ...
        'mom_sigma', 0.52, 'final', 0.5, 'ew', 0.3, 'vw', 0.1);

    rf = ...
        0.002 * ones(T,1);

    series.portfolio_month = ...
        portfolio_month;

    keys = ...
        fieldnames(beta);

    for k = 1:numel(keys)

        excess = ...
            0.001 + beta.(keys{k}) * m + scale.(keys{k}) * e;

        series.(keys{k}).excess_returns = ...
            excess;

        series.(keys{k}).returns = ...
            excess + rf;

    end

    ff.portfolio_month = ...
        portfolio_month;

    ff.mkt_rf = ...
        m;

    ff.rf = ...
        rf;

    ff.meta = ...
        struct('source', "synthetic");


    capm = ...
        analyze_market_beta_channel(series, rf, ff);


    full_period = ...
        capm.periods.period(1);

    verifyEqual(testCase, capm.periods.n_months, [T; T/2; T/2]);

    level_beta = @(label) capm.levels.beta( ...
        capm.levels.period == full_period & capm.levels.portfolio == label);

    verifyEqual(testCase, level_beta("MOM"), 1.20, 'AbsTol',1e-12);
    verifyEqual(testCase, level_beta("MOM+DD"), 0.80, 'AbsTol',1e-12);

    expected_q = ...
        ((1.20^2 - 0.80^2) * var(m,0)) / ...
        ((1.20^2 - 0.80^2) * var(m,0) + (1.0^2 - 0.5^2) * var(e,0));

    channel_row = ...
        capm.channel.period == full_period & ...
        capm.channel.transition == "MOM -> MOM+DD";

    verifyEqual(testCase, ...
        capm.channel.q(channel_row), ...
        expected_q, ...
        'AbsTol',1e-12);

end


function testSampleHalfLabelsAreDistinct(testCase)
% The full sample and the two halves must have different labels, because
% result rows are identified by them. Year labels are kept when they
% differ, as in the published study; otherwise all three name months.

    month_ends = @(first, n) ...
        dateshift((first + calmonths(0:n-1))', 'end', 'month');

    labels = @(halves) ...
        [halves.full_label; halves.label];

    verifyEqual(testCase, ...
        labels(split_sample_halves(month_ends(datetime(1990,1,1), 408))), ...
        ["1990-2023"; "1990-2006"; "2007-2023"]);

    % January to December 2020: all three year labels would be 2020-2020.
    verifyEqual(testCase, ...
        labels(split_sample_halves(month_ends(datetime(2020,1,1), 12))), ...
        ["2020-01/2020-12"; "2020-01/2020-06"; "2020-07/2020-12"]);

    % January 2019 to March 2020: the full sample and the second half would
    % both be 2019-2020.
    verifyEqual(testCase, ...
        labels(split_sample_halves(month_ends(datetime(2019,1,1), 15))), ...
        ["2019-01/2020-03"; "2019-01/2019-07"; "2019-08/2020-03"]);

end
