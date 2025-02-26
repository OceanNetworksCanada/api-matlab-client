classdef FileResponseConsumer < matlab.net.http.io.FileConsumer
    %% FileResponseConsumer Modified version of the FileConsumer class
    %
    %   Behaviour differences:
    %       1.  Keeps the response body data instead of replacing it with 
    %           a filename when the response status code is not 200.
    %       2.  Accepts an overwrite argument and overwrites files when 
    %           it is "true" even if a specific filename wasn't given.
    properties
        overwrite logical               % Permission to overwrite files
        isOverwritingStopped logical    % Flag of whether file overwriting was prevented
        outputPath char = ''            % Path to an output file or directory
    end

    methods
        function obj = FileResponseConsumer(filePath, overwrite, varargin)
            obj@matlab.net.http.io.FileConsumer(filePath, varargin{:});
            obj.outputPath = filePath;
            obj.overwrite = overwrite;
        end

        function [len, stop] = putData(obj, data)
            %% Process the next block of data 
            % 
            % putData(data)
            %
            % * data:   ([uint8])   Array of bytes to be processed
            %
            % Returns:
            %   len:    (int)       Number of bytes processed at the pass
            %   stop:   (logical)   Indicator of a response end
            if obj.isOverwritingStopped
                len = 0;
                stop = true;
                obj.Response.Body.Data = MException( ...
                    'onc:FileExistsError', ...
                    'Data product file exists in destination but overwrite is set to false');
            elseif double(obj.Response.StatusCode) == 200
                [len, stop] = putData@matlab.net.http.io.FileConsumer(obj, data);
            else
                [len, stop] = putData@matlab.net.http.io.ContentConsumer(obj, data);
                if isempty(data)
                    responseData = reshape(obj.Response.Body.Data, 1, []);
                    if ~isempty(obj.ContentType)
                        charset = obj.ContentType.getParameter('charset');
                        unicodeStr = native2unicode(responseData, charset);
                        if strcmp(obj.ContentType.Subtype, 'json')
                            obj.Response.Body.Data = jsondecode(unicodeStr);
                        else
                            obj.Response.Body.Data = unicodeStr;
                        end
                    else
                        unicodeStr = native2unicode(responseData);
                        obj.Response.Body.Data = unicodeStr;
                    end
                end
            end
        end
    end

    methods (Access=protected)
        function len = start(obj)
            %% Call when the response starts
            len = [];
            obj.isOverwritingStopped = false;
            if double(obj.Response.StatusCode) == 200
                if isfolder(obj.outputPath)
                    [filename, ext] = obj.getfilenameandextension();
                    if endsWith(obj.outputPath, '/')
                        filePath = string(obj.outputPath) + string(filename);
                    else
                        filePath = string(obj.outputPath) + "/" + string(filename);
                    end
                    if startsWith(ext, '.')
                        filePath = string(filePath) + string(ext);
                    else
                        filePath = string(filePath) + '.' + string(ext);
                    end
                    if obj.overwrite && isfile(filePath)
                        delete(filePath)
                    elseif isfile(filePath)
                        obj.isOverwritingStopped = true;
                        return
                    end
                end
                len = start@matlab.net.http.io.FileConsumer(obj);
            end
        end
    end

    methods (Access=private)
        function [name, ext] = getfilenameandextension(obj)
            %% Return a file name and extension based on request's headers and URI
            % Copied and reduced private method of MATLAB FileConsumer.

            % check the Content-Disposition field of the header
            name = '';
            ext = '';
            cdf = obj.Header.getValidField('Content-Disposition');
            if ~isempty(cdf)
                cdf = cdf(end);
                filename = cdf.getParameter('filename');
                if ~isempty(filename)
                    [~, name, ext] = fileparts(filename);
                    return;
                end
            end
            % if no Content-Disposition, check name and possible extension in URI
            path = obj.URI.Path;
            if ~isempty(path)
                filename = char(path(end));
                if ~isempty(filename)
                    [~, name, ext] = fileparts(filename);
                end
            end
        end 
    end
end
