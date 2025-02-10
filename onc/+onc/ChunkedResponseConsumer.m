classdef ChunkedResponseConsumer < matlab.net.http.io.GenericConsumer
%% ChunkedResponseConsumer Consumer with an option to control the size of 
% chunks which a response is processed in.
%
%   Default MATLAB (R2022b) implementation of method `send` in 
%   `matlab.net.http.ResponseMeassage` has a size limit of 2^30 bytes. 
%   Responses of greater sizes cause an error at the stage of decoding.
%
%   This consumer allows to mitigate the size limitation by processing 
%   responses in parts of a specified size. Although built-in GenericConsumer
%   seems to be able to handle big responses as well, its processing speed is 
%   slower since MATLAB built-in consumers process parts of responses when 
%   they get them. This consumer accumulates data in a buffer of the given 
%   size and processes the whole accumulated chunk in one pass.

    properties (Access=private)
        chunkSize           % Size of chunks to process in bytes (int)
        responseBuffer      % Buffer to accumulate data bytes (cell array)
        positionInBuffer    % Index of next buffer cell to be filled (int)
        accumulatedBytes    % Number of bytes accumulated in buffer (int)
    end

    methods
        function obj = ChunkedResponseConsumer(chunkSize)
        %% Initialize a customized GenericConsumer for processing responses in 
        % chunks
        %
        % ChunkedResponseConsumer(chunkSize)
        %
        % - chunkSize: (int) Number of bytes to accumulate in a buffer
        %
        % Returns: (ChunkedResponseConsumer) Consumer object

            if nargin < 1
                chunkSize = 2^29; % default value
            else
                if ~isnumeric(chunkSize) || length(chunkSize) > 1
                    error('MatlabAPI:ChunkedResponseConsumer:BadInputType', ...
                    'chunkSize is expected to be a number.')
                end
                if chunkSize > 2^30
                    error('MatlabAPI:ChunkedResponseConsumer:BadInputValue', ...
                    ['Provided chunkSize is too big and will cause an ' ...
                    'error when a response is decoded if its size ' ...
                    'exceeds 2^30 bytes. Provided value: ' num2str(chunkSize)])
                end
            end
            obj@matlab.net.http.io.GenericConsumer;
            obj.chunkSize = chunkSize;
        end
    
        function [len, stop] = putData(obj, data)
        %% Process the next block of data 
        % 
        % putData(data)
        %
        % - data: ([uint8]) Array of bytes to be processed
        %
        % Returns:
        %   (int)       Number of bytes processed at the pass
        %   (logical)   Indicator of a response end
        
            stop = false;
            len = numel(data);
            if ~isempty(data)
                if obj.accumulatedBytes + len > obj.chunkSize
                    % process an accumulated chunk
                    chunk = cell2mat(obj.responseBuffer);
                    obj.PutMethod(chunk);
                    obj.responseBuffer = {};
                    obj.accumulatedBytes = 0;
                    obj.positionInBuffer = 1;
                end
                % store a data block in responseBuffer
                % vertical structure of responseBuffer is important for 
                % stacking cells with cell2mat() into a vertical vector
                obj.responseBuffer{obj.positionInBuffer, 1} = data;
                obj.accumulatedBytes = obj.accumulatedBytes + len;
                obj.positionInBuffer = obj.positionInBuffer + 1;
            else
                if ~isempty(obj.responseBuffer)
                    % process the rest of data stored in responseBuffer
                    chunk = cell2mat(obj.responseBuffer);
                    obj.PutMethod(chunk);
                end
                % extract response data to CurrentDelegate
                obj.PutMethod(uint8.empty);
                obj.CurrentLength = length(obj.CurrentDelegate.Response.Body.Data);
                obj.PutMethod = [];
                % transfer data from CurrentDelegate to obj.Response
                putData@matlab.net.http.io.GenericConsumer(obj, []);
                stop = true;
            end
        end
    end

    methods (Access = protected)
        function buffsize = start(obj)
            %% Call when the response starts
            obj.responseBuffer = {}; 
            obj.CurrentLength = 0;
            obj.accumulatedBytes = 0;
            obj.positionInBuffer = 1;
            buffsize = start@matlab.net.http.io.GenericConsumer(obj);
        end
    end
end
