**TESTING DOCUMENTATION**

This directory contains an automated test suite written for the MATLAB API Client using MATLAB's [unit test framework](https://www.mathworks.com/help/matlab/matlab-unit-test-framework.html), in particular as Class-Based Unit tests to easily share functionality.

If ever needed, the maintainer is welcome to change the tests structure to Function-Based tests or to TestSuite meta-classes instead of TestCase children. Future versions of MATLAB might provide better and easier testing methods.

Directory structure is as follows:

* suites:    Test suites
* util:      General use classes and methods

Although each test suite inherits from matlab.unittest.TestCase, each is written as a collection of test cases at the integration level. This simplified implementation at the time of this writing since we're testing returned structure instead of values.


**TESTING REQUIREMENTS**

1. MATLAB unit testing framework (usually included by default)
2. Check "globals.m" to make sure default configuration (i.e. API token) is correct


**RUNNING TESTS**

In MATLAB, open the "tests" folder. Now you can use MATLAB's command window to run all tests, a single test suite or a single test case, as in the examples below.

*Running all tests:*

    runAllTests

*Running a test suite:*

    runTestSuite <NAME_OF_TEST_SUITE_CLASS>
    i.e.:
    runTestSuite TestLocations

*Running a test case:*

    runTestCase <NAME_OF_TEST_SUITE_CLASS> <NAME_OF_CASE_METHOD>
    i.e.:
    runTestCase TestLocations testFilterPropertyCode


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