@testset "Behavioural" begin
    @testset "hankel_scalar" begin
        data = [1.0, 5.0, 6.0, 8.0, 10.0, 12.0]
        hank = hankel_scalar(data, 3)
        @test isapprox(hank, 
        [1.0 5.0 6.0 8.0;
        5.0 6.0 8.0 10.0;
        6.0 8.0 10.0 12.0]) 
    end
    @testset "form_w_given" begin 
        data = [1.0 2.0;
                3.0 4.0;
                5.0 6.0]
        w_given = form_w_given(data)
        @test isapprox(w_given, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0])
    end

    @testset "hankel_vector" begin
        data = [1.0 2.0;
                3.0 4.0;
                5.0 6.0;
                7.0 8.0;
                9.0 10.0]
        hank = hankel_vector(data, 2)
        @test isapprox(hank,
        [1.0 3.0 5.0 7.0;
        2.0 4.0 6.0 8.0;
        3.0 5.0 7.0 9.0;
        4.0 6.0 8.0 10.0])
    end
end

