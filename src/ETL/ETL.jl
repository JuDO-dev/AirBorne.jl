"""
    This modules centralizes all features for the data pipeline of AirBorne including API
    connections, cache management and data transformations as part of the data pipeline.
"""
module ETL

include("./YFinance/YFinance.jl")
include("./Cache/Cache.jl")

end