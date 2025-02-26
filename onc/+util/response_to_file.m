function [response, endCode] = response_to_file( ...
    uri, options, fileDir, fileName, overwrite)
    %% Send a GET request and save a response to a file
    %
    % response_to_file(uri, options, fileDir, fileName, overwrite)
    %
    % * uri:        (URI)           Uniform resource identifier
    % * options:    (HTTPOptions)   Options for HTTP request messages
    % * fileDir:    ([char])        Directory where a file is saved to
    % * fileName:   ([char])        Name under which a file is saved
    % - overwrite:  (logical)       Flag for overwriting files with same names
    %
    % Returns:
    %   response:   (ResponseMessage)   HTTP response returned by a server
    %   endCode:    (int)               Status indicator if the file has been saved 
    %                                   {0: done, -1: error, -2: fileExists}
    % check inputs
    if nargin < 4
        error('onc:response_to_file:InsufficientInput', ...
              'At least four input arguments are expected')
    elseif nargin < 5
        overwrite = false;
    end
    % initialize variables
    response = matlab.net.http.ResponseMessage();
    % form a file path
    if ~isempty(fileDir)
        filePath = sprintf('%s/%s', fileDir, fileName);
        % create the directory if it doesn't exist
        isCreated = util.prepare_directory(fileDir);
        if ~isCreated
            fprintf(['ERROR: Could not create output path at "' fileDir '". ' ...
                     'File "' fileName '" was NOT saved.\n'])
            endCode = -1;
            return
        end
    else
        filePath = fileName;
    end
    % check if a file can be written with the provided name
    if ~overwrite && isfile(filePath)
        endCode = -2;
        return
    end
    % get a file and save it
    matlabVersion = version('-release');
    year = str2double(matlabVersion(1:end-1));
    request = matlab.net.http.RequestMessage('GET');
    try
        if year >= 2021
            consumer = onc.FileResponseConsumer( ...
                filePath, overwrite, 'w', 'n', 'ISO-8859-1');
        else
            consumer = onc.FileResponseConsumer( ...
                filePath, overwrite, 'w', 'n');
        end
        response = request.send(uri, options, consumer);
        if isa(response.Body.Data, 'MException')
            if strcmp(response.Body.Data.identifier, 'onc:FileExistsError')
                endCode = -2;
                return
            else
                throw(response.Body.Data)
            end
        end
    catch ME
        disp(ME)
        endCode = -1;
        return
    end  
    endCode = 0;
end