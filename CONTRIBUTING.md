# Contributing

This project is maintained by Ocean Network Canada's Data Team and is made public to facilitate and promote ONC Data usage through the Oceans 2.0 API. Pull requests from external users are valuable and should be considered; however, note that we try to maintain the Python, MATLAB and R client libraries as consistent with each other as possible, thus new features will require modifications to all of them.


## Overview

The full code base is kept in a [GitHub public repository](https://github.com/OceanNetworksCanada/api-matlab-client) as an open-source project. A MATLAB toolkit is generated from this project, and manually published to a [MATLAB Central entry](https://www.mathworks.com/matlabcentral/fileexchange/74008-ocean-networks-canada-api-client).

Although MATLAB File Exchange allows Github integration, it is not used because MATLAB will add undesired extra steps to the installation procedure due to licensing issues, which might be perceived negatively by some users.

The directory structure is as follows:

The **onc** package contains the classes that offer most of the functionality provided by the **Onc**
class, separated in small, single-responsibility modules. Each file has been carefully commented.

The **util** package acts as a *namespace* for general-use functions that are consumed
by the classes in the **onc** package. This package exists as a strategy to reduce code
redundancy, considering MATLAB's particularities.

The **ext** package was created to contain code from *external* projects (i.e. found in FileExchange) or general use libraries that could be published separately.

The **tests** folder contains the test suites (they have their own README.md file).


## Codebase design rationale

The Onc class has been engineered not as a MATLAB script or collection of functions, but as
a software product with an active maintenance cycle.

The Object-Oriented paradigm that directs the codebase increases modularity & cohesion, and reduces coupling between code components. Following software engineering practices facilitates extending and maintaining the code in the future, as long as the maintainers are familiar with [MATLAB's Object Oriented Capabilities](https://www.mathworks.com/discovery/object-oriented-programming.html). The advantages of Object Oriented Design over monolithic, procedural "spaghetti" code are well-known, specially in projects with multiple maintainers.


## Versioning

Version numbers have 3 parts: MAJOR.MINOR.REVISION (i.e. 2.1.0). When versioning, follow this criteria:

- **MAJOR** means a project-level revision that will potentially break existing code
- **MINOR** means a new feature was added, but old code still works without change (or minimal changes in exceptional cases that don't fit as a MAJOR version change). Most users should be able to upgrade with no consecuence.
- **REVISION** means a bugfix, refactorization, documentation change, etc. that does not add new features or break code. Users should be able to upgrade with no consecuence.


## Publishing a new toolkit version

### Creating the toolkit

1. Make sure the code doesn't contain logging messages, output directories, temporal files, etc.
2. Double-click **onc.prj**
3. Update version number and click **Package**
3. Rename the `.mltbx` file generated as: `onc-VERSION.mltbx`. (ex: `onc-2.1.0.mltbx`)
4. Delete the contents of the **"dist"** directory and place the toolkit file here
5. Delete the current onc toolkit installed (if any) and install the new toolkit
6. Run all test suites; all tests should pass

## Upload to Git

1. `git add .`
2. `git status` and review the file changes; double-check that no unintended files are uploaded
3. `git commit -m "your commit message"`
4. `git push`
5. Verify in the [Github project page](https://github.com/OceanNetworksCanada/api-matlab-client) that your commit was uploaded; you can optionally check your commit changes here.

## Upload to MATLAB Central

1. Access the [File Exchange Entry](https://www.mathworks.com/matlabcentral/fileexchange/74008-ocean-networks-canada-api-client)
2. Click "New Version"
3. Click "Change File" and select the new file
4. Update the Version number in the form
5. Write what changed in the update notes (this will go public and can't be modified)
6. Publish