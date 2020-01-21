function status = test_url(url, showInfo, timeout)
    % prepare HTTP request
    request = matlab.net.http.RequestMessage;
    request.Method = 'HEAD';
    uri = matlab.net.URI(url);
    
    % prepare MATLAB request options
    options = matlab.net.http.HTTPOptions();
    options.ConnectTimeout = timeout;

    % run and time request
    if showInfo, fprintf('\nRequesting URL through HEAD:\n   %s\n', url); end
    response = send(request, uri, options);
    status = double(response.StatusCode);
end

