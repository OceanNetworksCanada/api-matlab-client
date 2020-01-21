function print_error(response, url)
    % try to find status in response
    
    status = double(response.StatusCode);
    
    if status == 400
        fprintf('\nERROR 400 - Bad Request:\n  %s\n\n', url)
        payload = response.Body.Data;

        % Make sure the payload was parsed automatically
        if ~isstruct(payload)
            payload = jsondecode(payload);
        end

        if isfield(payload, 'errors')
            for i = 1 : numel(payload.errors)
                e = payload.errors(i);
                msg = e.errorMessage;
                parameters = e.parameter;
                fprintf('  Parameter "%s" -> %s\n', string(parameters), msg)
            end
            fprintf('\n');

        elseif status == 401
            fprintf('\nERROR 401: Unauthorized - %s\n', url)
            fprintf('Please check that your Web Services API token is valid. Find your token in your registered profile at https://data.oceannetworks.ca.\n')

        elseif status == 500
            fprintf('\nERROR 500: Internal Server Error - %s\n', url)
            fprintf('The API failed to process your request. You might want to retry later in case this is a temporary issue (i.e. Maintenance).\n')
        else
            fprintf('\nERROR %d: The request failed.\n', status)
        end
    end
end
