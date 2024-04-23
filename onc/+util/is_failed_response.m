function isFailed = is_failed_response(response, status)
    %% Checks if a server response describes a failure
    %
    % * response: (struct) Response as returned by do_request()
    % - status:   (double) http status code
    %
    % Returns: (Logical) true when the response is a failure
    isFailed = false;

    % Fail if HTTP status code is not a 2xx
    if exist('status', 'var')
        if status < 200 || status > 226
            isFailed = true;
            return
        end
    end

    % Fail if the response is an error description
    if isfield(response, "errors")
        names = fieldnames(response.errors(1));
        isFailed = ismember("errorCode", names) && ismember("errorMessage", names);
    end
end