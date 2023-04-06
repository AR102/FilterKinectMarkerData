using FilterKinect
using Test
using ReferenceTests

"""
If `false` (default) , create a temporary directory for the tests. 
This directory will be automatically deleted after the program has run.

If `true`, use a local directory `tmp/` instead. This is helpful when debugging the tests as
it allows to look at files produced by the tests.
"""
TESTS_USE_LOCAL_DIR = false

isfile("../dev.jl") && include("../dev.jl")

if TESTS_USE_LOCAL_DIR
    dir = "tmp/"
    isfile(joinpath(dir, "test_file.trc")) && rm(joinpath(dir, "test_file.trc"))
    isdir(dir) && rm(dir)
    mkdir(dir)
else
    dir = mktempdir()
end

@info dir
@testset "FilterKinect.jl" begin
    file = "test_file.trc"
    @testset "Saving & Loading" begin
        global data, data2
        # Check if header got read correctly
        @test_reference "references/headernames.txt" FilterKinect.get_header_names(file)[1]

        # Make sure loading and saving doesn't change / corrupt the data
        data = load_markerdata(file)
        save(data, joinpath(dir, "test_file.trc"))
        data2 = load_markerdata(joinpath(dir, "test_file.trc"))
        @test data == data2
    end
    @testset "Filtering" begin
        data = load_markerdata(file)
        FilterKinect.filter!(data, "HEAD_X")
        @test_reference "references/filtered_head-x.txt" data.HEAD_X
    end
end
