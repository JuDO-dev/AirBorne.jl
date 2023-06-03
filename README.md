# Template for JuDO Packages

## Create GitHub Repository
1. Start by clicking the green **'Use this template'** button;
2. Name your repository with the `.jl` suffix, like `Pizza.jl`;
3. Decide on its visibility: `Public`/`Private`;
4. Leave **'Include all branches'** unticked;
5. Clone the repository to your machine* (e.g., inside `\Documents`).

## Generate Julia Package
1. Open Julia and create a package template by running:
```julia 
julia> using Pkg; Pkg.add("PkgTemplates");
julia> using PkgTemplates
julia> t = Template(
    user="JuDO-dev",
    dir=pwd(),
    julia=v"1.6",
    plugins=[
        !License,
        Git(branch="dev"),
        GitHubActions(linux=true, x64=true, x86=true, extra_versions=[v"1.7", "nightly"]),
        Codecov(),
        Documenter{GitHubActions}()])
```
2. Generate the package files by running:
```julia
julia> t("Pizza") # NB: without the ".jl" suffix
```

## Assemble Julia Package
1. Copy the contents of `Pizza` into `Pizza.jl`, overwritting `README.md`;
2. Commit changes and push to origin*.

*You may use [GitHub Desktop](https://desktop.github.com/).

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

1. **Function docstrings**: Each function needs to be adequately documented, with inputs and outputs defined,
2. **Object docstrings**: Each object needs to have a docstring explaining its function and what it represents
3. **Respect unit tests**: Unit tests are put for a reason, make sure all pass before merging into a shared development branch.
