@testset "Errors" begin
    @testset "remove_first_i_vals" begin
        temp = [1, 2, 3, 4, 5, 6, 7, 8]
        @test isapprox(remove_first_i_vals(temp, 1), [2, 3, 4, 5, 6, 7, 8])
        temp = [1, 2, 3, 4, 5, 6, 7, 8]
        @test isapprox(remove_first_i_vals(temp, 5), [6, 7, 8])
        temp = [1, 2, 3, 4, 5, 6, 7, 8]
        @test isapprox(remove_first_i_vals(temp, 8), Int64[])
    end

    @testset "remove_last_i_vals" begin
        temp = [1, 2, 3, 4, 5, 6, 7, 8]
        @test isapprox(remove_last_i_vals(temp, 1), [1, 2, 3, 4, 5, 6, 7])
        temp = [1, 2, 3, 4, 5, 6, 7, 8]
        @test isapprox(remove_last_i_vals(temp, 5), [1, 2, 3])
        temp = [1, 2, 3, 4, 5, 6, 7, 8]
        @test isapprox(remove_last_i_vals(temp, 8), Int64[])
    end

    @testset "errors" begin
        pred = 10.0
        true_val = 20.0
        abs, rel, perc = errors(pred, true_val)
        @test isapprox(abs, 10.0)
        @test isapprox(rel, 0.5)
        @test isapprox(perc, 50.0)
        pred = 10.0
        true_val = 5.0
        abs, rel, perc = errors(pred, true_val)
        @test isapprox(abs, -5.0)
        @test isapprox(rel, -1.0)
        @test isapprox(perc, -100.0)
    end

    @testset "estimate_errors" begin
        predictions = [1, 2, 3, 4, 5, 6]
        true_vals = [2, 4, 1, 8, 9, 1]
        mse, mae, est = estimate_errors(predictions, true_vals)
        @test isapprox(mse, 11.0)
        @test isapprox(mae, 3.0)
        @test isapprox(est, 8.944, atol = 0.001)
    end

    @testset "get_error_matrix" begin
        # testing same length (one col)
        predictions = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
        true_vals = [2.0, 4.0, 1.0, 8.0, 9.0, 1.0]
        train_data = []
        abs_matx, rel_matx, est_matx = get_error_matrix(predictions, true_vals, train_data)
        @test isapprox(abs_matx, [1.0; 2.0; -2.0; 4.0; 4.0; -5.0])
        @test isapprox(rel_matx, [0.5; 0.5; -2.0; 0.5; 0.444; -5.0], atol = 0.001)
        @test isapprox(est_matx, [50.0; 50.0; -200.0; 50.0; 44.444; -500.0], atol = 0.001)

        # testing different length (one col)
        predictions = [missing , missing, missing, 5.0, 6.0, 7.0] # This is how the predictions of the behavioural will be outputted
        true_vals = [2.0, 4.0] # this is what test data will look like
        train_data = [1.0, 10.0, 20.0] # this is train data
        abs_matx, rel_matx, est_matx = get_error_matrix(predictions, true_vals, train_data)
        @test isapprox(abs_matx, [-3.0; -2.0])
        @test isapprox(rel_matx, [-1.5; -0.5])
        @test isapprox(est_matx, [-150.0; -50.0])

        # testing matrix of predictions 

        #The test should be carried out as below but isapprox doesnt work for missing values

        # predictions = [missing missing missing;
        #                 1.0     2.0     3.0;
        #                 10.0    20.0    5.0;
        #                 20.0    10.0     1.0;
        #                 11.0    12.0     10.0]
        # true_vals = [10.0, 10.0, 20.0]
        # train_data = [1.0]
        # abs_matx, rel_matx, perc_matx = get_error_matrix(predictions, true_vals, train_data)
        # @test isapprox(abs_matx, 
        # [9.0 8.0 17.0;
        # missing missing missing;
        # missing missing missing])
        # @test isapprox(rel_matx, 
        # [0.9 0.8 0.85;
        # missing missing missing;
        # missing missing missing])
        # @test isapprox(perc_matx,
        # [90.0 80.0 85.0;
        # missing missing missing;
        # missing missing missing])
    end

    @testset "rescale" begin
        data = get_data("AAPL", "2016-07-11", "2021-07-10", "", "1d")
        adj_close = data[:, 6]
        train, test = split_train_test(adj_close)
        test_stand = standardize(test, train)
        @test isapprox(rescale(test_stand, train), test, atol = 0.001)
    end
end