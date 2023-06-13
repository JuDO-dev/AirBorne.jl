# Contribution Guidelines
This notes are meant for developers wanting to contribute to this project.

## Local environment for development

##### Best practices for merging
This guide of best practices are to help developers understand the code written, to ensure good documentation is available for end users and guarantee robustness of the code.

1. **Function docstrings**: Each function needs to be adequately documented, with inputs and outputs defined. On examples try using jldoctest language type instead of julia except for OS/circumstance specific examples.
1. **Module docstrings**: Each module needs to have a docstring explaining its function and what it represents
1. **Respect unit tests**: Unit tests are put for a reason, make sure all pass before merging into a shared development branch. The reason for the unit test should be indicated somewhere in the code.
1. **Respect style**: Havin a consistent writing style help the developers read the code and brings homogeneity to the contributions. To do this we adhere to te [Blue style](https://github.com/invenia/BlueStyle). 


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
make testJ
```

Then execute the following three commands in the newly open Julia console:
```julia
using Revise
# dev "../AirBorne" # In Pkg REPL
include("test/runtests.jl")

# To execute a single test just use the command below and replace 
# test_file by the name of the file containing the test you want to run.
# include("test/test_file.jl")
# include("test/backtest_A.jl")
```
1. `using Revise`
2. Open the Pkg REPL using `]` and type: `dev "../AirBorne"`
3. Go back using backspace and use `include("test/runtests.jl")`

Now anytime you want to test your code again type `include("test/runtests.jl")` (or just use the up arrow to select the last command that ran).


