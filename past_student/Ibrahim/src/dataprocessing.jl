#get_tradable_securities defintion 


function get_tradable_securities(platform::APIKeyJSON, indexing_function::Function)
    headers = Dict("X-API-KEY" => platform.api_key)
    response = HTTP.get(platform.api_url, headers=headers)
    securities_data = JSON.parse(String(response.body))

    tradable_securities = indexing_function(securities_data)
    return tradable_securities
end

function get_tradable_securities(platform::OAuthJSON, indexing_function::Function)
    headers = Dict("Authorization" => "Bearer $(platform.access_token)")
    response = HTTP.get(platform.api_url, headers=headers)
    securities_data = JSON.parse(String(response.body))

    tradable_securities = indexing_function(securities_data)
    return tradable_securities
end

function get_tradable_securities(platform::APIKeyCSV, indexing_function::Function)
    headers = Dict("X-API-KEY" => platform.api_key)
    response = HTTP.get(platform.api_url, headers=headers)
    securities_data = CSV.read(IOBuffer(response.body), DataFrame)

    tradable_securities = indexing_function(securities_data)
    return tradable_securities
end

function get_tradable_securities(platform::OAuthCSV, indexing_function::Function)
    headers = Dict("Authorization" => "Bearer $(platform.access_token)")
    response = HTTP.get(platform.api_url, headers=headers)
    securities_data = CSV.read(IOBuffer(response.body), DataFrame)

    tradable_securities = indexing_function(securities_data)
    return tradable_securities
end

function get_tradable_securities(platform::NoAuthJSON, indexing_function::Function)
    response = HTTP.get(platform.api_url)
    securities_data = JSON.parse(String(response.body))

    tradable_securities = indexing_function(securities_data)
    return tradable_securities
end

function get_tradable_securities(platform::NoAuthCSV, indexing_function::Function)
    response = HTTP.get(platform.api_url)
    securities_data = CSV.read(IOBuffer(response.body), DataFrame)

    tradable_securities = indexing_function(securities_data)
    return tradable_securities
end


#----------------------------------------

function get_financial_securities(platform::APIKeyJSON, indexing_function::Function)
    headers = Dict("X-API-KEY" => platform.api_key)
    response = HTTP.get(platform.api_url, headers=headers)
    securities_data = JSON.parse(String(response.body))

    financial_securities = indexing_function(securities_data)
    return financial_securities
end

function get_financial_securities(platform::OAuthJSON, indexing_function::Function)
    headers = Dict("Authorization" => "Bearer $(platform.access_token)")
    response = HTTP.get(platform.api_url, headers=headers)
    securities_data = JSON.parse(String(response.body))

    financial_securities = indexing_function(securities_data)
    return financial_securities
end

function get_financial_securities(platform::APIKeyCSV, indexing_function::Function)
    headers = Dict("X-API-KEY" => platform.api_key)
    response = HTTP.get(platform.api_url, headers=headers)
    securities_data = CSV.read(IOBuffer(response.body), DataFrame)

    financial_securities = indexing_function(securities_data)
    return financial_securities
end

function get_financial_securities(platform::OAuthCSV, indexing_function::Function)
    headers = Dict("Authorization" => "Bearer $(platform.access_token)")
    response = HTTP.get(platform.api_url, headers=headers)
    securities_data = CSV.read(IOBuffer(response.body), DataFrame)

    financial_securities = indexing_function(securities_data)
    return financial_securities
end

function get_financial_securities(platform::NoAuthJSON, indexing_function::Function)
    response = HTTP.get(platform.api_url)
    securities_data = JSON.parse(String(response.body))

    financial_securities = indexing_function(securities_data)
    return financial_securities
end

function get_financial_securities(platform::NoAuthCSV, indexing_function::Function)
    response = HTTP.get(platform.api_url)
    securities_data = CSV.read(IOBuffer(response.body), DataFrame)

    financial_securities = indexing_function(securities_data)
    return financial_securities
end


#----------------------------------------------------------------------------------------------------
#Type defintion

abstract type PlatformType end

struct APIKeyJSON <: PlatformType
    api_url::String
    api_key::String
end

struct OAuthJSON <: PlatformType
    api_url::String
    access_token::String
end

struct APIKeyCSV <: PlatformType
    api_url::String
    api_key::String
end

struct OAuthCSV <: PlatformType
    api_url::String
    access_token::String
end

struct NoAuthJSON <: PlatformType
    api_url::String
end

struct NoAuthCSV <: PlatformType
    api_url::String
end
#-------------------------------------------------------------------------------------------------------------------------------

# Get Universe Securities Dispatch Function
function get_universe_securities_dispatch(trading_platform::PlatformType, financial_platform::PlatformType, trading_indexing_function::Function, financial_indexing_function::Function, constraints::Vector{GeneralConstraint}, denomination::String="USD")

    # Get tradable securities
    tradable_securities = get_tradable_securities(trading_platform, trading_indexing_function)
    
    # Get financial securities
    financial_securities = get_financial_securities(financial_platform, financial_indexing_function)

    # Apply constraints to the financial securities
    financial_securities = apply_constraints(financial_securities, constraints)
    tradable_securities = apply_constraints(tradable_securities.constraints)
    
    # Convert to uppercase for comparison
    tradable_tickers = [uppercase(get_feature(ticker, "AssetID") * denomination) for ticker in tradable_securities]
    financial_tickers = [uppercase(get_feature(ticker, "AssetID") * denomination) for ticker in financial_securities]

    # Get the intersection
    universe_tickers = intersect(tradable_tickers, financial_tickers)

    # Find the tickers that can be traded on the trading platform and have financial data available
    #universe_securities_trading_api = [tradable_securities[findfirst(t -> uppercase(get_feature(t, "AssetID") * denomination) == ticker, tradable_securities)] for ticker in universe_tickers]
    #universe_securities_financial_api = [financial_securities[findfirst(t -> uppercase(get_feature(t, "AssetID") * denomination) == ticker, financial_securities)] for ticker in universe_tickers]
    
    return (universe_tickers)
end




