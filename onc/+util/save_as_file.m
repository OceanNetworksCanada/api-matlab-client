% Saves the file downloaded in the response object, in the outPath, with filename
% @keywords internal
%
% @param response  An http raw response as returned by httr::GET
% @param filePath  Path where the file will be saved
% @param fileName  Name of the file to save
% @param overwrite If true will overwrite files with the same name
% @return (numeric) Result code from {0: done, -1: error, -2: fileExists}
function endCode = save_as_file(response, filePath, fileName, varargin)
[overwrite] = util.param(varargin, 'overwrite', false);

fullPath = fileName;
if ~isempty(filePath)
    fullPath = sprintf('%s/%s', filePath, fileName);
    % Create outPath directory if not exists
    if not(util.prepare_directory(filePath))
        fprintf('   ERROR: Could not create ouput path at "%s". File "%s" was NOT saved.\n', filePath, fileName);
        endCode = -1;
        return;
    end
end

% Save file in outPath if it doesn't exist yet
if overwrite || not(isfile(fullPath))
    try
        matlabVersion = version('-release');
        year = str2double(matlabVersion(1:end-1));
        if year >= 2021
            f = fopen(fullPath, 'w','n','ISO-8859-1');
        else
            f = fopen(fullPath, 'w','n');
        end
        
        if f ~= -1
            fwrite(f, response);
        else
            endCode = -1;
            return;
        end
        fclose(f);
    catch ex
        disp(ex);
        endCode = -1;
        return;
    end
else
    throw(MException('onc:FileExistsError', 'Data product file exists in destination but overwrite is set to false'));
end

endCode = 0;
end
