function ex = prepare_exception(status, errorCode)
    %% Prepares a throwable exception object for the response
    %
    % * response: (struct) Response as returned by do_request()
    % - status:   http response code
    % - errorCode: optional
    %              specific error code returned in field errors (only for 400 and 401)
    %
    % Returns: (MException) @TODO
    switch status
        case 400
            ex = MException(sprintf('onc:http400:error%d', errorCode), 'HTTP 400: Invalid request parameters');
        case 401
            ex = MException(sprintf('onc:http401:error%d', errorCode), 'HTTP 401: Invalid token');
        case 404
            ex = MException('onc:http404', 'HTTP 404: Not found');
        case 410
            ex = MException('onc:http410', 'HTTP 410: Deleted from FTP server');
        case 500
            ex = MException('onc:http500', 'HTTP 500: Server error');
        case 503
            ex = MException('onc:http503', 'HTTP 503: Service unavailable or under maintenance');
        otherwise
            ex = MException(sprintf('onc:http%d', status), sprintf('HTTP %d: Request error', status));
    end
end

