function verify_no_next_page(testCase, data)
%VERIFY_NO_NEXT_PAGE only passes if data is a response where next is null
    verify_has_field(testCase, data, 'next');
    verifyTrue(testCase, isempty(data.next));

end

