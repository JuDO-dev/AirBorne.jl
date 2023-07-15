# expected results user metrics tests
using CSV, DataFrames, XLSX, JSON, SQLite, LibPQ, HTTP, Dates

function get_expected_result()
    return Dict(
        "small_csv" => DataFrame(
            AssetID = ["AAPL", "MSFT", "GOOG", "BTC"],
            AssetType = ["Stock", "Stock", "Stock", "CRYPTO"],
            Volume = [123456, 234567, 345678, 50000],
            Price = [145.67, 208.56, 2762.32, 35000],
            Exchange = ["NASDAQ", "NASDAQ", "NASDAQ", "BINANCE"]
        ),

        "empty_csv" => DataFrame(),

        "single_row_csv" =>  DataFrame(
            AssetID = ["AAPL"],
            Type = ["Stock"],
            Volume = [1000],
            Value = [150000]
        ),
        
        "missing_values_csv" => DataFrame(
            AssetID = Union{String, Missing}["AAPL", "GOOG", "MSFT", missing],
            Type = Union{String, Missing}["Stock", "Stock", "Stock", "ETF"],
            Volume = Union{Int, Missing}[1000, missing, 1200, 600],
            Value = Union{Int, Missing}[missing, 75000, 110000, 180000]
        ),

        "small_xlsx" => DataFrame(
            AssetID = ["AAPL", "MSFT", "GOOG", "BTC"],
            AssetType = ["Stock", "Stock", "Stock", "CRYPTO"],
            Volume = [123456, 234567, 345678, 50000],
            Price = [145.67, 208.56, 2762.32, 35000],
            Exchange = ["NASDAQ", "NASDAQ", "NASDAQ", "BINANCE"]
        ),
 
        "empty_xlsx" => DataFrame(),

        "single_row_xlsx" =>  DataFrame(
            AssetID = ["AAPL"],
            Type = ["Stock"],
            Volume = [1000],
            Value = [150000]
        ),
        
        "missing_values_xlsx" => DataFrame(
            AssetID = Union{String, Missing}["AAPL", "GOOG", "MSFT", missing],
            Type = Union{String, Missing}["Stock", "Stock", "Stock", "ETF"],
            Volume = Union{Int, Missing}[1000, missing, 1200, 600],
            Value = Union{Int, Missing}[missing, 75000, 110000, 180000]
        ),
        
    )
end
