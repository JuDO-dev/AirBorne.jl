using Test
using AirBorne: AirBorne
@testset "AirBorne.ETL.Cache" begin
        # Sanity check

        using Parquet2: Parquet2
        using DataFrames: DataFrames
        asset_dir = joinpath(@__DIR__, "assets")
        # Test caching capabilities
        # 1. Load data
        temp_mem = deepcopy(get(ENV, "AIRBORNE_ROOT", nothing)) # Make a copy
        try
            bundle_id = "test_bundle"
            ENV["AIRBORNE_ROOT"] = joinpath(@__DIR__, ".test_cache123456789")
            cache_path = AirBorne.ETL.Cache.get_cache_path()
            if isdir(cache_path) # If Cache path clean it up
                rm(cache_path; recursive=true)
            end
            file_path = joinpath(asset_dir, "demo.parq.snappy")
            ds = Parquet2.Dataset(file_path) # Create a dataset
            df = DataFrames.DataFrame(ds; copycols=false) # Load from dataframed
            AirBorne.ETL.Cache.store_bundle(df; bundle_id=bundle_id, archive=true) # Store
            sleep(0.002) # Wait 2 milliseconds
            AirBorne.ETL.Cache.store_bundle(df; bundle_id=bundle_id, archive=true) # Store (and increase the archive)
            sleep(0.002) # Wait 2 milliseconds
            AirBorne.ETL.Cache.store_bundle(df; bundle_id=bundle_id, archive=false) # Store (replace live file)
            @test size(AirBorne.ETL.Cache.list_bundles())[1] == 1 # Test that the bundle can be found in the cache directory
            @test isequal(df, AirBorne.ETL.Cache.load_bundle(bundle_id)) # Test that loading the data does not affect the underlying data
            AirBorne.ETL.Cache.remove_bundle(bundle_id; just_archive=true) # Delete Archive
            AirBorne.ETL.Cache.remove_bundle(bundle_id) # Delete Bundle
            @test size(AirBorne.ETL.Cache.list_bundles())[1] == 0 # Test that bundle is gone

            @test_throws ErrorException AirBorne.ETL.Cache.load_bundle(bundle_id) # Verify an exception will be thrown

            manual_bundle = "test2"
            mkpath(joinpath(cache_path, manual_bundle))

            cp(file_path, joinpath(cache_path, manual_bundle, "demoA.parq.snappy"))
            cp(file_path, joinpath(cache_path, manual_bundle, "demoB.parq.snappy"))
            @test_throws ErrorException AirBorne.ETL.Cache.load_bundle(manual_bundle) # Verify an exception will be thrown

            rm(cache_path; recursive=true)
        catch e
            # Code didn't run without errors, so a failure is due
            @test false
        finally
            ENV["AIRBORNE_ROOT"] = temp_mem
        end
    end