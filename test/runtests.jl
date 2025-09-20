using SEQ2EXPdata
using Test

@testset "SEQ2EXPdata.jl" begin
    
    @testset "Basic Dataset Creation" begin
        # Test simple dataset creation
        strings = ["ATCG", "GGTA", "CCCC"]
        labels = [1.0, 2.0, 3.0]
        ds = SEQ2EXP_Dataset(strings, labels)
        
        @test ds.strings == strings
        @test ds.labels == labels
        @test ds.feature_names === nothing
        @test ds.consensus === nothing
    end
    
    @testset "Dataset with Feature Names" begin
        strings = ["ATCG", "GGTA"]
        labels = [1.0 2.0; 3.0 4.0]
        feature_names = ["exp1", "exp2"]
        
        ds = SEQ2EXP_Dataset(strings, labels, feature_names)
        @test ds.feature_names == feature_names
        @test size(ds.labels) == (2, 2)
    end
    
    @testset "Dataset with Consensus" begin
        strings = ["ATCG", "ATCA", "ATGG"]
        labels = [1.0, 2.0, 3.0]
        
        ds = SEQ2EXP_Dataset(strings, labels; GET_CONSENSUS=true)
        @test has_consensus(ds)
        @test get_consensus(ds) == "ATCG"  # Most frequent at each position
    end
    
    @testset "Validation Tests" begin
        # Test unequal string lengths
        @test_throws ArgumentError SEQ2EXP_Dataset(["AT", "ATCG"], [1.0, 2.0])
        
        # Test mismatched strings and labels count
        @test_throws ArgumentError SEQ2EXP_Dataset(["ATCG", "GGTA"], [1.0, 2.0, 3.0])
        
        # Test mismatched feature names length
        @test_throws AssertionError SEQ2EXP_Dataset(
            ["ATCG", "GGTA"], 
            [1.0 2.0; 3.0 4.0], 
            ["exp1"]  # Should be 2 feature names, not 1
        )
    end
    
    @testset "Accessor Functions" begin
        strings = ["ATCG", "GGTA"]
        labels = [1.0, 2.0]
        ds = SEQ2EXP_Dataset(strings, labels)
        
        # Test get_sequence_and_labels
        seqs, labs = get_sequence_and_labels(ds)
        @test seqs == strings
        @test labs == labels
        
        # Test get_feature_names
        @test get_feature_names(ds) === nothing
        
        # Test consensus functions
        @test !has_consensus(ds)
        @test_throws ArgumentError get_consensus(ds)
    end
    
    @testset "Consensus Function" begin
        # Test consensus computation directly
        strings = ["ATCG", "ACCG", "ATCA"]
        consensus = SEQ2EXPdata.get_consensus(strings)
        @test consensus == "ATCG"  # A-T-C-G are most frequent at each position
        
        # Test with ties (should pick one consistently)
        strings_tie = ["AT", "GC"]
        consensus_tie = SEQ2EXPdata.get_consensus(strings_tie)
        @test length(consensus_tie) == 2
        
        # Test error cases
        @test_throws ArgumentError SEQ2EXPdata.get_consensus(String[])
        @test_throws ArgumentError SEQ2EXPdata.get_consensus(["AT", "GCG"])
    end
    
    @testset "Display Test" begin
        # Test that show doesn't error (basic smoke test)
        strings = ["ATCG", "GGTA"]
        labels = [1.0, 2.0]
        ds = SEQ2EXP_Dataset(strings, labels)
        
        io = IOBuffer()
        show(io, ds)
        output = String(take!(io))
        @test occursin("SEQ2EXP_Dataset", output)
        @test occursin("2 sequences", output)
    end
    
    @testset "Utility Functions" begin
        strings = ["ATCG", "GGTA", "CCAC"]
        labels = [1.2, 3.4, 4.1]
        feature_names = nothing
        ds = SEQ2EXP_Dataset(strings, labels, feature_names)

        # get_sequence_and_labels
        seqs, labs = get_sequence_and_labels(ds)
        @test seqs == strings
        @test labs == labels

        # get_feature_names
        @test get_feature_names(ds) === nothing

        # get_sequence_length
        @test get_sequence_length(ds) == 4

        # get_feature_counts (vector labels)
        @test get_feature_counts(ds) == 1

        # With feature names and matrix labels
        labels2 = [1.0 2.0; 4.0 5.0]
        ds2 = SEQ2EXP_Dataset(["ATCG", "GGTA"], labels2, ["exp1", "exp2"])
        @test get_feature_names(ds2) == ["exp1", "exp2"]
        @test get_feature_counts(ds2) == 2
    end
    
    @testset "@seq2exp Macro Tests" begin
        # Test simple case
        ds_macro1 = @seq2exp ["ATCG", "GGTA"] [1.2, 3.4]
        @test ds_macro1.strings == ["ATCG", "GGTA"]
        @test ds_macro1.labels == [1.2, 3.4]
        @test ds_macro1.feature_names === nothing
        @test ds_macro1.consensus === nothing

        # Test with feature names
        ds_macro2 = @seq2exp ["ATCG", "GGTA"] [1.0 2.0; 3.0 4.0] ["exp1", "exp2"]
        @test ds_macro2.strings == ["ATCG", "GGTA"]
        @test ds_macro2.labels == [1.0 2.0; 3.0 4.0]
        @test ds_macro2.feature_names == ["exp1", "exp2"]
        @test ds_macro2.consensus === nothing

        # Test with consensus computation
        ds_macro3 = @seq2exp ["ATCG", "ATCA", "ATGG"] [1.0, 2.0, 3.0] nothing GET_CONSENSUS=true
        @test ds_macro3.strings == ["ATCG", "ATCA", "ATGG"]
        @test ds_macro3.labels == [1.0, 2.0, 3.0]
        @test ds_macro3.feature_names === nothing
        @test has_consensus(ds_macro3)
        @test get_consensus(ds_macro3) == "ATCG"

        # Test that macro produces equivalent results to constructor
        strings = ["ATCG", "GGTA"]
        labels = [1.2, 3.4]
        ds_constructor = SEQ2EXP_Dataset(strings, labels)
        ds_macro = @seq2exp strings labels
        @test ds_constructor.strings == ds_macro.strings
        @test ds_constructor.labels == ds_macro.labels
        @test ds_constructor.feature_names == ds_macro.feature_names
        @test ds_constructor.consensus == ds_macro.consensus
    end
    
    @testset "Type Conversion" begin
        strings = ["ATCG", "GGTA"]
        labels = [1, 2]

        # Default: inferred type (Int)
        ds_int = SEQ2EXP_Dataset(strings, labels)
        @test eltype(ds_int.labels) == Int

        # Specify Float32
        ds_f32 = SEQ2EXP_Dataset(strings, labels; type=Float32)
        @test eltype(ds_f32.labels) == Float32
        @test ds_f32.labels == Float32[1, 2]

        # Specify Float64
        ds_f64 = SEQ2EXP_Dataset(strings, labels; type=Float64)
        @test eltype(ds_f64.labels) == Float64
        @test ds_f64.labels == Float64[1, 2]

        # Specify Float16
        ds_f16 = SEQ2EXP_Dataset(strings, labels; type=Float16)
        @test eltype(ds_f16.labels) == Float16
        @test ds_f16.labels == Float16[1, 2]

        # Matrix case
        labels_mat = [1 2; 3 4]
        ds_mat_f32 = SEQ2EXP_Dataset(strings, labels_mat; type=Float32)
        @test eltype(ds_mat_f32.labels) == Float32
        @test ds_mat_f32.labels == Float32[1 2; 3 4]
    end
end
