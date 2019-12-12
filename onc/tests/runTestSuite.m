function runTestSuite(suite)
    run('globals.m');	
    
    % Run a single test suite
	switch suite
		case 1
			testResults = run(Test01_Locations);
		case 2
			testResults = run(Test02_Deployments);
		case 3
			testResults = run(Test03_DeviceCategories);
		case 4
			testResults = run(Test04_Devices);
		case 5
			testResults = run(Test05_Properties);
		case 6
			testResults = run(Test06_DataProductDiscovery);
		case 7
			testResults = run(Test07_DataProductDelivery);
        case 8
			testResults = run(Test08_RealTime);
        case 9
			testResults = run(Test09_ArchiveFiles);
	end

    rt = table(testResults);
	fprintf('\n');
    disp(rt);
end