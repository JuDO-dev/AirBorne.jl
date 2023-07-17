# Example: Building Strategies for DEDS & Static Markets
In this page you will find examples on the creation of strategies.

### [Building a Simple Moving Average Strategy](https://github.com/JuDO-dev/AirBorne.jl/blob/markowitz/docs/example_notebooks/SMA_Example.ipynb).
This example will show you how to build a simple moving average strategy for a **Static Market** using the **Discrete Event Driven Simulation** (DEDS) egine as well as an introduction to the template provided by [AirBorne.jl](https://github.com/JuDO-dev/AirBorne.jl). 

The SMA strategy takes the average return over 2 time windows known as the short horizon and the long horizon. If the short horizon average is greater than the long horizon average then we assume that the asset is increasing in value and we tend to buy such asset, when the condition is no longer met all the shares of such asset are sold.

The full example can be found in the [AirBorne.jl](https://github.com/JuDO-dev/AirBorne.jl) repository in the form of a Jupyter Notebook following [this link](https://github.com/JuDO-dev/AirBorne.jl/blob/markowitz/docs/example_notebooks/SMA_Example.ipynb).


### [Building a Markowitz Strategy](https://github.com/JuDO-dev/AirBorne.jl/blob/markowitz/docs/example_notebooks/Markowitz_Example.ipynb).
This example will show you how to build a markotiz strategy for a **Static Market** using the **Discrete Event Driven Simulation** (DEDS) egine as well as an introduction to the template provided by [AirBorne.jl](https://github.com/JuDO-dev/AirBorne.jl). 

The Markowtiz strategy models the returns of each asset as random variables, with mean, variance and covariance, the objective in the Markowitz  strategy is that given a desired expected return to organize a portfolio with the minimum possible variance. 

The full example can be found in the [AirBorne.jl](https://github.com/JuDO-dev/AirBorne.jl) repository in the form of a Jupyter Notebook following [this link](https://github.com/JuDO-dev/AirBorne.jl/blob/markowitz/docs/example_notebooks/Markowitz_Example.ipynb).