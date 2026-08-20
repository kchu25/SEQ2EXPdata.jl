"""
    get_consensus(strings::Vector{String}) -> String

Compute the consensus sequence from a vector of strings of equal length.

For each position, finds the most frequently occurring character and constructs
the consensus sequence using these most common characters.

# Arguments
- `strings::Vector{String}`: Vector of strings, all must be the same length

# Returns
- `String`: Consensus sequence

# Examples
```julia
strings = ["ATCG", "ACCG", "ATCA"]
consensus = get_consensus(strings)
# Returns "ATCG" (A-T-C-G are most frequent at positions 1-2-3-4)
```

# Keyword arguments
- `min_modal_freq::Real=0.5`: warn when the most frequent character at some
  position accounts for less than this fraction of the sequences.
- `warn_on_low_modal::Bool=true`: set false to silence that warning.

Note: 
- If multiple characters are equally frequent at a position, it will arbitrarily choose one.
- Make sure to run `check_all_strings_same_length` before using this function 
    to ensure all strings are of equal length.

!!! warning "The consensus is not always the wild type"
    In a saturating or combinatorial mutagenesis library the wild-type residue
    can be a MINORITY at heavily mutated positions, so the per-column plurality
    vote returns a mutant residue instead. Measured on 69 ProteinGym datasets,
    the consensus differs from the true reference sequence in 3 of them, by
    Hamming distance 2 to 4.

    This matters beyond bookkeeping: the mutation encoding (`X_mut`) marks every
    position where a sequence differs from the consensus, so wherever the
    consensus is wrong the encoding INVERTS there. Variants carrying the true
    wild-type residue get marked as mutated, and the actual mutants get marked
    as unmutated.

    The `min_modal_freq` guard flags this. On those 69 datasets it fires on all
    three bad ones (modal frequencies 0.052, 0.078, 0.226) with one false alarm
    among the 66 good ones. When it fires, supply the real reference sequence
    instead of relying on the consensus.
"""
function get_consensus(strings::Vector{String}; min_modal_freq::Real=0.5,
                       warn_on_low_modal::Bool=true)
    isempty(strings) && throw(ArgumentError("Cannot compute consensus of empty vector"))
    
    # Check that all strings have the same length
    seq_length = length(strings[1])
    all(length(s) == seq_length for s in strings) || 
        throw(ArgumentError("All strings must be the same length"))
    seq_length = length(strings[1])

    # Find all unique characters across all strings
    unique_chars = Set{Char}()
    for string in strings
        for char in string
            push!(unique_chars, char)
        end
    end
    
    consensus_chars = Vector{Char}(undef, seq_length)
    modal_counts = Vector{Int}(undef, seq_length)
    
    # For each position, find the most frequent character
    for pos in 1:seq_length
        char_counts = Dict{Char, Int}()
        
        # Initialize counts for all unique characters
        for char in unique_chars
            char_counts[char] = 0
        end
        
        # Count characters at this position
        for string in strings
            char = string[pos]
            char_counts[char] += 1
        end
        
        # Find the most frequent character
        max_count = 0
        consensus_char = first(unique_chars)  # default fallback
        for (char, count) in char_counts
            if count > max_count
                max_count = count
                consensus_char = char
            end
        end
        
        consensus_chars[pos] = consensus_char
        modal_counts[pos] = max_count
    end

    if warn_on_low_modal
        n = length(strings)
        low = [(pos, modal_counts[pos] / n) for pos in 1:seq_length
               if modal_counts[pos] / n < min_modal_freq]
        if !isempty(low)
            shown = first(low, 10)
            @warn """
                Consensus may not be the wild type.
                At $(length(low)) of $seq_length positions the most frequent character
                accounts for less than $(min_modal_freq) of the $n sequences, which is
                what a saturating or combinatorial library looks like. Where that
                happens the consensus can pick a MUTANT residue as the reference, and
                the mutation encoding inverts at those positions.
                Supply the true reference sequence if you have one.""" positions_below =
                [p for (p, _) in shown] frequencies = [round(f, digits=3) for (_, f) in shown] n_below =
                length(low) min_frequency = round(minimum(f for (_, f) in low), digits=4)
        end
    end

    return String(consensus_chars)
end

"""
    consensus_modal_frequencies(strings::Vector{String}) -> Vector{Float64}

Fraction of sequences carrying the most frequent character, per position.

Use this to check whether `get_consensus` can be trusted as the wild type. A
value near 1.0 means that position is rarely mutated and the consensus is almost
certainly the wild-type residue. A value below 0.5 means the position is mutated
in most of the library, so the plurality vote may have selected a mutant.

```julia
freqs = consensus_modal_frequencies(strings)
minimum(freqs) < 0.5 && @warn "consensus unreliable" argmin(freqs)
```
"""
function consensus_modal_frequencies(strings::Vector{String})
    isempty(strings) && throw(ArgumentError("Cannot compute frequencies of empty vector"))
    seq_length = length(strings[1])
    all(length(s) == seq_length for s in strings) ||
        throw(ArgumentError("All strings must be the same length"))
    n = length(strings)
    freqs = Vector{Float64}(undef, seq_length)
    for pos in 1:seq_length
        counts = Dict{Char,Int}()
        for s in strings
            c = s[pos]
            counts[c] = get(counts, c, 0) + 1
        end
        freqs[pos] = maximum(values(counts)) / n
    end
    return freqs
end
