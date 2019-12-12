function runTestCase(suiteName, caseName)
    run('globals.m');

    % Run a single test case
    obj = eval(suiteName);
    testResults = run(obj, caseName);  % Method name
    rt = table(testResults);
    disp(rt);
end