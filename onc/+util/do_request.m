
function [result, duration, info] = do_request(url, filters, varargin)
    [timeout, showInfo, rawResponse, showProgress] = ...
        util.param(varargin, 'timeout', 120, 'showInfo', false, ...
                   'rawResponse', false, 'showProgress', false);
    
    % sanitize filters
    filters = util.sanitize_filters(filters);

    % prepare HTTP request
    request = matlab.net.http.RequestMessage;
    uri = matlab.net.URI(url);
    uri.Query = matlab.net.QueryParameter(filters);
    fullUrl = char(uri);
    
    % prepare options
    options = matlab.net.http.HTTPOptions();
    options.ConnectTimeout = timeout;
    if rawResponse, options.ConvertResponse = false; end
    
    % add progress bar if required
    if showProgress
        options.UseProgressMonitor = true;
        options.ProgressMonitorFcn = @onc.ProgressBar;
    end

    % run and time request
    if showInfo, fprintf('\nRequesting URL:\n   %s\n', fullUrl); end
    tic
    response = send(request, uri, options);
    duration = toc;
    txtDuration = util.format_duration(duration);
    if showInfo, fprintf('   Web Service response time: %s\n', txtDuration); end

    status = response.StatusCode;
    switch status
        case 200
            % OK
            if rawResponse
                result = response;
            else
                result = response.Body.Data;
            end
        case 202
            % Accepted, no need to print error, handle manually
            result = response.Body.Data;
        case 400
            % Bad request
            result = response.Body.Data;
            util.print_error(response, fullUrl);
        case 401
            % Unauthorized
            fprintf('\nERROR 401: Unauthorized. Please verify your user token.\n')
            result = response.Body.Data;
        case 503
            % Down for maintenance
            fprintf('\nERROR 503: Service unavailable.\nWe could be down for maintenance; ');
            fprintf('visit https://data.oceannetworks.ca for more information.\n')
            result = struct('errors', [struct('errorCode', 503, 'message', 'Service Unavailable')]);
        otherwise
            result = response.Body.Data;
            fprintf('\nERROR: The request failed with HTTP error %d\n', status)
    end

    size = 0;
    if status == 200
        hConLength = response.getFields('Content-Length');
        if isempty(hConLength)
            size = '0';
        else
            size = str2double(hConLength.Value);
        end
        
    end

    info = struct('status', status, 'size', size);
end