module Utils
export hello_world
using Pipe: @pipe
using DataFrames: groupby, combine

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

# Important bug in Julia: https://github.com/JuliaLang/julia/issues/32727 prevents this function from compiling sometimes for documentation
# Is still a good function that we need to put forward at some point
# TODO: Implement function without "_" as a variable
# """
#     get_latest_N(df,id_symbols,sort_symbol,N)
#     Retrieves last N records from a dataframe, sortying by sort_symbol and grouping by id_symbols.
#     ```julia
#     get_latest_N(past_data,[:exchangeName,:symbol],:date,2)
#     ```
# """
# function get_latest_N(df, id_symbols, sort_symbol, N)
#     return @pipe combine(_) do sdf
#         sorted = sort(sdf, sort_symbol)
#         first(sorted, N)
#     end(groupby(_, id_symbols)(df))
# end

end
