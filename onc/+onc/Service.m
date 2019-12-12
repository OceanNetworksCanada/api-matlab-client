classdef Service < handle
    %% Generic parent for all service classes
    % Provides generic functionality
    
    methods (Access = protected, Hidden = true)
        function [result, duration, status] = doRequest(this, url, filters)
            %% A wrapper of util.do_request
            % Performs a request to the Onc API
            %
            % * url      ([char]) Url to send the request to
            % * filters: (struct) Describes the data origin
            %
            % Returns: ([struct]) 
            [result, duration, status] = util.do_request(url, filters, 'timeout', this.timeout, 'showInfo', this.showInfo);
        end
        
        function status = testUrl(this, url)
            %% Test a url without downloading its contents
            %
            % * url ([char]) Url to send the request to
            %
            % Returns: (int) the status code obtained after the HEAD request to the url
            
            % prepare HTTP request
            request = matlab.net.http.RequestMessage;
            request.Method = 'HEAD';
            uri = matlab.net.URI(url);
            options = matlab.net.http.HTTPOptions('ConnectTimeout', this.timeout);
            
            % run and time request
            response = send(request, uri, options);
            status = response.StatusCode;
        end
        
        
        function url = serviceUrl(this, service)
            %% Returns the absolute base url for an API service
            %
            % * service ([char]) API service as named in the docs
            %
            % Returns: ([char]) Absolute base url, or '' if the service string is invalid
            if ismember(service, ['locations', 'deployments', 'devices', 'deviceCategories', 'properties', 'dataProducts', 'archivefiles', 'scalardata', 'rawdata'])
                url = sprintf('%sapi/%s', this.baseUrl, service);
                return
            else
            end
        
            url = '';
            return
        end
    end
end

