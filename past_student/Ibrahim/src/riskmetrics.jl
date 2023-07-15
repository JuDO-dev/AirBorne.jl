using DataFrames, Dates, Plots, StatsBase, Distributions, Random, DataFramesMeta

Random.seed!(123)  # for reproducibility

# Define stock prices and trades
prices = repeat([100.0, 110.0, 95.0, 120.0, 130.0, 140.0, 105.0, 115.0, 125.0, 135.0, 145.0, 155.0], 2)
stocks = repeat(["stock1", "stock1", "stock2", "stock2", "stock3", "stock3", "stock1", "stock1", "stock2", "stock2", "stock3", "stock3"], 2)
times = Date(2023,1,1):Month(1):Date(2024,12,1)

# Create DataFrame for trade_history
trade_history = DataFrame(time = times, stock = stocks, price = prices)

# Calculate returns
trade_history[:, :return] = @transform(trade_history, return == :price ./ lag(:price) .- 1).return

# Clean up missing return from first row
trade_history = trade_history[2:end, :]

# Create DataFrame to hold your stats
portfolio_stats = DataFrame(time = unique(trade_history.time), 
                            skew = Float64[], 
                            kurtosis = Float64[], 
                            variance = Float64[], 
                            sharpe_ratio = Float64[])

# Loop through the unique time points
for (i, t) in enumerate(portfolio_stats.time)
    # Select the data up to the current time point
    current_data = trade_history[trade_history.time .<= t, :]
    
    # Calculate stats
    portfolio_stats[i, :skew] = skewness(skipmissing(current_data[:, :return]))
    portfolio_stats[i, :kurtosis] = kurtosis(skipmissing(current_data[:, :return]))
    portfolio_stats[i, :variance] = var(skipmissing(current_data[:, :return]))
    
    # Assume risk-free rate is 0 for simplicity
    portfolio_stats[i, :sharpe_ratio] = mean(skipmissing(current_data[:, :return])) / std(skipmissing(current_data[:, :return]))
end

# Plot the statistics over time
plot(portfolio_stats.time, [portfolio_stats.skew, portfolio_stats.kurtosis, portfolio_stats.variance, portfolio_stats.sharpe_ratio],
     label = ["Skewness" "Kurtosis" "Variance" "Sharpe Ratio"], 
     title = "Portfolio Statistics Over Time")
