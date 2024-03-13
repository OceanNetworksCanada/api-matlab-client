function print_error(response, url)
    % try to find status in response
    
    status = double(response.StatusCode);
    
    if status == 400
        % Bad request
        fprintf('\nERROR 400 - Bad Request:\n  %s\n\n', url)
        print_error_message(response.Body.Data);

    elseif status == 401
        % Unauthorized
        fprintf('\nERROR 401: Unauthorized. Please verify your user token.\n')
        print_error_message(response.Body.Data)

    elseif status == 404
        %Not Found
        fprintf('\nERROR 404: Not Found \n')

    elseif status == 500
        % Internal Server Error
        fprintf('\nERROR 500: Internal Server Error - %s\n', url)
        fprintf('The API failed to process your request. You might want to retry later in case this is a temporary issue (i.e. Maintenance).\n')
    
    elseif status == 503
        % Down for maintenance
        fprintf('\nERROR 503: Service unavailable.\nWe could be down for maintenance; ');
        fprintf('visit https://data.oceannetworks.ca for more information.\n')
    
    else
        fprintf('\nERROR: The request failed with HTTP error %d\n', status);
    end
end

% helper function
function print_error_message(payload)
    % Make sure the payload was parsed automatically
    if ~isstruct(payload)
        payload = jsondecode(payload);
    end

    %if isfield(payload, 'errors')
    for i = 1 : numel(payload.errors)
        e = payload.errors(i);
        msg = e.errorMessage;
        parameters = e.parameter;
        fprintf('  Parameter "%s" -> %s\n', string(parameters), msg)
    end
    fprintf('\n');
end

