"""
    This modules centralizes caching for the AirBorne package. Containing:
    - Definition of data storage procedures
    - Definition of data storage formats
"""
module Cache
using DataFrames: DataFrames
using Parquet2: Dataset, writefile, metadata
using Dates: Dates, DateTime
using Tables: schema
using ..Transform: getSchema

export hello_cache
export get_cache_path
export store_bundle
export load_bundle
export list_bundles

# TODO: 
# - Add method to list archive (Best practice will be to enable an optional keyword on list_bundle)
# - Add method to load archive (Best practice will be to enable an optional keyword on load_bundle) 

"""
    hello_cache()

Returns a string saying "Hello Cache!".
"""
function hello_cache()
    return "Hello Cache!"
end

"""
    gen_id()

    Generates an id based on the current UTC timestamp with format "yyyy_mm_dd_H_M_S_s"
"""
function gen_id()
    return Dates.format(Dates.now(Dates.UTC), "yyyy_mm_dd_H_M_S_s")
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
    cache_path = get(ENV, "AIRBORNE_ROOT", nothing)
    if !(isnothing(cache_path))
        return cache_path
        # COV_EXCL_START
    elseif (Sys.islinux()) || (Sys.isapple())
        return "/root/tmp/.AirBorne/.cache"
    elseif Sys.iswindows()
        return "$(ENV["HOME"])/.AirBorne/.cache"
    end
    # COV_EXCL_STOP
end

"""
    store_bundle(data::DataFrames.DataFrame; bundle_id::Union{Nothing, String}=nothing, archive::Bool=true, meta::Dict=Dict(), c_meta::Dict=Dict())
    
    Stores a dataframe in a bundle in parquet format.

    **Is very important that none of the columns are of type "Any"** as the storage for this column type is not defined.
"""
function store_bundle(
    data::DataFrames.DataFrame;
    bundle_id::Union{Nothing,String}=nothing,
    archive::Bool=true,
    meta::Dict=Dict(),
    c_meta::Dict=Dict(),
    cache_dir::Union{String,Nothing}=nothing,
)
    # Define directories
    cache_dir = cache_dir === nothing ? get_cache_path() : cache_dir
    bundle_id = !(isnothing(bundle_id)) ? bundle_id : gen_id()
    bundle_dir = joinpath(cache_dir, bundle_id)
    archive_dir = joinpath(bundle_dir, "archive")
    meta["schema"] = getSchema(schema(data)) # Add Schema to Metadata
    # Ensure directories exist
    if !(isdir(archive_dir))
        mkpath(archive_dir)
    end

    # Move current contents to archive
    contents = readdir(bundle_dir)
    files_to_archive = [c for c in contents if c != "archive"]
    for files_to_archive in files_to_archive
        if archive
            mv(
                joinpath(bundle_dir, files_to_archive),
                joinpath(archive_dir, files_to_archive),
            )
        else
            @info("Removing $(joinpath( bundle_dir,files_to_archive))")
            rm(joinpath(bundle_dir, files_to_archive))
        end
    end

    # Write file
    file_path = joinpath(bundle_dir, gen_id() * ".parq.snappy")

    @info("Storing $file_path")
    return writefile(
        file_path, data; compression_codec=:snappy, metadata=meta, column_metadata=c_meta
    )
end

"""
    load_bundle(bundle_id::String)

    Loads data from a cached bundle.
    
    # Returns
    DataFrames.DataFrame
"""
function load_bundle(bundle_id::String; cache_dir::Union{String,Nothing}=nothing)
    cache_dir = isnothing(cache_dir) ? get_cache_path() : cache_dir
    bundle_dir = joinpath(cache_dir, bundle_id)
    if !(isdir(bundle_dir))
        throw(ErrorException("Bundle does not exist."))
    end
    contents = readdir(bundle_dir)
    contents_to_read = [c for c in contents if c != "archive"]
    if size(contents_to_read)[1] != 1
        throw(
            ErrorException("$(size(contents_to_read)[1]) files found in bundle directory.")
        )
    end
    file_path = joinpath(bundle_dir, contents_to_read[1])
    ds = Dataset(file_path) # Create a dataset
    df = DataFrames.DataFrame(ds; copycols=false) # Load from dataframed
    return df
end

"""
    list_bundles()

    Returns the list of bundles available in the cached folder.
    
    In the future this function can be expanded to return information as timestamp, 
    format of data in bundle among relevant metadata.
"""
function list_bundles(; cache_dir::Union{String,Nothing}=nothing)
    cache_dir = cache_dir === nothing ? get_cache_path() : cache_dir
    return readdir(cache_dir; sort=false)
end

"""
    describe_bundles(;archive=false)

    Returns the list of dictionaries describing the files for each bundle. 
    It allows to retrieve information about the archived files like:
        - Status of the files (missing, corrupted, etc.)
        - Schema
        - Timestamp of storage
        - File name 
"""
function describe_bundles(; archive=false, cache_dir::Union{String,Nothing}=nothing)
    cp = cache_dir === nothing ? get_cache_path() : cache_dir
    bundles = readdir(cp; sort=false)
    l = []
    for b in bundles
        contents = readdir(joinpath(cp, b); sort=false)
        f = [c for c in contents if c != "archive"]
        filename = f[1]
        status = "OK"
        ds = Dataset(joinpath(cp, b, filename))
        m = metadata(ds)
        entry = Dict(
            "bundle" => b,
            "file" => filename,
            "schema" => get(m, "schema", "MISSING"),
            "storedDate" => DateTime(filename[1:21], "yyyy_mm_dd_H_M_S_s"),
            "is_archived" => false,
            "status" => status,
        )
        push!(l, entry)
        if archive
            archive_files = readdir(joinpath(cp, b, "archive"); sort=false)
            for filename in archive_files
                try
                    status = "OK"
                    ds = Dataset(joinpath(cp, b, "archive", filename))
                    m = metadata(ds)
                catch e
                    status = e.msg
                    m = Dict()
                end
                entry = Dict(
                    "bundle" => b,
                    "file" => filename,
                    "schema" => get(m, "schema", "MISSING"),
                    "storedDate" => DateTime(filename[1:21], "yyyy_mm_dd_H_M_S_s"),
                    "is_archived" => true,
                    "status" => status,
                )
                push!(l, entry)
            end
        end
    end

    return l
end

"""
    remove_bundle(bundle_id::String; just_archive::Bool=false)

    Removes bundle from cache. This is an irreversible operation. If just_archive is true it only flushes the archive folder.
"""
function remove_bundle(
    bundle_id::String; just_archive::Bool=false, cache_dir::Union{String,Nothing}=nothing
)
    # Define directories
    cache_dir = cache_dir === nothing ? get_cache_path() : cache_dir
    bundle_dir = joinpath(cache_dir, bundle_id)
    archive_dir = joinpath(bundle_dir, "archive")
    if (just_archive) && (isdir(archive_dir))
        rm(archive_dir; recursive=true)
    elseif !(just_archive) && (isdir(bundle_dir))
        rm(bundle_dir; recursive=true)
    end
end

end
