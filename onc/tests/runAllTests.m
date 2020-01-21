function runAllTests()
    import matlab.unittest.TestSuite;
    run('globals.m');    
    
    %  Runs all tests suites and displays results    
    suiteFolder = TestSuite.fromFolder('./suites');
    testResults = run(suiteFolder);
    rt = table(testResults);
    disp(rt);
end