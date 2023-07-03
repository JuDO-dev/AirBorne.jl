using Test
using AirBorne: AirBorne
using AirBorne.ETL.Transform: addSchema, getSchema
using AirBorne.ETL.Cache: get_cache_path, store_bundle, describe_bundles, list_bundles, remove_bundle, load_bundle


@testset "AirBorne.ETL Cache & Transform" begin
    # Sanity check
    using Tables: Schema
    using Parquet2: Dataset
    using DataFrames: DataFrames
    using Dates: Dates
    
    # Try adding a new format to the schemas
    specs2 = [
        :exchangeName;  String;;
        :timezone;      String;;
        :currency;      String;;
        :symbol;        String;;
        :close;         Float64;;
        :high;          Float64;;
        :low;           Float64;;
        :open;          Float64;;
        :volume;        Int64;;
        :date;          Dates.DateTime;;
        :unix;          Int64;;
        ]
    sch2 = Schema(specs2[1,:],specs2[2,:])
    if getSchema("OHLCV_V2") != nothing
        delete!(schemas,"OHLCV_V2")
    end
    addSchema("OHLCV_V2",sch2)
    @test getSchema("OHLCV_V2") == sch2
    @test getSchema(sch2) == "OHLCV_V2" 

    asset_dir = joinpath(@__DIR__, "assets")
    # Test caching capabilities
    # 1. Load data
    temp_mem = deepcopy(get(ENV, "AIRBORNE_ROOT", nothing)) # Make a copy
    try
        bundle_id = "test_bundle"
        ENV["AIRBORNE_ROOT"] = joinpath(@__DIR__, ".test_cache123456789")
        cache_path = get_cache_path()
        if isdir(cache_path) # If Cache path clean it up
            rm(cache_path; recursive=true)
        end
        file_path = joinpath(asset_dir, "demo.parq.snappy")
        ds = Dataset(file_path) # Create a dataset
        df = DataFrames.DataFrame(ds; copycols=false) # Load from dataframed
        store_bundle(df; bundle_id=bundle_id, archive=true) # Store
        sleep(0.002) # Wait 2 milliseconds
        store_bundle(df; bundle_id=bundle_id, archive=true) # Store (and increase the archive)
        sleep(0.002) # Wait 2 milliseconds
        store_bundle(df; bundle_id=bundle_id, archive=false) # Store (replace live file)
        
        @test length(describe_bundles(archive=true))>1
        @test size(list_bundles())[1] == 1 # Test that the bundle can be found in the cache directory
        @test isequal(df, load_bundle(bundle_id)) # Test that loading the data does not affect the underlying data
        remove_bundle(bundle_id; just_archive=true) # Delete Archive
        remove_bundle(bundle_id) # Delete Bundle
        @test size(list_bundles())[1] == 0 # Test that bundle is gone

        @test_throws ErrorException load_bundle(bundle_id) # Verify an exception will be thrown

        manual_bundle = "test2"
        mkpath(joinpath(cache_path, manual_bundle))

        cp(file_path, joinpath(cache_path, manual_bundle, "demoA.parq.snappy"))
        cp(file_path, joinpath(cache_path, manual_bundle, "demoB.parq.snappy"))
        @test_throws ErrorException load_bundle(manual_bundle) # Verify an exception will be thrown
        rm(cache_path; recursive=true)

    catch e
        # Code didn't run without errors, so a failure is due
        @test false
    finally
        ENV["AIRBORNE_ROOT"] = temp_mem
    end
end
