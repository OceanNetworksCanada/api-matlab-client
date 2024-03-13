function [result, info] = do_request(url, filters, varargin)
    [timeout, showInfo, rawResponse, showProgress] = ...
        util.param(varargin, 'timeout', 120, 'showInfo', false, 'rawResponse', false, 'showProgress', false);
    
    % sanitize filters
    filters = util.sanitize_filters(filters);

    % prepare HTTP request
    request = matlab.net.http.RequestMessage;
    uri = matlab.net.URI(url);
    uri.Query = matlab.net.QueryParameter(filters);
    fullUrl = char(uri);
    
    % prepare MATLAB request options
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
    %response = send(request, uri, options);
    response = request.send(uri,options);
    
    duration = toc;
    
    % print duration
    if showInfo
        txtDuration = util.format_duration(duration);
        fprintf('   Web Service response time: %s\n', txtDuration);
    end
    
    % prepare result
    status = double(response.StatusCode);
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
        otherwise
            util.print_error(response, fullUrl);
            if status == 400 || status == 401
                throw(util.prepare_exception(status,double(response.Body.Data.errors.errorCode)));
            else
                throw(util.prepare_exception(status));
            end
    end

    % prepare info.size only if the response is a file, otherwise 0
    size = 0;
    if status == 200
        hConLength = response.getFields('Content-Length');
        if isempty(hConLength)
            size = '0';
        else
            size = str2double(hConLength.Value);
        end
        
    end

    info = struct('status', status, 'size', size, 'duration', duration);
end