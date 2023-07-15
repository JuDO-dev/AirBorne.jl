#------------------------------------------
# Optimization Block

# Load Necessary Libraries
using DataFrames, StatsBase, LinearAlgebra, JuMP, Optim

# Required Data & Modules
# Load DataProcessing and UserMetrics modules here

#------------------------------------------
# Data Gathering and Processing

# Using DataProcessing module functions, gather necessary data on securities being traded 
# and store them in a DataFrame.

securities_data = DataProcessing.get_data(securities)

#------------------------------------------
# Time Series Prediction Using Least Squares and Hankel Matrix

# Define the prediction function which uses least squares and Hankel matrix to forecast the time series.

function predict_time_series(securities_data::DataFrame, num_forecast_periods::Int)
    # Add code here to perform least squares prediction using a Hankel matrix.
    # This function should return a DataFrame or Matrix containing the forecasted time series data.
end

# Call the prediction function to get the forecasted time series data.

forecasted_data = predict_time_series(securities_data, num_forecast_periods)

#------------------------------------------
# Optimization Problem Definition

using JuMP

# Define a struct for the optimization problem
mutable struct DeePCOptimizationProblem
    model::Model
    g::Array{VariableRef}
end

# Function to construct a DeePC optimization problem
#=function construct_portfolio_deePC_problem(u_ini::Array{Float64}, y_ini::Array{Float64}, Q::Array{Float64}, R::Array{Float64}, L::Int, T::Int)

    # Construct the Hankel matrices
    H_u = construct_hankel_matrix(u_ini, L)
    H_y = construct_hankel_matrix(y_ini, L)

    # Dimensions
    n = size(H_u, 1)   # Number of states
    m = size(H_u, 2)   # Number of inputs

    # Define the matrices for the optimization problem
    U_p = H_u[1:end-1, :]
    Y_p = H_y[1:end-1, :]
    U_f = H_u[2:end, :]
    Y_f = H_y[2:end, :]

    # Define the JuMP model (without specifying the solver)
    model = Model()

    # Decision variable
    g = @variable(model, [1:n])

    # Objective function
    @NLobjective(model, Min, -sum(Q[k]*(Y_f[k,:]*g) - R[k]*(U_f[k,:]*g)^2 for k in 1:T))

    # Constraints
    @constraint(model, [i=1:n], U_p*g == u_ini[i])
    @constraint(model, [i=1:n], Y_p*g == y_ini[i])

    # Additional constraint: The weights of the portfolio should sum up to 1
    @constraint(model, sum(g) == 1)

    # Return the optimization problem
    return DeePCOptimizationProblem(model, g)
end=#

function construct_portfolio_deePC_problem(constraints::PortfolioConstraints, U_p::Matrix, Y_p::Matrix, u_ini::Vector, y_ini::Vector, U_f::Matrix, Y_f::Matrix, Q::Vector, R::Vector, r::Vector)
    
    N = size(U_f, 1)  # Time horizon
    g = Variable(size(U_p, 2))  # Decision variable
    
    # Objective function
    objective = sumsquares(Y_f*g - r)*diagm(Q) + sumsquares(U_f*g)*diagm(R)
    
    # Equality constraints
    equality_constraints = [U_p*g == u_ini, Y_p*g == y_ini]
    
    # User-defined constraints
    user_constraints = [constraint.condition(g) for constraint in constraints.constraints]
    
    problem = minimize(objective, [equality_constraints; user_constraints])
    
    return problem
end



#=using JuMP
using GLPK

# Define a simple portfolio with 3 securities
num_securities = 3

# Assume some expected returns for each security
expected_returns = [0.1, 0.2, 0.15]

# Assume some covariance matrix for the returns
covariances = [0.005 -0.010 0.004; -0.010 0.040 -0.002; 0.004 -0.002 0.023]

# Define the mean-variance optimization model
model = Model(GLPK.Optimizer)

@variable(model, x[1:num_securities] >= 0)
@objective(model, Min, dot(x, covariances * x) - dot(expected_returns, x))

@constraint(model, sum(x) == 1)

# Solve the optimization problem
optimize!(model)

# Get the optimized portfolio
optimized_portfolio = value.(x)

println("Optimized portfolio: ", optimized_portfolio)
=#