classdef ConsoleProgressBar < handle
    properties (Access = public)
        percent  double  = 0.0
        segments uint32  = 10
        chHead   char    = '>'
        chBody   char    = '='
        chTrack  char    = '·'
        chLeft   char    = '['
        chRight  char    = ']'
        prepend  char    = []
        period   double  = 0.5
    end
    
    properties (Access = private)
        initialized logical = false   % true after the first bar render
        frame       uint32  = 0       % number of calss to update()
        renderTime  double  = 0       % timestamp (seconds) of last render
    end
    
    methods (Access = public)
        function this = ConsoleProgressBar(varargin)
            % parse input parameters with defaults
            p = inputParser();
            addOptional(p, 'percent'  , this.percent);
            addOptional(p, 'segments' , this.segments);
            addOptional(p, 'charHead' , this.chHead);
            addOptional(p, 'charBody' , this.chBody);
            addOptional(p, 'charTrack', this.chTrack);
            addOptional(p, 'charLeft' , this.chLeft);
            addOptional(p, 'charRight', this.chRight);
            parse(p, varargin{:});
            
            % store
            this.percent  = p.Results.percent;
            this.segments = p.Results.segments;
            this.chHead   = p.Results.charHead;
            this.chBody   = p.Results.charBody;
            this.chTrack  = p.Results.charTrack;
            this.chLeft   = p.Results.charLeft;
            this.chRight  = p.Results.charRight;
        end
        
        
        function update(this, newPercent)
            % Updates the percentage value and re-renders the bar if needed
            % Bar will be re-rendered only at the configured speed
            %
            % - newPercent: (double) A number in [0, 1] with the percentage to show
            
            this.frame = this.frame + 1;
            
            % sanitize newPercent
            if newPercent < 0, newPercent = 0; end
            if newPercent > 1, newPercent = 1; end
            
            % re-render only if the percent changed
            if newPercent > this.percent
                this.percent = newPercent;
                
                % render only if speed allows it
                tsNow = 100000 * rem(now, 1);
                if not(this.initialized) || (tsNow - this.renderTime) > this.period
                    this.render();
                end
            end
        end
        
        function complete(this)
            % Redraws the progress bar completelly full
            % Can be manually called in cases where a 1.0 value is never reached
            this.percent = 1.0;
            this.render();
        end
        
        function [barTxt, clearTxt] = render(this)
            % store last render time (seconds)
            this.renderTime = 100000 * rem(now, 1);
            
            % draws progress bar on command window
            progress  = floor(this.percent * this.segments); % [0, segments] e Z
            txtCompl  = repmat(this.chBody, 1, min(progress, this.segments - 1));
            remaining = max(this.segments - progress, 0);
            txtRemain = repelem(this.chTrack, remaining - 1);
            
            if (this.segments - progress) < 0.01
                progressChar = this.chBody;
            else
                progressChar = this.chHead;
            end
            
            barTxt = sprintf('%s%c%s%c%s%c %3.0f%%\n', ...
                             this.prepend,             ...
                             this.chLeft,              ...
                             txtCompl,                 ...
                             progressChar,             ...
                             txtRemain,                ...
                             this.chRight,             ...
                             this.percent * 100);

            if not(this.initialized)
                clearTxt = [];
                this.initialized = true;
            else
                if usejava('desktop')  % Check if GUI or CLI
                    clearTxt = repmat('\b', 1, length(barTxt));
                else
                    clearTxt = '\033[1F\033[2K\r';
                end
            end

            if nargout < 1
                fprintf([clearTxt '%s'], barTxt);
            end
        end
        
        function reset(this)
            this.percent = 0.0;
            this.frame = 0;
            this.initialized = false;
        end
    end
end