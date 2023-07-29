using AirBorne.ETL.AssetValuation:
    valuePortfolio, stockValuation, covariance, returns, sharpe, logreturns
using AirBorne.ETL.Cache: load_bundle

using Test
@testset "AssetValuation.jl" begin
    cache_dir = joinpath(@__DIR__, "assets", "cache") # joinpath("test","assets", "cache")
    data = load_bundle("demo"; cache_dir=cache_dir)
    sv = stockValuation(data)
    @test size(sv) == (1259, 4)
    portfolio = Dict("NMS/AAPL" => 100, "NMS/GOOG" => 200)
    rets = returns(sv)
    logrets = returns(sv;returnFun=logreturns) # Logarithmic return on Value DataFrame
    @test round(valuePortfolio(portfolio, sv[1, "stockValue"]); digits=2) == 10765.15
    @test size(rets) == size(sv)
    @test size(logrets) == size(sv)
    @test size(sharpe(rets[1:100, "NMS/AAPL"]; windowSize=5)) == (100,)
    @test size(covariance(rets)) == (2, 2)
end

# To generate the "demo" data use:
# using AirBorne.ETL.YFinance: get_interday_data
# using AirBorne.ETL.Cache: store_bundle
# using Dates: DateTime, datetime2unix
# from = DateTime("2017-01-01"); to = DateTime("2022-01-01")
# u_from = string(round(Int, datetime2unix(from)));
# u_to = string(round(Int, datetime2unix(to)))
# data = get_interday_data(["AAPL","GOOG"], u_from, u_to)
# store_bundle(data; bundle_id="demo", archive=true, cache_dir=cache_dir)
