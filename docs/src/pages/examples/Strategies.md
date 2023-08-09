# Example: Building Strategies for DEDS & Static Markets
In this page you will find examples on the creation of strategies.

### [Building a Simple Moving Average Strategy](https://github.com/JuDO-dev/AirBorne.jl/blob/dev/docs/example_notebooks/SMA_Example.ipynb).
This example will show you how to build a simple moving average strategy for a **Static Market** using the **Discrete Event Driven Simulation** (DEDS) engine as well as an introduction to the template provided by [AirBorne.jl](https://github.com/JuDO-dev/AirBorne.jl). 

The SMA strategy takes the average return over 2 time windows known as the short horizon and the long horizon. If the short horizon average is greater than the long horizon average then we assume that the asset is increasing in value and we tend to buy such asset, when the condition is no longer met all the shares of such asset are sold.

The full example can be found in the [AirBorne.jl](https://github.com/JuDO-dev/AirBorne.jl) repository in the form of a Jupyter Notebook following [this link](https://github.com/JuDO-dev/AirBorne.jl/blob/dev/docs/example_notebooks/SMA_Example.ipynb).


### [Building a Markowitz Strategy](https://github.com/JuDO-dev/AirBorne.jl/blob/dev/docs/example_notebooks/Markowitz_Example.ipynb).
This example will show you how to build a markotiz strategy for a **Static Market** using the **Discrete Event Driven Simulation** (DEDS) engine as well as an introduction to the template provided by [AirBorne.jl](https://github.com/JuDO-dev/AirBorne.jl). 

The Markowtiz strategy models the returns of each asset as random variables, with mean, variance and covariance, the objective in the Markowitz strategy is that given a desired expected return to organize a portfolio with the minimum possible variance. 

The full example can be found in the [AirBorne.jl](https://github.com/JuDO-dev/AirBorne.jl) repository in the form of a Jupyter Notebook following [this link](https://github.com/JuDO-dev/AirBorne.jl/blob/dev/docs/example_notebooks/Markowitz_Example.ipynb).


### [Building a Mean Variance MPC  Strategy](https://github.com/JuDO-dev/AirBorne.jl/blob/mpc/docs/example_notebooks/MPC_Example.ipynb).
This example will show you how to build a Model Predictive Control strategy following the MeanVariance framework for a **Static Market** using the **Discrete Event Driven Simulation** (DEDS) engine as well as an introduction to the template provided by [AirBorne.jl](https://github.com/JuDO-dev/AirBorne.jl). 

The MeanVariance MPC strategy models uses predictions of the expected returns and covariance matrices of the assets in the market within a horizon to establish the sequence of portfolio structures over time that maximizes expected returns whilst minimizing the overall variance. Is similar to the Markowitz strategy, but instead of simply looking at the past data to infer a static picture of the first and second moments of the returns distributions it leverages future predictions for them.

The full example can be found in the [AirBorne.jl](https://github.com/JuDO-dev/AirBorne.jl) repository in the form of a Jupyter Notebook following [this link](https://github.com/JuDO-dev/AirBorne.jl/blob/mpc/docs/example_notebooks/MPC_Example.ipynb).

**Bonus material on forecasting:** A second notebook is also available were examples for different forecasting techniques compatible withe the Mean Variance MPC strategy can be found, including Hidden Markov Models, Linear Regression and Behavioural Models. See **["MPC Additional Resources: Forecasting"](https://github.com/JuDO-dev/AirBorne.jl/blob/dev/docs/example_notebooks/MPC_Example_Forecasts.ipynb)**.