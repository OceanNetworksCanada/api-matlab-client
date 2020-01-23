# Contributing

This project is maintained by Ocean Network Canada's Data Team, and is provided to the public
in order to fascilitate and promote ONC Data usage. Pull requests from external users are valuable and should be considered; however, note that we try to maintain the Python, MATLAB and R client libraries as consistent with each other as possible, thus new features will require work in all of them.


## Codebase design rationale

The Onc class has been engineered not as a MATLAB script or collection of functions, but as
a software product with an active maintenance cycle.

The Object-Oriented paradigm that directs the codebase increases modularity & cohesion, and reduces coupling between code components. Following software engineering practices facilitates extending and maintaining the code in the future, as long as the maintainers are familiar with [MATLAB's Object Oriented Capabilities](https://www.mathworks.com/discovery/object-oriented-programming.html). The advantages of Object Oriented Design over monolithic, procedural "spaghetti" code are well-known, specially in projects with multiple maintainers.

The directory structure is as follows:

The **onc** package contains the classes that offer most of the functionality provided by the **Onc**
class, separated in small, single-responsibility modules. Each file has been carefully commented.

The **util** package acts as a *namespace* for general-use functions that are consumed
by the classes in the **onc** package. This package exists as a strategy to reduce code
redundancy, considering MATLAB's particularities.

The **ext** package was created to contain code from *external* projects (i.e. found in FileExchange) or general use libraries that could be published separately.

The **tests** folder contains the test suites (they have their own README.md file).


## Publishing a new version

1. Make sure the code doesn't contain logging messages, output directories, temporal files, etc.
2. Double-click **onc.prj**, update version number and click **Package**
3. Rename the `.mltbx` file generated as: `onc-VERSION.mltbx`. (ex: `onc-2.1.0.mltbx`)
4. Delete the contents of the **"dist"** directory and place the toolkit file here
5. Delete the current onc toolkit installed (if any) and install the new toolkit
2. Run all test suites; all tests should pass


6. `git add .`
7. `git status` and review the file changes; double-check that no unintended files are uploaded
8. `git commit -m "your commit message"`
9. `git push`
10. Verify in the [Github project page](https://github.com/OceanNetworksCanada/api-matlab-client) that your commit was uploaded; you can optionally check your commit changes here.
