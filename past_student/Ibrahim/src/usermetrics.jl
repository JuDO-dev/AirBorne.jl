#Depndencies 
using CSV, DataFrames, XLSX, JSON, SQLite, LibPQ, HTTP, Dates

#Error Handling - external to improve reabability of code 

include("usermetrics_errorhandling.jl")
using .PortfolioErrorHandling

#Base Structure for assets

abstract type AbstractAsset end

struct BaseAsset <: AbstractAsset
    AssetType::String
    AssetID::String
    QuantityOwned::Float64 
    PurchasePrice::Float64
    Currency::String
    PurchaseDate::Date
    AdditionalDetails::Dict{String, Any}
end

struct Option <: AbstractAsset
    BaseAsset
    OptionType::String
    StrikePrice::Float64
    ExpiryDate::Date
end

#Note this is extendable as per documentation


#---------------------------------------------------

#Data Input Method 

abstract type InputMethod end

struct EmptyMethod <: InputMethod end
struct ManualMethod <: InputMethod end
struct CSVMethod <: InputMethod end
struct ExcelMethod <: InputMethod end
struct JSONMethod <: InputMethod end
struct SQLiteMethod <: InputMethod end
struct PostgreSQLMethod <: InputMethod end

#--------------------------------------------------------
#Empty Method 


function initial_portfolio_details(method::EmptyMethod)
    # Create an empty DataFrame to represent the portfolio
    assets = DataFrame(
        AssetType = String[],
        AssetID = String[],
        QuantityOwned = Float64[],
        PurchasePrice = Float64[],
        Currency = String[],
        PurchaseDate = Date[],
        AdditionalDetails = Dict{String, Any}[]
    )
    return assets
end


#------------------------------------------------
# Manual Method 


# Function to reshape wide-format DataFrame to long format
function wide_to_long(df::DataFrame)
    df_long = stack(df, Not(:AssetID))
    rename!(df_long, :variable => :AssetType, :value => :QuantityOwned)
    return df_long
end

# Function to reshape long-format DataFrame to wide format
function long_to_wide(df::DataFrame)
    df_wide = unstack(df, :AssetID, :AssetType, :QuantityOwned)
    return df_wide
end


function initial_portfolio_details(method::ManualMethod, input::Union{DataFrame, Dict}, orientation::Symbol=:wide)
    # Check input orientation
    allowed_orientations = (:wide, :long)
    if !(orientation in allowed_orientations)
        PortfolioErrorHandling.raise_invalid_input_error("Invalid input orientation. Allowed orientations are: $(join(allowed_orientations, ", "))")
    end

    # Convert dictionary input to DataFrame
    if typeof(input) == Dict
        input = DataFrame(input)
    end

    # If the input is in wide format, reshape it to long format
    if orientation == :wide
        input = wide_to_long(input)
    end

    # Validate required columns
    required_columns = [:AssetType, :AssetID, :QuantityOwned, :PurchasePrice, :Currency, :PurchaseDate]
    PortfolioErrorHandling.validate_required_columns(input, required_columns)

    # Validate data types
    column_types = Dict(
        :QuantityOwned => Float64,
        :PurchasePrice => Float64,
        :Currency => String,
        :PurchaseDate => Date
    )
    PortfolioErrorHandling.validate_data_types(input, column_types)

    # Initialize an empty DataFrame to store the assets
    assets = DataFrame(AssetType = String[], AssetID = String[], QuantityOwned = Float64[], PurchasePrice = Float64[], 
                       Currency = String[], PurchaseDate = Date[], AdditionalDetails = Dict{String, Any}[])

    for row in eachrow(input)
        asset = Dict()

        asset["AssetType"] = row[:AssetType]
        asset["AssetID"] = row[:AssetID]
        asset["QuantityOwned"] = parse(Float64, row[:QuantityOwned])
        asset["PurchasePrice"] = parse(Float64, row[:PurchasePrice])
        asset["Currency"] = row[:Currency]
        asset["PurchaseDate"] = Date(row[:PurchaseDate], "yyyy-mm-dd")

        # Handle additional details
        if haskey(row, "AdditionalDetails")
            if typeof(row[:AdditionalDetails]) != Dict{String, Any}
                error("AdditionalDetails must be a dictionary")
            else
                asset["AdditionalDetails"] = row[:AdditionalDetails]
            end
        else
            asset["AdditionalDetails"] = Dict()
        end

        push!(assets, asset)
    end

    return assets
end

# if the input is already in the long format (orientation == :long), the function will skip the wide_to_long conversion and proceed with the processing.


#--------------------------------------------------------

#Input Parsing Structs

abstract type InputParsing end

struct CSVParsing <: InputParsing end
struct ExcelParsing <: InputParsing end
struct JSONParsing <: InputParsing end
struct SQLiteParsing <: InputParsing end
struct PostgreSQLParsing <: InputParsing end

#-----------------------------------------------------------------------
# Parsing Functions

using FilePathsBase: exists

function parse_input(input::AbstractString, method::CSVParsing, delimiter::AbstractChar)
    # Check if the file exists
    if !isfile(input)
        PortfolioErrorHandling.raise_invalid_input_error("File not found: $(input)")
    end

    # Try to read the file
    df = DataFrames.DataFrame()
    try
        df = CSV.File(input, header=true, delim=delimiter) |> DataFrame
    catch error
        # If reading fails, raise a detailed error message
        PortfolioErrorHandling.raise_invalid_input_error("Error occurred while parsing the CSV file: $(error)")
    end

    # Convert String7 columns to String, preserving missing values
    for col in names(df)
        if eltype(df[!, col]) <: Union{Missing, String7}
            df[!, col] = [ismissing(x) ? missing : String(x) for x in df[!, col]]
        end
    end

    return df
end


function parse_input(input::AbstractString, method::ExcelParsing, sheet_name::AbstractString)
    # Check if the file exists
    if !isfile(input)
        PortfolioErrorHandling.raise_invalid_input_error("File not found: $(input)")
    end

    df = DataFrame()

    try
        df = DataFrame(XLSX.readtable(input, sheet_name)...)
    catch error
        # If reading fails, raise a detailed error message
        PortfolioErrorHandling.raise_invalid_input_error("Error occurred while parsing the Excel file: $(error)")
    end

    # Convert any missing data in df to missing value
    for col in names(df)
        if eltype(df[!, col]) <: Union{Missing, String}
            df[!, col] = [ismissing(x) ? missing : x for x in df[!, col]]
        end
    end

    return df
end







function parse_input(input::AbstractString, method::JSONParsing)
    try
        df = JSON.File(input) |> DataFrame
    catch error
        PortfolioErrorHandling.raise_invalid_input_error("Error occurred while parsing the JSON file: $(error)")
    end
    return df
end

function parse_input(input::AbstractString, method::SQLiteParsing, table_name::AbstractString)
    try
        db = SQLite.DB(input)
        query = "SELECT * FROM $table_name"
        df = SQLite.Query(db, query) |> DataFrame
        SQLite.close(db)
    catch error
        PortfolioErrorHandling.raise_invalid_input_error("Error occurred while querying the SQLite database: $(error)")
    end
    return df
end

function parse_input(connection_string::AbstractString, method::PostgreSQLParsing, table_name::AbstractString)
    try
        db = LibPQ.Connection(connection_string)
        query = "SELECT * FROM $table_name"
        result = LibPQ.execute(db, query)
        columns = LibPQ.columnnames(result)
        rows = LibPQ.rows(result)
        df = DataFrame(columns, rows)
        LibPQ.finish(db)
    catch error
        PortfolioErrorHandling.raise_invalid_input_error("Error occurred while querying the PostgreSQL database: $(error)")
    end
    return df
end


#--------------------------------------------------------------------------------------------------------------------------------------
# Unified Method

function initial_portfolio_details(parsing::InputParsing, input::AbstractString, args...; kwargs...)
    return initial_portfolio_details(ManualMethod(), parse_input(input, parsing, args...; kwargs...), args...; kwargs...)
end


#---------------------------------------------------------------------------------------------------------------------------------


#Framework for conmstraints

# A single portfolio constraint
struct PortfolioConstraint
    description::String
    condition::Function
end

# A set of portfolio constraints
struct PortfolioConstraints
    constraints::Vector{PortfolioConstraint}
end

# Function to add a new constraint to a set of constraints
function add_constraint(constraints::PortfolioConstraints, description::String, condition::Function)
    push!(constraints.constraints, PortfolioConstraint(description, condition))
end

# Function to check if a portfolio satisfies all constraints
function check_portfolio(constraints::PortfolioConstraints, portfolio)
    return all(constraint.condition(portfolio) for constraint in constraints.constraints)
end


#Add Strength attribute 

#Check if constraints contradict should be done in the optimizer block