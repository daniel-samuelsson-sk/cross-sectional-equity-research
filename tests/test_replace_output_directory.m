function tests = test_replace_output_directory
%TEST_REPLACE_OUTPUT_DIRECTORY Results are replaced only by a complete set.
%
% The last two tests recreate the folders that an abrupt stop inside
% replace_output_directory leaves behind, and check that
% recover_output_directory returns a consistent set.

tests = functiontests(localfunctions);

end


function setupOnce(testCase) %#ok<INUSD>

    root = ...
        fileparts(fileparts(mfilename('fullpath')));

    addpath(fullfile(root,'src'));

end


function setup(testCase)

    base = ...
        tempname;

    mkdir(base);

    testCase.TestData.base = ...
        base;

    testCase.TestData.target = ...
        fullfile(base, 'results');

    testCase.TestData.staging = ...
        fullfile(base, 'results.staging');

    mkdir(testCase.TestData.target);
    write_text(fullfile(testCase.TestData.target, 'a.csv'), "old a");
    write_text(fullfile(testCase.TestData.target, 'b.csv'), "old b");

    mkdir(testCase.TestData.staging);

end


function teardown(testCase)

    rmdir(testCase.TestData.base, 's');

end


function testCompleteStagingReplacesTarget(testCase)

    d = ...
        testCase.TestData;

    write_text(fullfile(d.staging, 'a.csv'), "new a");
    write_text(fullfile(d.staging, 'b.csv'), "new b");

    replace_output_directory(d.staging, d.target, ["a.csv"; "b.csv"]);

    verifyEqual(testCase, read_text(fullfile(d.target, 'a.csv')), "new a");
    verifyEqual(testCase, read_text(fullfile(d.target, 'b.csv')), "new b");
    verifyFalse(testCase, isfolder(d.staging));
    verifyFalse(testCase, isfolder([d.target '.previous']));

end


function testIncompleteStagingLeavesTargetUntouched(testCase)
% Simulates a run that failed after writing only part of its output.

    d = ...
        testCase.TestData;

    write_text(fullfile(d.staging, 'a.csv'), "new a");

    verifyError(testCase, ...
        @() replace_output_directory(d.staging, d.target, ["a.csv"; "b.csv"]), ...
        'OutputReplacement:IncompleteStaging');

    verifyEqual(testCase, read_text(fullfile(d.target, 'a.csv')), "old a");
    verifyEqual(testCase, read_text(fullfile(d.target, 'b.csv')), "old b");
    verifyFalse(testCase, isfolder([d.target '.previous']));

end


function testLeftoverBackupStopsReplacement(testCase)
% A leftover .previous folder may hold the only copy of earlier results.

    d = ...
        testCase.TestData;

    write_text(fullfile(d.staging, 'a.csv'), "new a");
    write_text(fullfile(d.staging, 'b.csv'), "new b");

    mkdir([d.target '.previous']);

    verifyError(testCase, ...
        @() replace_output_directory(d.staging, d.target, ["a.csv"; "b.csv"]), ...
        'OutputReplacement:StaleBackup');

    verifyEqual(testCase, read_text(fullfile(d.target, 'a.csv')), "old a");
    verifyEqual(testCase, read_text(fullfile(d.target, 'b.csv')), "old b");

end


function testUnownedFileInTargetStopsReplacement(testCase)
% The results folder may hold only files that the run owns.

    d = ...
        testCase.TestData;

    write_text(fullfile(d.staging, 'a.csv'), "new a");
    write_text(fullfile(d.staging, 'b.csv'), "new b");
    write_text(fullfile(d.target, 'notes.txt'), "keep");

    verifyError(testCase, ...
        @() replace_output_directory(d.staging, d.target, ["a.csv"; "b.csv"]), ...
        'OutputReplacement:UnexpectedFiles');

    verifyEqual(testCase, read_text(fullfile(d.target, 'a.csv')), "old a");
    verifyFalse(testCase, isfolder([d.target '.previous']));

end


function testSubfolderInTargetStopsReplacement(testCase)
% A folder named like a result file would receive the moved file, and the
% move would still report success.

    d = ...
        testCase.TestData;

    write_text(fullfile(d.staging, 'a.csv'), "new a");
    write_text(fullfile(d.staging, 'b.csv'), "new b");

    delete(fullfile(d.target, 'b.csv'));
    mkdir(fullfile(d.target, 'b.csv'));

    verifyError(testCase, ...
        @() replace_output_directory(d.staging, d.target, ["a.csv"; "b.csv"]), ...
        'OutputReplacement:UnexpectedFolder');

    verifyEqual(testCase, read_text(fullfile(d.target, 'a.csv')), "old a");
    verifyFalse(testCase, isfolder([d.target '.previous']));

end


function testRecoveryRestoresInterruptedReplacement(testCase)
% Stopped while replacing: the backup is complete and marked, a.csv has
% already been replaced, and c.csv is new in this run.

    d = ...
        testCase.TestData;

    backup = ...
        [d.target '.previous'];

    copyfile(d.target, backup);
    write_text(fullfile(backup, 'BACKUP_COMPLETE'), "");

    write_text(fullfile(d.target, 'a.csv'), "new a");
    write_text(fullfile(d.target, 'c.csv'), "new c");

    verifyTrue(testCase, ...
        recover_output_directory(d.target, ["a.csv"; "b.csv"; "c.csv"]));

    verifyEqual(testCase, read_text(fullfile(d.target, 'a.csv')), "old a");
    verifyEqual(testCase, read_text(fullfile(d.target, 'b.csv')), "old b");
    verifyFalse(testCase, isfile(fullfile(d.target, 'c.csv')));
    verifyFalse(testCase, isfolder(backup));

end


function testRecoveryDiscardsUnmarkedBackup(testCase)
% Stopped while copying the backup: the copy is incomplete and unmarked,
% and the results have not been touched.

    d = ...
        testCase.TestData;

    backup = ...
        [d.target '.previous'];

    mkdir(backup);
    write_text(fullfile(backup, 'a.csv'), "old a");

    verifyTrue(testCase, ...
        recover_output_directory(d.target, ["a.csv"; "b.csv"]));

    verifyEqual(testCase, read_text(fullfile(d.target, 'a.csv')), "old a");
    verifyEqual(testCase, read_text(fullfile(d.target, 'b.csv')), "old b");
    verifyFalse(testCase, isfolder(backup));

end


function write_text(path, text)

    fid = ...
        fopen(path, 'w');

    fprintf(fid, '%s', text);
    fclose(fid);

end


function text = read_text(path)

    text = ...
        string(fileread(path));

end
