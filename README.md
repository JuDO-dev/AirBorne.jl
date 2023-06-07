# AirBorne
[![CI](https://github.com/JuDO-dev/AirBorne.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/JuDO-dev/AirBorne.jl/actions/workflows/CI.yml)

Welcome to the AirBorne a complete algorithmic trading framework for Julia. This package is currently under construction more documentation will be put forward soon.

# Developer Notes
This notes are meant for developers using the development environment provided in this repository.

##### How to import package 
Until package is released, the package can be locally imported by using 
```bash
develop "../AirBorne"
```

##### How to test connection to GitHub
```bash
ssh -T git@github.com
```


##### Best practices for merging

1. **Function docstrings**: Each function needs to be adequately documented, with inputs and outputs defined. On examples try using jldoctest language type instead of julia except for OS/circumstance specific examples.
1. **Object docstrings**: Each object needs to have a docstring explaining its function and what it represents
1. **Respect unit tests**: Unit tests are put for a reason, make sure all pass before merging into a shared development branch.
