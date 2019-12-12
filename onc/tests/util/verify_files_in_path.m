% verifies that path has exactly n files
function verify_files_in_path(obj, path, n)
    files = dir(sprintf('%s/*.*', path));
    
    % remove . and ..
    count = 0;
    for i = 1 : numel(files)
        if not(files(i).isdir)
            count = count + 1;
        end
    end
    
    verifyEqual(obj, count, n);
end