@testset "Simple" begin
    @testset "naive" begin
        data = [1, 2, 3]
        #need to remove missing data since isapprox doesnt work with int
        naive_pred_clean = collect(skipmissing(naive(data, 1)))
        @test isapprox(naive_pred_clean, [1, 2])
    end
    @testset "sma" begin
        data = [10, 1, 4, 5, 7]
        sma_pred_clean = collect(skipmissing(sma(data, 3)))
        @test isapprox(sma_pred_clean, [5.0, 3.333, 5.333], atol = 0.001)
    end

    @testset "linear_predict" begin
        data = [1, 2, 3, 4]
        @test isapprox(linear_predict(data, 1), 5, atol = 0.001)
    end
end
