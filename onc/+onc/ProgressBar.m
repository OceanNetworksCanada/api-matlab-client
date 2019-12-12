classdef ProgressBar < matlab.net.http.ProgressMonitor
    properties
        ProgHandle
        NewDir     matlab.net.http.MessageType = matlab.net.http.MessageType.Request
        textBar
        Value
        Direction
    end
    
    methods
        function obj = ProgressBar
            obj.Interval = 0.5;
            obj.textBar = ext.ConsoleProgressBar('segments', 50);
            obj.textBar.prepend = '   ';
        end
        
        function done(obj)
            obj.textBar.complete();
        end
        
        function set.Value(obj, value)
            obj.update(value);
        end
    end
    
    methods (Access = private)
        
        function update(obj, value)
            % called when Value is set
            percent = double(value) / double(obj.Max);
            
            if ~isempty(obj.textBar)
                obj.textBar.update(percent);
            end
        end
    end
end