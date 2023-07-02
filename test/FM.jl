using AirBorne: AirBorne
using Test
@testset "AirBorne.FM" begin
    using Currencies: Currencies
    USD = Currencies.currency(:USD)
    GBP = Currencies.currency(:GBP)
    UYU = Currencies.currency(:UYU)

    # Money Instantiation
    a = 10USD
    b = 10.0USD
    c1 = AirBorne.Money{:GBP}(5.0)
    c2 = AirBorne.Money{:GBP}(5)

    # Money Arithmetic Operations
    @test 2.0 * a == (b + b)
    @test 2.0 * a == b * 2
    @test 2 * a == b * 2.0
    @test USD * 2 == USD * 2.0

    # Currency checks
    @test AirBorne.get_symbol(c1) == AirBorne.get_symbol(typeof(c2))
    @test AirBorne.sameCurrency(a, b) === true
    @test AirBorne.sameCurrency(a, c1) === false

    # Currency Exchange
    exchangeRateI = Dict{Tuple{Symbol,Symbol},Real}(
        (:USD, :GBP) => 2, (:GBP, :USD) => 1//2, (:USD, :UYU) => 50
    )

    @test AirBorne.exchange(10USD, :GBP, 1//2) == 5GBP # Specify rate
    @test AirBorne.exchange(10USD, :USD, exchangeRateI) == 10USD # Same Currency 
    @test AirBorne.exchange(10USD, :UYU, exchangeRateI) == 500UYU # Known Exchange
    @test AirBorne.exchange(500UYU, :USD, exchangeRateI) == 10USD # Known Inverse

    # Wallet tests
    w0 = AirBorne.Wallet(USD) # Test Later
    w1 = AirBorne.Wallet(:USD)
    @test w0 == w1
    @test w1[:USD] == 0
    @test w1[:GBP] == 0
    @test length(w1) == 1

    w2 = AirBorne.Wallet(20USD)
    w3 = AirBorne.Wallet(50UYU)
    w4 = AirBorne.Wallet(Dict(:USD => 20, :UYU => 50))
    w5 = deepcopy(w3)
    w5[:USD] = 10.0

    # Arithmetic operations between wallets and money
    @test w2 + 50UYU == w4
    @test 20USD + w3 == w4
    @test w2 + w3 == w4
    @test 20USD + 50UYU == w4
    @test w5[:USD] == 10

    # Opeations with keys
    @test haskey(w5, :USD)
    @test collect(keys(w5)) == [:UYU, :USD]
end
