using AirBorne.ETL.AssetValuation:
    valuePortfolio, stockValuation, covariance, returns, sharpe
using AirBorne.ETL.Cache: load_bundle

using Test
@testset "AssetValuation.jl" begin

    # cache_dir = joinpath("test","assets", "cache")
    cache_dir = joinpath(@__DIR__, "assets", "cache")

    # To generate this data use:
    # using AirBorne.ETL.YFinance: get_interday_data
    # using AirBorne.ETL.Cache: store_bundle
    # using Dates: DateTime, datetime2unix
    # from = DateTime("2017-01-01"); to = DateTime("2022-01-01")
    # u_from = string(round(Int, datetime2unix(from)));
    # u_to = string(round(Int, datetime2unix(to)))
    # data = get_interday_data(["AAPL","GOOG"], u_from, u_to)
    # store_bundle(data; bundle_id="demo", archive=true, cache_dir=cache_dir)

    data = load_bundle("demo"; cache_dir=cache_dir)
    # @info cache_dir
    # @info names(data)
    sv = stockValuation(data)
    @test size(sv) == (1259, 4)
    portfolio = Dict("NMS/AAPL" => 100, "NMS/GOOG" => 200)
    rets = returns(sv)
    @test round(valuePortfolio(portfolio, sv[1, "stockValue"]); digits=2) == 10765.15
    @test size(rets) == size(sv)
    @test size(sharpe(rets[1:100, "NMS/AAPL"]; windowSize=5)) == (100,)
    @test size(covariance(rets)) == (2, 2)
end
