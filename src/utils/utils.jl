module Utils
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
end
