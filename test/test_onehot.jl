using Test
using SEQ2EXPdata
include("../src/onehot_encode/Onehot.jl")

@testset "OnehotSEQ2EXP_Dataset" begin
    # Create a SEQ2EXP_Dataset
    seqs = ["ATCG", "GGTA"]
    labels = [1.0, 2.0]
    ds = SEQ2EXP_Dataset(seqs, labels)

    # Create a OnehotSEQ2EXP_Dataset
    ods = OnehotSEQ2EXP_Dataset(ds)
    @test ods.raw_data === ds
    @test size(ods.onehot_sequences) == (4, 4, 1, 2)
    @test eltype(ods.onehot_sequences) == Float64

    # Test label accessors
    @test get_label(ods) == labels
    @test get_label_names(ods) === nothing

    # Show test (smoke test)
    io = IOBuffer()
    show(io, ods)
    output = String(take!(io))
    @test occursin("OnehotSEQ2EXP_Dataset", output)
    @test occursin("One-hot tensor shape", output)
end
