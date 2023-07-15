using HTTP, JSON, DataFrames, CSV

abstract type FinancialPlatform end

struct APIKeyJSON_Historical <: FinancialPlatform
    api_url::String
    api_key::String
end

struct OAuthJSON_Historical <: FinancialPlatform
    api_url::String
    access_token::String
end

struct APIKeyCSV_Historical <: FinancialPlatform
    api_url::String
    api_key::String
end

struct OAuthCSV_Historical <: FinancialPlatform
    api_url::String
    access_token::String
end

struct NoAPIKey_Historical
    api_url::String
end

function parse_ticker_data(ticker_data, ticker, input_args::Dict{Symbol, Any})
    prices_key = input_args[:prices_key]
    market_caps_key = input_args[:market_caps_key]
    total_volumes_key = input_args[:total_volumes_key]
    columns = input_args[:columns]

    parsed_data = try
        prices = get(ticker_data, prices_key, [])
        market_caps = get(ticker_data, market_caps_key, [])
        total_volumes = get(ticker_data, total_volumes_key, [])

        df = DataFrame()
        for col in columns
            df[!, col] = Vector{Union{Missing, typeof(ticker_data[col][1])}}()
        end

        for (price, market_cap, total_volume) in zip(prices, market_caps, total_volumes)
            row = Dict{Symbol, Union{Missing, Real}}()
            for col in columns
                value = getfield(ticker_data, col)
                if value !== nothing
                    row[col] = coalesce(value, missing)
                end
            end
            push!(df, row)
        end

        return df
    catch
        # If parsing fails, return the original unparsed data in a DataFrame
        return DataFrame(UnparsedData = [ticker_data])
    end
end



function get_historical_data(platform::APIKeyJSON_Historical, universe_securities::Vector{String})
    historical_data = []

    for ticker in universe_securities
        url = platform.api_url * "/historical-data/$ticker"
        headers = Dict("X-API-KEY" => platform.api_key)
        response = HTTP.get(url, headers=headers)

        ticker_data = JSON.parse(String(response.body))
        ticker_df = parse_ticker_data(ticker_data, ticker)

        push!(historical_data, ticker_df)
    end

    return historical_data
end

function get_historical_data(platform::OAuthJSON_Historical, universe_securities::Vector{String})
    historical_data = []

    for ticker in universe_securities
        url = platform.api_url * "/historical-data/$ticker"
        headers = Dict("Authorization" => "Bearer $(platform.access_token)")
        response = HTTP.get(url, headers=headers)

        ticker_data = JSON.parse(String(response.body))
        ticker_df = parse_ticker_data(ticker_data, ticker)

        push!(historical_data, ticker_df)
    end

    return historical_data
end

function get_historical_data(platform::APIKeyCSV_Historical, universe_securities::Vector{String})
    historical_data = []

    for ticker in universe_securities
        url = platform.api_url * "/historical-data/$ticker"
        headers = Dict("X-API-KEY" => platform.api_key)
        response = HTTP.get(url, headers=headers)

        ticker_data = CSV.read(IOBuffer(response.body), DataFrame)
        ticker_df = parse_ticker_data(ticker_data, ticker)

        push!(historical_data, ticker_df)
    end

    return historical_data
end

function get_historical_data(platform::OAuthCSV_Historical, universe_securities::Vector{String})
    historical_data = []

    for ticker in universe_securities
        url = platform.api_url * "/historical-data/$ticker"
        headers = Dict("Authorization" => "Bearer $(platform.access_token)")
        response = HTTP.get(url, headers=headers)

        ticker_data = CSV.read(IOBuffer(response.body), DataFrame)
        ticker_df = parse_ticker_data(ticker_data, ticker)

        push!(historical_data, ticker_df)
    end

    return historical_data
end

function get_historical_data(platform::NoAPIKey_Historical, tickers::Vector{String})
    historical_data = []

    for ticker in tickers
        api_url_with_ticker = replace(platform.api_url, "{ticker}" => ticker)

        response = HTTP.get(api_url_with_ticker)
        ticker_data = JSON.parse(String(response.body))

        ticker_df = parse_ticker_data(ticker_data, ticker)

        push!(historical_data, ticker_df)
    end

    return historical_data
end

function main()
    input_args = Dict(
    :prices_key => "prices",
    :market_caps_key => "market_caps",
    :total_volumes_key => "total_volumes",
    :columns => [:Timestamp, :Price, :MarketCap, :TotalVolume]
)

    universe_securities = ["bitcoin", "ethereum", "litecoin"]
    coingecko_api_url = "https://api.coingecko.com/api/v3/coins/{ticker}/market_chart?vs_currency=usd&days=max&interval=daily"
    coingecko_platform = NoAPIKey_Historical(coingecko_api_url)
    historical_data = get_historical_data(coingecko_platform, universe_securities)

    for (i, ticker) in enumerate(universe_securities)
        println("Historical data for $(ticker):")
        println(historical_data[i])
        println("\n")
    end
end

main()