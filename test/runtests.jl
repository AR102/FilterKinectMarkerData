using FilterKinect
using Test
using ReferenceTests

dir = "tmp/" #mktempdir()
isfile(joinpath(dir, "test_file.trc")) && rm(joinpath(dir, "test_file.trc"))
isdir(dir) && rm(dir)
mkdir(dir)

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
