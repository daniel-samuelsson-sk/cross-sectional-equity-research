function replace_output_directory(staging_dir, target_dir, expected_files)
%REPLACE_OUTPUT_DIRECTORY Replace result files only with a complete set.
%
% REPLACE_OUTPUT_DIRECTORY(staging_dir, target_dir, expected_files)
%
% staging_dir must contain exactly expected_files, and target_dir may hold
% no other files. Neither may contain subfolders. The steps are:
%
%   1. Copy the current files to <target_dir>.previous.
%   2. Write the marker <target_dir>.previous/BACKUP_COMPLETE.
%   3. Move the new files into target_dir one at a time.
%   4. Delete the marker, then delete <target_dir>.previous.
%
% If a move fails, the files already replaced and the file being moved are
% restored from the copy, so target_dir ends up unchanged. A failed move can
% already have deleted its destination, for example when the staging file
% is locked by another program. If MATLAB stops abruptly instead, the
% marker tells recover_output_directory whether the copy is complete and
% must be restored (marker present) or can be discarded (marker absent).

staging_dir = ...
    char(staging_dir);

target_dir = ...
    char(target_dir);

backup_dir = ...
    [target_dir '.previous'];

marker = ...
    fullfile(backup_dir, 'BACKUP_COMPLETE');

expected_files = ...
    sort(string(expected_files(:)));


assert(isfolder(staging_dir), ...
    'OutputReplacement:MissingStaging', ...
    'Staging folder not found: %s', ...
    staging_dir);

assert(~isfolder(backup_dir), ...
    'OutputReplacement:StaleBackup', ...
    ['%s exists from an interrupted run. Run recover_output_directory ' ...
     'before generating new results.'], ...
    backup_dir);

assert( ...
    isequal(file_names(staging_dir), expected_files), ...
    'OutputReplacement:IncompleteStaging', ...
    'The staging folder does not contain exactly the expected files.');


if ~isfolder(target_dir)
    mkdir(target_dir);
end

assert( ...
    all(ismember(file_names(target_dir), expected_files)), ...
    'OutputReplacement:UnexpectedFiles', ...
    '%s contains files that this run does not own.', ...
    target_dir);


[copied, message] = ...
    copyfile(target_dir, backup_dir);

assert(copied, ...
    'OutputReplacement:BackupFailed', ...
    '%s', ...
    message);

fclose(fopen(marker, 'w'));


replaced = ...
    strings(0,1);

for k = 1:numel(expected_files)

    name = ...
        char(expected_files(k));

    [moved, message] = ...
        movefile( ...
            fullfile(staging_dir, name), ...
            fullfile(target_dir, name), ...
            'f');

    if ~moved

        if restore_files([replaced; expected_files(k)], backup_dir, target_dir)

            rmdir(backup_dir, 's');

            outcome = ...
                'The previous files were restored.';

        else

            outcome = ...
                sprintf(['Not all previous files could be restored. ' ...
                         'They are kept in %s and are restored at the ' ...
                         'start of the next run.'], ...
                    backup_dir);

        end

        error('OutputReplacement:ReplaceFailed', ...
            'Could not replace %s (%s). %s', ...
            name, ...
            message, ...
            outcome);

    end

    replaced(end+1,1) = ...
        expected_files(k); %#ok<AGROW>

end


delete(marker);
rmdir(backup_dir, 's');
rmdir(staging_dir, 's');

end


function names = file_names(folder)
%FILE_NAMES Sorted names of the files directly inside a folder.
%
% Subfolders are not allowed: movefile would move a result file into a
% folder that has the file's name and still report success.

listing = ...
    dir(folder);

listing = ...
    listing(~ismember({listing.name}, {'.', '..'}));

assert(~any([listing.isdir]), ...
    'OutputReplacement:UnexpectedFolder', ...
    '%s contains a subfolder. It may hold only result files.', ...
    folder);

names = ...
    sort(string({listing.name})');

end


function restored = restore_files(names, backup_dir, target_dir)
%RESTORE_FILES Put back the backed-up version of each listed file.
%
% A file that cannot be overwritten, for example because it is open in
% another program, counts as restored if it still equals its backup.

restored = ...
    true;

for k = 1:numel(names)

    name = ...
        char(names(k));

    previous = ...
        fullfile(backup_dir, name);

    current = ...
        fullfile(target_dir, name);

    if isfile(previous)

        copied = ...
            copyfile(previous, current, 'f') || ...
            same_content(previous, current);

        restored = ...
            restored && copied;

    elseif isfile(current)

        delete(current);

    end

end

end


function same = same_content(file_a, file_b)
%SAME_CONTENT True if both files can be read and have the same content.

try
    same = ...
        isequal(fileread(file_a), fileread(file_b));
catch
    same = ...
        false;
end

end
