module PortfolioErrorHandling

using CSV, DataFrames, XLSX, JSON, SQLite, LibPQ, HTTP,Dates

export raise_invalid_input_error
export validate_required_columns
export validate_data_types

# Raise an error when the input is invalid
function raise_invalid_input_error(message::AbstractString)
    throw(ArgumentError(message))
end

# Validate the required columns in the DataFrame
function validate_required_columns(df::DataFrame, required_columns::Vector{Symbol})
    for column in required_columns
        if !(column in names(df))
            raise_invalid_input_error("The DataFrame does not have a required column: $column")
        end
    end
end

# Validate the data types of the columns in the DataFrame
function validate_data_types(df::DataFrame, column_types::Dict{Symbol, DataType})
    for (column, column_type) in column_types
        if !(column in names(df))
            continue
        end
        if !(typeof(df[1, column]) <: column_type)
            raise_invalid_input_error("The column $column does not have the required data type: $column_type")
        end
    end
end

end  # module PortfolioErrorHandling