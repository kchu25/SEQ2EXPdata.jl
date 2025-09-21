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

@testset "OnehotSEQ2EXP_Dataset Accessors" begin
    seqs = ["ATCG", "GGTA"]
    labels = [1.0, 2.0]
    ds = SEQ2EXP_Dataset(seqs, labels)
    ods = OnehotSEQ2EXP_Dataset(ds)

    # Accessors
    @test get_onehot(ods) === ods.onehot_sequences
    @test get_label(ods) === ds.labels
    @test get_label_names(ods) === ds.feature_names

    # Convenient accessors for features (X) and labels (Y)
    @test get_X(ods) === ods.onehot_sequences
    @test get_Y(ods) === ds.labels
    @test get_XY(ods) == (ods.onehot_sequences, ds.labels)

    # Dimensions
    @test get_X_dim(ods) == (4, 4)
    @test get_Y_dim(ods) == 1

    # Test with multi-label
    seqs2 = ["ATCG", "GGTA"]
    labels2 = [1.0 2.0; 3.0 4.0]  # 2 features, 2 samples
    ds2 = SEQ2EXP_Dataset(seqs2, labels2, ["f1", "f2"])  # Pass feature_names as positional
    ods2 = OnehotSEQ2EXP_Dataset(ds2)
    @test get_label(ods2) === ds2.labels
    @test get_label_names(ods2) === ds2.feature_names
    @test get_X_dim(ods2) == (4, 4)
    @test get_Y_dim(ods2) == 2
    @test get_XY(ods2) == (ods2.onehot_sequences, ds2.labels)
end
