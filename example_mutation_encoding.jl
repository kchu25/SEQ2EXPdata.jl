using SEQ2EXPdata

println("=" ^ 80)
println("Mutation Encoding Example")
println("=" ^ 80)

# Create sequences with some mutations relative to a consensus
sequences = ["ATCG", "ATCA", "ATGG", "TTCG"]
labels = [1.0, 2.0, 3.0, 4.0]

println("\nInput Sequences:")
for (i, seq) in enumerate(sequences)
    println("  $i: $seq")
end

# Create dataset with consensus
ds = SEQ2EXP_Dataset(sequences, labels; GET_CONSENSUS=true)
println("\nConsensus: ", ds.consensus)

# Create one-hot encoded dataset
ods = OnehotSEQ2EXP_Dataset(ds)

println("\n" * "=" ^ 80)
println("Standard One-Hot Encoding (X)")
println("=" ^ 80)
println("Shape: ", size(ods.X))
println("\nFor each sequence, showing which channel (A=1, C=2, G=3, T=4) is '1' at each position:")
println("(Channel × Position × 1 × Sequence)")

for seq_idx in 1:size(ods.X, 4)
    println("\nSequence $seq_idx: $(sequences[seq_idx])")
    print("  Positions:  ")
    for pos in 1:size(ods.X, 2)
        print("  $pos  ")
    end
    println()
    
    for channel in 1:4
        channel_name = ["A", "C", "G", "T"][channel]
        print("  $channel_name:         ")
        for pos in 1:size(ods.X, 2)
            val = ods.X[channel, pos, 1, seq_idx]
            print(val > 0 ? " [1] " : "  0  ")
        end
        println()
    end
end

println("\n" * "=" ^ 80)
println("Mutation Encoding (X_mut) - Only differences from consensus")
println("=" ^ 80)
println("Shape: ", size(ods.X_mut))
println("Consensus: ", ds.consensus)
println("\nShowing only positions that differ from consensus:")

for seq_idx in 1:size(ods.X_mut, 4)
    println("\nSequence $seq_idx: $(sequences[seq_idx])")
    
    # Find positions with mutations
    has_mutation = false
    print("  Positions:  ")
    for pos in 1:size(ods.X_mut, 2)
        if any(ods.X_mut[:, pos, 1, seq_idx] .> 0)
            print("  $pos  ")
            has_mutation = true
        else
            print("  -  ")
        end
    end
    println()
    
    if has_mutation
        for channel in 1:4
            channel_name = ["A", "C", "G", "T"][channel]
            print("  $channel_name:         ")
            for pos in 1:size(ods.X_mut, 2)
                if any(ods.X_mut[:, pos, 1, seq_idx] .> 0)
                    val = ods.X_mut[channel, pos, 1, seq_idx]
                    print(val > 0 ? " [1] " : "  0  ")
                else
                    print("  -  ")
                end
            end
            println()
        end
    else
        println("  (No mutations - identical to consensus)")
    end
end

println("\n" * "=" ^ 80)
println("Sparsity Comparison")
println("=" ^ 80)
num_ones_standard = sum(ods.X)
num_ones_mutation = sum(ods.X_mut)
sparsity_reduction = (1 - num_ones_mutation/num_ones_standard) * 100

println("Standard encoding: $num_ones_standard ones")
println("Mutation encoding: $num_ones_mutation ones")
println("Sparsity reduction: $(round(sparsity_reduction, digits=1))%")

println("\n" * "=" ^ 80)
println("Mutation Summary by Sequence")
println("=" ^ 80)
for seq_idx in 1:length(sequences)
    consensus_chars = collect(ds.consensus)
    seq_chars = collect(sequences[seq_idx])
    mutations = []
    
    for pos in 1:length(seq_chars)
        if seq_chars[pos] != consensus_chars[pos]
            push!(mutations, "pos $pos: $(consensus_chars[pos])→$(seq_chars[pos])")
        end
    end
    
    if isempty(mutations)
        println("Sequence $seq_idx ($(sequences[seq_idx])): No mutations (matches consensus)")
    else
        println("Sequence $seq_idx ($(sequences[seq_idx])): $(join(mutations, ", "))")
    end
end

println("\n" * "=" ^ 80)
println("Full Arrays (showing all zeros)")
println("=" ^ 80)

println("\nStandard One-Hot Encoding (X):")
println("Shape: (channels=4, positions=4, batch=1, sequences=4)")
println("\nSequence-by-sequence view:")
for seq_idx in 1:size(ods.X, 4)
    println("\nSequence $seq_idx: $(sequences[seq_idx])")
    for channel in 1:4
        channel_name = ["A", "C", "G", "T"][channel]
        println("  $channel_name: ", ods.X[channel, :, 1, seq_idx])
    end
end

println("\n" * "-" ^ 80)
println("\nMutation Encoding (X_mut):")
println("Shape: (channels=4, positions=4, batch=1, sequences=4)")
println("\nSequence-by-sequence view (zeros show conserved positions):")
for seq_idx in 1:size(ods.X_mut, 4)
    println("\nSequence $seq_idx: $(sequences[seq_idx])")
    for channel in 1:4
        channel_name = ["A", "C", "G", "T"][channel]
        println("  $channel_name: ", ods.X_mut[channel, :, 1, seq_idx])
    end
end

println("\n" * "=" ^ 80)
