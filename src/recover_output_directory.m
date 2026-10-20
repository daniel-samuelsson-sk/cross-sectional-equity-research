function recovered = recover_output_directory(target_dir, expected_files)
%RECOVER_OUTPUT_DIRECTORY Restore a consistent result set after a crash.
%
% recovered = RECOVER_OUTPUT_DIRECTORY(target_dir, expected_files)
%
% Handles the state left behind if MATLAB stopped abruptly inside
% replace_output_directory:
%
%   - No <target_dir>.previous: nothing to do.
%   - <target_dir>.previous with BACKUP_COMPLETE: the run stopped while
%     replacing files, so target_dir may mix old and new files. The
%     complete previous set is restored.
%   - <target_dir>.previous without the marker: the run stopped before the
%     copy was complete (target_dir untouched) or after the replacement
%     had finished (target_dir complete). The copy is discarded.
%
% recovered is true if a leftover folder was handled.

target_dir = ...
    char(target_dir);

backup_dir = ...
    [target_dir '.previous'];

recovered = ...
    isfolder(backup_dir);

if ~recovered
    return
end


if isfile(fullfile(backup_dir, 'BACKUP_COMPLETE'))

    for name = reshape(string(expected_files), 1, [])

        previous = ...
            fullfile(backup_dir, name);

        current = ...
            fullfile(target_dir, name);

        if isfile(previous)

            [copied, message] = ...
                copyfile(previous, current, 'f');

            assert(copied, ...
                'OutputRecovery:RestoreFailed', ...
                'Could not restore %s (%s). %s was kept.', ...
                name, ...
                message, ...
                backup_dir);

        elseif isfile(current)

            delete(current);

        end

    end

    fprintf('Restored the previous results from %s.\n', backup_dir);

end


rmdir(backup_dir, 's');

end
