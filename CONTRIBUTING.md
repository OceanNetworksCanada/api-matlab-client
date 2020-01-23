# Contributing

This project is maintained by Ocean Network Canada's Data Team, and is provided to the public
in order to fascilitate and promote ONC Data usage. Pull requests from external users are valuable and
will be considered; however, note that we try to maintain the Python, MATLAB and R client libraries
as consistent with each other as possible, thus new features will require work in all of them.


## Codebase description

The Onc class has been engineered not as a MATLAB script or collection of functions, but as
an object-oriented codebase in order to increase modularity & cohesion, and reduce coupling
between code components. Following software engineering practices allows this Toolkit to be
easily extended and maintained in the future (as long as the maintainers are familiar with
[MATLAB's Object Oriented Capabilities](https://www.mathworks.com/discovery/object-oriented-programming.html)).

The **onc** package contains the classes that offer most of the functionality provided by the **Onc**
class, separated in small, single-responsibility modules. Each file has been carefully commented.

The **util** package acts as a *namespace* for general-use functions that are consumed
by the classes in the **onc** package. This package exists as a strategy to reduce code
redundancy, considering MATLAB's particularities.

The **ext** package was created to contain code from *external* projects (i.e. found in FileExchange).

The **tests** folder contains the test suites (check its README.md file).


## Publishing a new version

1. Make sure there are no logging messages, output directories, temporal files, etc.
2. Run all test suites; all tests should pass
3. Double-click **onc.prj**, update version number and click **Package**
4. Rename the `.mltbx` file generated as: `onc-VERSION.mltbx`. (ex: `onc-2.1.0.mltbx`)
5. Delete the contents of the **"dist"** directory and place inside the toolkit file
3. `git add .`
4. `git status` and review the file changes; double-check that no unintended files are uploaded.
5. `git commit -m "your commit message"`
6. `git push`