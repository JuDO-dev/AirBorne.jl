
"""
    This modules provides an interface between AirBorne and Yahoo Finance API. 
"""
module YFinance
using HTTP: HTTP
using JSON: JSON
using Dates: Dates
using DataFrames: DataFrames

export get_interday_data
export hello_yfinance

using Logging: Logging

rate_limits = """"""

"""
    hello_yfinance()

Returns a string saying "Hello YFinance!".
"""
function hello_yfinance()
    return "Hello YFinance!"
end

urlencode(x) = HTTP.URIs.escapeuri(x)

"""
    get_chart_data(symbol, period1, period2, freq)

This function calls the Yahoo chart API to get the OHCLV data.
The documentation for this function is based on [CryptoCoinTracker's guide](https://cryptocointracker.com/yahoo-finance/yahoo-finance-api#34a6032b7b9949a1876f4568e4961afd).

# Arguments

- `symbol::String`:  Ticker Symbol
- `period1::String`:  UNIX Timestamp indicating the start of the data requested
- `period2::String`:  UNIX Timestamp indicating the end time of the data requested 
- `freq::String`: The time interval between two data points. Can be 1m 2m 5m 15m 30m 60m 90m 1h 1d 5d 1wk 1mo 3mo.

# Returns
- r::HTTP.Messages.Response

# Examples
```julia
# This example is untestable as it requires internet connection.
julia> import AirBorne
julia> r = AirBorne.ETL.YFinance.get_chart_data("AAPL","1577836800","1580515200","1d")
```
"""
function get_chart_data(symbol, period1, period2, freq)
    YAHOO_CHART_V8_URL = "https://query1.finance.yahoo.com/v8/finance/chart/$symbol?"
    params = Dict(
        "period1" => period1,
        "period2" => period2,
        "interval" => freq,
        "events" => "div%7Csplit",
        "includePrePost " => "true",
    )
    url = YAHOO_CHART_V8_URL * HTTP.URIs.escapeuri(params)
    r = HTTP.request("GET", url)
    return r
end

function parse_intraday_raw_data(r)
    resp = deepcopy(r.body)
    resp_json = JSON.parse(String(resp))
    df = DataFrames.DataFrame(resp_json["chart"]["result"][1]["indicators"]["quote"][1])
    gmt_offset = resp_json["chart"]["result"][1]["meta"]["gmtoffset"]
    unix_timestamps_vector = resp_json["chart"]["result"][1]["timestamp"]
    date_vector = [
        Dates.unix2datetime(x + gmt_offset) for
        x in resp_json["chart"]["result"][1]["timestamp"]
    ]
    df[:, :"date"] = date_vector
    df[:, :"unix"] = unix_timestamps_vector
    df[:, :"exchangeName"] .= resp_json["chart"]["result"][1]["meta"]["exchangeName"]
    df[:, :"timezone"] .= resp_json["chart"]["result"][1]["meta"]["exchangeTimezoneName"]
    df[:, :"currency"] .= resp_json["chart"]["result"][1]["meta"]["currency"]
    df[:, :"symbol"] .= resp_json["chart"]["result"][1]["meta"]["symbol"]
    return df
end

"""
    function get_interday_data(symbols, period1, period2)

Use this function to get interday data for different tickers from Yahoo charts API.

# Arguments
- `symbols::String`:  Ticker Symbol
- `period1::String`:  UNIX Timestamp indicating the start of the data requested
- `period2::String`:  UNIX Timestamp indicating the end time of the data requested 

# Example
```julia
import AirBorne
data = AirBorne.ETL.YFinance.get_interday_data(["AAPL","GOOG"],"1577836800","1580515200")
```
"""
function get_interday_data(symbols, period1, period2)
    freq = "1d"
    df = DataFrames.DataFrame()
    for ticker in symbols
        df = DataFrames.vcat(
            df, parse_intraday_raw_data(get_chart_data(ticker, period1, period2, freq))
        )
    end
    return df
end

end
