"""
    This modules centralizes caching for the AirBorne package. Containing:
    - Definition of data storage procedures
    - Definition of data storage formats
"""
module Cache
export hello_cache
# export get_cache_path
# import Base.Sys as Sys 
"""
    hello_cache()

Returns a string saying "Hello Cache!".
"""
function hello_cache()
    return "Hello Cache!"
end


"""
     get_cache_path()
    
Defines the cache path depending on the OS and environment variables.
```julia
julia> import AirBorne
julia> AirBorne.ETL.Cache.get_cache_path()
```
"""
function get_cache_path()
    cache_path=get(ENV,"AIRBORNE_ROOT",nothing)
    if !(isnothing(cache_path))
        return cache_path
    elseif (Sys.islinux()) ||  (Sys.isapple()) 
        return "/root/tmp/.AirBorne/.cache"
    elseif Sys.iswindows() 
        return "$(ENV["HOME"])/.AirBorne/.cache"
    end
end

```
Stores OHLCV in cache
```
end