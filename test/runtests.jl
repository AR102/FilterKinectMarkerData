using FilterKinect
using Test
include("comparison_values.jl")

@testset "FilterKinect.jl" begin
    file = "test_file.trc"
    @testset "Saving & Loading" begin
        # Check if header got read correctly
        @test FilterKinect.get_header_names(file)[1] == HEADER_NAMES

        # Make sure loading and saving doesn't change / corrupt the data
        data = load_markerdata(file)
        save_markerdata(data, "tmp_test_file.trc")
        data2 = load_markerdata("tmp_test_file.trc")
        @test isequal(data, data2)
    end
    @testset "Filtering" begin
        data = load_markerdata(file)
        FilterKinect.filter!(data, "HEAD_X")
        @test data.HEAD_X == FILTERED_VALS
    end
end
