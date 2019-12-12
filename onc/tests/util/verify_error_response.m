function verify_error_response(obj, response)
    verifyTrue(obj, isfield(response, "errors"))
    if isfield(response, "errors")
        names = fieldnames(response.errors(1));
        verifyTrue(obj, ismember("errorCode", names))
        verifyTrue(obj, ismember("errorMessage", names))
    end
end