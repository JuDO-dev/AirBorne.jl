using Test
using Airborne
using CSV, DataFrames, XLSX, JSON, SQLite, LibPQ, HTTP, Dates
using Logging

include("../src/usermetrics.jl")
include("test_usermetrics_expectedresults.jl")
expected_results = get_expected_result()


# Function to generate full file path
function gen_path(filename::String, ext::String)
    return joinpath(@__DIR__, "testdata", string(filename, ".", ext))
end

# Define a testset for Parsing functions
@testset "Parsing Functions Tests" begin
    # CSV_Parsing Tests
    @testset "CSV_Parsing Tests" begin
        @test parse_input(gen_path("small", "csv"), CSVParsing(), ',') == expected_results["small_csv"]
        @test parse_input(gen_path("empty", "csv"), CSVParsing(), ',') == expected_results["empty_csv"]
        @test parse_input(gen_path("single_row", "csv"), CSVParsing(), ',') == expected_results["single_row_csv"]
        @test isequal(parse_input(gen_path("missing_values", "csv"), CSVParsing(), ','), expected_results["missing_values_csv"])
        @test_throws ArgumentError parse_input(gen_path("irregulardata", "csv"), CSVParsing(), ',')
    end


    #Excel_Parsing Tests

    @testset "Excel_Parsing Tests" begin
        @test parse_input(gen_path("small", "xlsx"), ExcelParsing(), "small") == expected_results["small_xlsx"]
        @test parse_input(gen_path("empty", "xlsx"), ExcelParsing(), "empty") == expected_results["empty_xlsx"]
        @test parse_input(gen_path("single_row", "xlsx"), ExcelParsing(), "single_row") == expected_results["single_row_xlsx"]
        @test isequal(parse_input(gen_path("missing_values", "xlsx"), ExcelParsing(), "missing_values"), expected_results["missing_values_xlsx"])
        @test_throws ArgumentError parse_input(gen_path("irregulardata", "xlsx"), ExcelParsing(), "irregulardata")
     end
    # JSON_Parsing Tests
    @testset "JSON_Parsing Tests" begin
        @test parse_input(gen_path("small", "json"), JSONParsing(), ',') == expected_results["small_json"]
        @test parse_input(gen_path("empty", "json"), JSONParsing(), ',') == expected_results["empty_json"]
        @test parse_input(gen_path("single_row", "json"), JSONParsing(), ',') == expected_results["single_row_json"]
        @test isequal(parse_input(gen_path("missing_values", "json"), JSONParsing(), ','), expected_results["missing_values_json"])
        @test_throws ArgumentError parse_input(gen_path("irregulardata", "json"), JSONParsing(), ',')
    end

    # SQLite_Parsing Tests
    @testset "SQLite_Parsing Tests" begin
        @test parse_input(gen_path("small", "sqlite"), SQLiteParsing(), ',') == expected_results["small_sqlite"]
        @test parse_input(gen_path("empty", "sqlite"), SQLiteParsing(), ',') == expected_results["empty_sqlite"]
        @test parse_input(gen_path("single_row", "sqlite"), SQLiteParsing(), ',') == expected_results["single_row_sqlite"]
        @test isequal(parse_input(gen_path("missing_values", "sqlite"), SQLiteParsing(), ','), expected_results["missing_values_sqlite"])
        @test_throws ArgumentError parse_input(gen_path("irregulardata", "sqlite"), SQLiteParsing(), ',')
    end

    # PostgreSQL_Parsing Tests
    @testset "PostgreSQL_Parsing Tests" begin
        @test parse_input(gen_path("small", "postgresql"), PostgreSQLParsing(), ',') == expected_results["small_postgresql"]
        @test parse_input(gen_path("empty", "postgresql"), PostgreSQLParsing(), ',') == expected_results["empty_postgresql"]
        @test parse_input(gen_path("single_row", "postgresql"), PostgreSQLParsing(), ',') == expected_results["single_row_postgresql"]
        @test isequal(parse_input(gen_path("missing_values", "postgresql"), PostgreSQLParsing(), ','), expected_results["missing_values_postgresql"])
        @test_throws ArgumentError parse_input(gen_path("irregulardata", "postgresql"), PostgreSQLParsing(), ',')
    end
end