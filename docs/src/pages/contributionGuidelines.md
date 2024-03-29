# Contribution Guidelines

>This notes are meant for developers wanting to contribute to this project. We follow the [ColPrac guide for collaborative practices](https://github.com/SciML/ColPrac). New contributors should make sure to read that guide as well as the best practices immediately below.

##### Best practices for merging
This guide of best practices are to help developers understand the code written, to ensure good documentation is available for end users and guarantee robustness of the code.

1. **Function docstrings**: Each function needs to be adequately documented, with inputs and outputs defined. On examples try using jldoctest language type instead of julia except for OS/circumstance specific examples.
1. **Module docstrings**: Each module needs to have a docstring explaining its function and what it represents
1. **Respect unit tests**: Unit tests are put for a reason, make sure all pass before merging into a shared development branch. The reason for the unit test should be indicated somewhere in the code.
1. **Respect style**: Havin a consistent writing style help the developers read the code and brings homogeneity to the contributions. To do this we adhere to te [Blue style](https://github.com/invenia/BlueStyle). 


## Branch Management

### Versioning
When this package is released it will have a version. Versioning is a standard practice in software development, but different approaches are available to define the versions of a package. Usually a package will have the version defined by 3 number which are *Major*,*Minor*, *Patch*. AirBorne 0.1.3 has Major version 0, Minor version 1 and Patch version 3. 

- **Patch**: The patch is incremented if a bug has been fix, but no additional feature has been added.
- **Minor**: The minor is incremented if a new feature, such as new function or submodule or even additional functionalities for existing functions are added. The new minor version needs to be compatible with all previous minor version of the same major version. Therefore if a unit test passes for a minor version it also needs to pass for any further minor version released, and is the responsibility of the newer minor version to comply with this, the sole exception is for undetected bugs, which needs to be corrected immediately in the minor version in which was detected.
- **Major**: A major version is incremented if the change in the software is so large that backwards compatibility is impossible. This is a worst case scenario and must be avoided at all costs, existing users of AirBorne will have their code crash, several issues are expected after a major release, it must be done strategically and for very well justified reasons.

#### Unit Test result
Each minor version of AirBorne will have at least 2 associated branches *"dev-Major.Minor.Patch"* and *"master-Major.Minor.Patch"*, merge requests on either of these branches need to pass, local development branches are to be merged *"dev-Major.Minor.Patch"* were limited localized unit-test may be carried out and once the patch is ready for release that branch is merged into *"master-Major.Minor.Patch"* any merge request into the master branch needs to pass a through run of unit tests.

#### Support
Each minor version needs to be adequately supported as it is to be considered a finished product available for the wider public to use.


### Archiving
Sometimes we want to keep a branch with some data, but at the same time we don't want to pollute the list of branches in the repository. A way to achieve this is through the usage of tags. The archived branches can be accessed later on by looking at the tags of the repository, following [GitHub instructions](https://docs.github.com/en/repositories/releasing-projects-on-github/viewing-your-repositorys-releases-and-tags).

```bash
# For example we may want to archive or restore the add-quandl branch when picking up the connection to the datasource Quandl. 
export BRANCH=add-quandl
# Tag branch (this will add it to the archive)
git tag archive/$BRANCH $BRANCH
# Push the tag to remote
git push origin archive/$BRANCH
# Deleate head of branch (this will remove it from the list)
git push origin --delete $BRANCH
# This will restore the branch
git checkout -b $BRANCH archive/$BRANCH
```

## Citation and credits

It is important to identify and credit the contributors of this project, in particular the ones that will act as a point of contact for external enquiries. To do this we put in place a **CITATION.cff** file that should follow the schema of [Github's citation guidelines](https://github.com/citation-file-format/citation-file-format/blob/main/schema-guide.md). 

## Local environment for development
This section is meant for new joiners or people new to software development. If you already know about local environments and have your own style to generate functional code, feel free to skip this section.

In this repository you can find a local environment in which the package is guaranteed to work, to do so we leverage docker containers.

### Setting up a local environment


##### How to import package 
Until package is released, the package can be locally imported by using 
```bash
develop "../AirBorne"
```

##### How to test connection to GitHub
For some operations connection to GitHub may be required, to test your SSH connection in the console use the command below: 
```bash
ssh -T git@github.com
```
##### How to perform unit tests efficiently
Unit testing when executed for the first time takes long, most of the time is taken in compilation. This formula will let you compile once and then execute tests rapidly.

First open a console in the testing environment.
```bash
make J
```

Then execute the following three commands in the newly open Julia console:
```julia
# Activate Test Environment & Dependencies
using TestEnv;TestEnv.activate(); using Revise

# Run all tests
include("test/runtests.jl")

# Run individual tests in a file.
# include("test/test_file.jl")
# include("test/backtest_A.jl")
# include("test/FM.jl")
```
1. `using Revise`
2. Open the Pkg REPL using `]` and type: `dev "../AirBorne"`
3. Go back using backspace and use `include("test/runtests.jl")`

Now anytime you want to test your code again type `include("test/runtests.jl")` (or just use the up arrow to select the last command that ran).


