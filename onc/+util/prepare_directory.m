% Creates directory if it does not exist
% Supports directory paths with or without filenames
% @keywords internal
%
% @param filepath (character) Directory path
% @return (logical) true if the directory was created or already exists
function isDone = prepare_directory(path)
    % MATLAB will search in all paths, so we need an absolute route
    if util.is_relative_path(path)
        path = sprintf('%s/%s', pwd, path);
    end

    isDone = true;
    if not(exist(path, 'dir'))
       isDone = (mkdir(path) == 1);
    end
end
