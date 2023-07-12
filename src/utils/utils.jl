module Utils
export hello_world
using Pipe: @pipe
using DataFrames: DataFrame, groupby, combine, missing

"""
    hello_world()

    Returns a string saying "Hello World!".
    """
function hello_world()
    return "Hello World!"
end

"""
    sortedStructInsert!(v::Vector, x,symbol;rev=true) 

    Inserts a struct into a **sorted** Vector of structs in the right place to keep the array sorted.
    """
function sortedStructInsert!(v::Vector, x, symbol; rev=true)
    return (splice!(v, searchsorted(v, x; by=v -> getproperty(v, symbol), rev=rev), [x]); v)
end

"""
    sortStruct!(v::Vector, symbol;rev=true) 

    Sorts a struct by a given symbol.
    """
function sortStruct!(v::Vector, symbol; rev=true)
    return sort!(v; by=v -> getproperty(v, symbol), rev=rev)
end

"""
    deepPush!(list,element)

    Inserts the deepcopy of an element into a collection 
    """
function deepPush!(list, element)
    return push!(list, deepcopy(element))
end

"""
    get_latest(df,id_symbols,sort_symbol)

    Retrieves last record from a dataframe, sortying by sort_symbol and grouping by id_symbols.

    ```julia
    get_latest(past_data,[:exchangeName,:symbol],:date)
    ```
"""
function get_latest(df, id_symbols, sort_symbol)
    return combine(groupby(df, id_symbols)) do sdf
        sdf[argmax(sdf[!, sort_symbol]), :]
    end
end

"""
    lagFill(df::DataFrame,col::Symbol; respect_nothing::Bool=false)

    Replaces all missing values in a column of a dataframe for the previous 
    non-missing value.
"""
function lagFill(df::DataFrame, col::Symbol; respect_nothing::Bool=false)
    filledArray = df[!, col]
    for i in 2:length(filledArray)
        if (filledArray[i] === missing) || (respect_nothing && filledArray[i] === nothing)
            filledArray[i] = filledArray[i - 1]
        end
    end
    return filledArray
end

"""
    Given a function (mean, variance, sharpe,...) from an 1-D array to a single element
    It creates an array with same size of original with the function applied from the 
    beginning of the array to the index of the output. 

    !!! Tip "Performance"
        This function is not meant to be highly performant. If a function is used function is
        advised to have a specialized function to calculate its running counterpart.

    # Optional Arguments
    - `windowSize::Union{Int,Nothing}`: If its desired to truncate the number of past elements to be considered, this field can be set to the maximum number of past elements to take into account. This can be used for Moving Averages for example. 
    - `ignoreFirst::Int`: Indicates for how many elements the operation should not be applied. In those elements "nothing" will be placed instead.
"""
function makeRunning(
    array::Vector, fun::Function; windowSize::Union{Int64,Nothing}=nothing, startFrom::Int=1
)
    out = Array{Union{Float64,Nothing}}(undef, length(array)) # Preallocate memory
    start(i) = windowSize === nothing ? startFrom : max(i - windowSize, startFrom)
    for i in startFrom:length(array)
        # @info "$(start(i)) - $i :" array[start(i):i] # Uncomment to see input of function.
        out[i] = fun(array[start(i):i])
    end
    return out
end

"""
    More efficient implementation of a moving average (mean running).
"""
function movingAverage(
    array::Vector; windowSize::Union{Int,Nothing}=nothing, startFrom::Int=1
)
    out = Array{Union{Float64,Nothing}}(undef, length(array)) # Preallocate memory
    start(i) = windowSize === nothing ? 1 : max(i - windowSize, 1)
    function factor(i)
        return if windowSize === nothing
            i + 1 - startFrom
        else
            min(windowSize, i + 1 - startFrom)
        end
    end
    sum_value = 0
    for i in startFrom:length(array)
        sum_value += array[i]
        sum_value -= i + 1 - startFrom > windowSize ? array[start(i)] : 0
        out[i] = sum_value / factor(i)
    end
    return out
end

end
