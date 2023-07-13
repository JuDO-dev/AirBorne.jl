# Example: Building a Simple Moving Average Strategy



The moving average of the close price at any point in time can be calculated by picking the last N entries of data for each ticker and calculating the mean of the sequence. 
```julia
# Define parameters for SMA
shortH=context.extra.short_horizon
longH=context.extra.short_horizon

# Define functions to calculate the most recent moving averages
shortSMA(sdf_col) = mean(last(sdf_col, context.extra.short_horizon)) # Calculate short horizon from a single column
longSMA(sdf_col) = mean(last(sdf_col, context.extra.long_horizon))

function shortSMA_2(sdf) # Calculates short horizon from the subdataframe
    # The advantage of the subdataframe function is that it enables more complex behaviour as 
    # sorting the subdataframe prior to moving average.
    sorted = sort(sdf, :date) 
    return mean(last(sorted, shortH).close) # Make mean of first shortH results
end

# Calculate the moving averages for the data
sma_df=combine(groupby(data, ["symbol","exchangeName"]),
 :close=>shortSMA=>:SMA_S,
 shortSMA_2,
 :close=>longSMA=>:SMA_L )
```

!!! tip "Tip: Preprocess your data"
    All algorithms work faster if you know the shape your data has. Ideally you can save computational time of sorting by pre-sorting your source data by time.