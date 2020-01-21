function runTestCase(suiteName, caseName)
    import matlab.unittest.TestSuite;
    run('globals.m');    

    % Run a single test case
    obj = eval(suiteName);
    testResults = run(obj, caseName);  % Method name
    rt = table(testResults);
    disp(rt);
end