% extracts parameters from the args object of type {varargin}
% The first argument is the 'varargin' variable parameters object from another function
% And the arguments that follow are pairs of 'name' and 'defaultValue' to extract
% Returns the values parsed from args
% Example usage: [a, b] = util.param(varargin, 'a', 1, 'b', 2)
function [varargout] = param(args, varargin)
    p = inputParser;
    n = length(varargin);

    names = [];
    for i = 1 : 2 : n
        name     = varargin{i};
        names    = [names, string(name)];
        defValue = varargin{i + 1};
        addOptional(p, name, defValue);
    end
    
    if n == 2 && isstruct(varargin{2})
        % Handle struct param seperately
        name = names(1);
        if length(args) == 1
            % one struct given
            varargout{1} = args{1};
        else
            varargout{1} = varargin{2}; 
        end
    else
        % parse using inputParser
        parse(p, args{:});
        for i = 1 : numel(names)
            value = p.Results.(names(i));
            varargout{i} = value;
        end
    end
end