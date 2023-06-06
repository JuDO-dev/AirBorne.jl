using AirBorne
using Test

@testset "AirBorne.jl" begin
    # Sanity check
    @test AirBorne.hello_world() == "Hello World!"
    @test AirBorne.ETL.YFinance.hello_yfinance() == "Hello YFinance!"
    @test AirBorne.ETL.Cache.hello_cache() == "Hello Cache!"

end

import Parquet2
import DataFrames
asset_dir=joinpath(@__DIR__,"assets")
@testset "AirBorne.ETL.Cache" begin
    # Sanity check

    # Test caching capabilities
    # 1. Load data
    temp_mem=deepcopy(get(ENV,"AIRBORNE_ROOT",nothing)) # Make a copy
    # deepcopy(AirBorne.ETL.Cache.get_cache_path())
    try
        bundle_id="test_bundle"
        ENV["AIRBORNE_ROOT"]=joinpath(@__DIR__,".test_cache123456789")
        cache_path=AirBorne.ETL.Cache.get_cache_path()
        if isdir(cache_path) # If Cache path clean it up
            rm(cache_path; recursive=true)
        end
        
        ds = Parquet2.Dataset(joinpath(asset_dir,"demo.parq.snappy")) # Create a dataset
        df = DataFrames.DataFrame(ds; copycols=false) # Load from dataframed
        AirBorne.ETL.Cache.store_bundle(df;bundle_id=bundle_id,archive=true) # Store
        @test size(AirBorne.ETL.Cache.list_bundles())[1]==1 # Test that the bundle can be found in the cache directory
        @test isequal(df, AirBorne.ETL.Cache.load_bundle(bundle_id)) # Test that loading the data does not affect the underlying data
        AirBorne.ETL.Cache.remove_bundle(bundle_id) # Delete Bundle
        @test size(AirBorne.ETL.Cache.list_bundles())[1]==0 # Test that bundle is gone
        rm(cache_path; recursive=true)
    catch e    
        # Code didn't run without errors, so a failure is due
        @test false
    finally
        ENV["AIRBORNE_ROOT"]=temp_mem
    end

end
