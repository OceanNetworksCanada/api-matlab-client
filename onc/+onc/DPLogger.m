% Poll log
%
classdef DPLogger < handle
    %% A helper for DataProductFile that prints progress messages
    % Keeps track of the messages printed in a single product download process

    properties
       lastMsg
       count
       newLine
    end
    
	methods
        function this = DPLogger()
            %% Initializer
            %
            % - showInfo (logical) As provided by the Onc class
            
            this.lastMsg = {};
            this.newLine = false; % true when last msg printed includes a newline
            this.count = 0;
        end
        
        function printLine(this, msg)
            if this.count == 0 || ~strcmp(this.lastMsg, msg)
                fprintf('\n   %s', msg);
                this.lastMsg = msg;
            else
                fprintf('.');
            end
            this.count = this.count + 1;
        end

        function printResponse(this, response)
            %% Adds a message to the messages list if it's new
            % Prints message to console, or '.' if it is a redundant message
            %
            % * response (object) Parsed httr response

            % Try to extract the response message
            msg = 'Generating data product';
            
            r1 = response(1);
            
            if isstruct(r1)
                if isfield(r1, 'message')
                    msg = r1.message;
                elseif isfield(r1, 'status')
                    msg = r1.status;
                end
            end
            
            % Store and print message
            if this.count == 0
                fprintf('\n   %s', msg);
                this.lastMsg = msg;
            else
                if ~strcmp(this.lastMsg, msg)
                    fprintf('\n   %s', msg);
                    this.lastMsg = msg;
                else
                    fprintf('.');
                end
            end
            this.count = this.count + 1;
        end
    end
end