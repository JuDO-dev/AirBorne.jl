#need to change to your own directory to run the tests 
include("C:\\Users\\Alexander scos\\Documents\\Airborne.jl\\src\\Airborne.jl")
using Test
using .AirBorne

include("test_Data.jl")
include("test_Errors.jl")
include("test_Simple.jl")
include("test_Behavioural.jl")
