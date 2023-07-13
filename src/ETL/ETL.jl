"""
    This modules centralizes all features for the data pipeline of AirBorne including API
    connections, cache management and data transformations as part of the data pipeline.
"""
module ETL
include("./Transform/Transform.jl") # Definition of structures and common transformations are here. This module must be included first.
include("./Transform/AssetValuation.jl")
include("./sources/NASDAQ.jl")
include("./sources/YFinance.jl")
include("./Cache/Cache.jl")
end
