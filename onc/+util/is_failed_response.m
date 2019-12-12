function r = is_failed_response(response)
    r = false;
    if isfield(response, "errors")
        names = fieldnames(response.errors(1));
        r = ismember("errorCode", names) && ismember("errorMessage", names);
    end
end

