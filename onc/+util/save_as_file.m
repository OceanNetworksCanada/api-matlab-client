% Saves the file downloaded in the response object, in the outPath, with filename
% @keywords internal
%
% @param response  An http raw response as returned by httr::GET
% @param filePath  Path where the file will be saved
% @param fileName  Name of the file to save
% @param overwrite If true will overwrite files with the same name
% @return (numeric) Result code from {0: done, -1: error, -2: fileExists}
function endCode = save_as_file(dataToWrite, filePath, fileName, varargin)
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
        [~, ~, ext] = fileparts(fileName);
        % if result is an image file or .xml file, use other save methods instead of fwrite. 
        if strcmp(ext, '.png') || strcmp(ext, '.jpg')
            imwrite(dataToWrite, fullPath);
        elseif strcmp(ext, '.xml')
            xmlwrite(fullPath, dataToWrite);
        else
            % open output file
            if year >= 2021
                f = fopen(fullPath, 'w','n','ISO-8859-1');
            else
                f = fopen(fullPath, 'w','n');
            end
            
            % write result if open file successfully
            if f ~= -1
                fwrite(f, char(dataToWrite));
            else
                endCode = -1;
                return;
            end
            fclose(f);
        end
    catch ex
        disp(ex);
        endCode = -1;
        return;
    end
else
    % if file exists and overwrite is false, raise exception
    throw(MException('onc:FileExistsError', 'Data product file exists in destination but overwrite is set to false'));
end

endCode = 0;
end
