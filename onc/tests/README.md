**TESTING DOCUMENTATION**

This directory contains an automated test suite written for the MATLAB API Client using MATLAB's [unit test framework](https://www.mathworks.com/help/matlab/matlab-unit-test-framework.html), in particular as Class-Based Unit tests to easily share functionality.

If ever needed, the maintainer is welcome to change the tests structure to Function-Based tests or to TestSuite meta-classes instead of TestCase children. Future versions of MATLAB might provide better and easier testing methods.

Directory structure is as follows:

* suites:    Test suites
* util:      General use classes and methods

Although each test suite inherits from matlab.unittest.TestCase, each is written as a collection of test cases at the integration level. This simplified implementation at the time of this writing since we're testing returned structure instead of values.


**TESTING REQUIREMENTS**

1. MATLAB unit testing framework (usually included)
2. Create a text file named "TOKEN" (no extension) that contains your token. This file will NOT be uploaded to GitHub (due to a .gitignore entry) nor packed into the toolbox (file exclusion) and exists to avoid publishing your token by mistake. If in doubt, clear its contents before publishing changes.

**RUNNING TESTS**

1. IF YOU MADE CODE CHANGES: Uninstall the Onc MATLAB toolkit
1. In MATLAB, open (i.e. Right click -> "Open") the "tests" folder
2. Use MATLAB's command window to run all tests, using the commands described below:

*Running all tests:*
    in folder api-matlab-client, run command:
    runtests('onc/tests/suites', 'IncludeSubfolders', true);

(if it doesn't display test results table at the end, all tests pass. You can also remove semicolon to see test results)
    
*Running a test suite:*

    runtests(<NUMBER_OF_TEST_SUITE>)
    i.e.:
    runtests("Test01_Locations"); 

*Running a test case:*
    
    runtests(<NAME_OF_TEST_SUITE_CLASS>/<NAME_OF_CASE_METHOD>)

    i.e.:
    runtests("Test01_Locations/testInvalidTimeRangeGreaterStartTime")


**DEVELOPING TESTS**

New test suite files or new test case methods will be detected by the MATLAB Unit Test framework automatically. In most cases, duplicating an existing suite or case should suffice for starters.

New test suites should be written as classes that inherit from matlab.unittest.TestCase.

New test case methods in a test suite should have the "test" prefix and produce failure conditions as depicted in Mathworks' documentation (i.e. throwing soft failures as explained in https://www.mathworks.com/help/matlab/ref/matlab.unittest.qualifications.verifiable-class.html ).


**CODE DOCUMENTATION**

Code documentation follows the format recognized by MATLAB's "help" and "doc" commands:

- File starts with class title and description
- Class properties have their description comment at the same line
- Methods have their description as the first comment inside their code

Maintainers are free to consider changing this format (i.e. to Doxygen) if the required add-ons are actively maintained and work in all platforms.