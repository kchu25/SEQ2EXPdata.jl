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

"""
    _resolve_reference(strings, wild_type) -> String

Reference sequence for the mutation encoding.

When `wild_type` is supplied it is validated and returned; the plurality vote is
not consulted. When it is `nothing` the consensus is computed as before, with
its low-modal-frequency warning.

Why supplying it matters: the consensus is a per-column plurality vote, and in a
saturating library the wild-type residue can be a minority. In
`SPG1_STRSG_Wu_2016` positions 265/266/267/280 are each mutated in ~95% of
149,360 variants, so every residue sits near 5% and the vote is noise — it
picked `W` at 5.3% over the true wild type `V` at 5.1%. The encoding then
inverts at those positions: variants carrying the real wild-type residue are
marked as mutated, and the common mutants are marked as wild type.
"""
function _resolve_reference(strings::Vector{String}, wild_type::Union{AbstractString,Nothing})
    wild_type === nothing && return get_consensus(strings)

    wt = String(wild_type)
    L = length(strings[1])
    length(wt) == L || throw(ArgumentError(
        "wild_type has length $(length(wt)) but the sequences have length $L"))

    # Alphabet check: a wild type built from a different alphabet (or a stray
    # gap/stop character) would encode every position as a mutation.
    seq_chars = Set{Char}()
    for s in strings, c in s; push!(seq_chars, c); end
    unknown = setdiff(Set(collect(wt)), seq_chars)
    isempty(unknown) || @warn "wild_type contains characters absent from the sequences" characters=sort(collect(unknown))

    # Sanity diagnostic: where does the supplied wild type disagree with the
    # plurality, and was the plurality trustworthy there? Disagreement at
    # low-modal-frequency positions is EXPECTED and is the whole point.
    # Widespread disagreement at high-frequency positions means the wrong
    # sequence was passed.
    freqs = consensus_modal_frequencies(strings)
    voted = get_consensus(strings; warn_on_low_modal=false)
    diff  = [i for i in 1:L if wt[i] != voted[i]]
    if !isempty(diff)
        suspicious = [i for i in diff if freqs[i] >= 0.5]
        @info "wild_type differs from the plurality vote" n_positions=length(diff) positions=first(diff, 10) modal_freq_there=[round(freqs[i], digits=3) for i in first(diff, 10)]
        isempty(suspicious) ||
            @warn """
                wild_type disagrees with the plurality at $(length(suspicious)) position(s)
                where the plurality was well supported (modal frequency >= 0.5).
                That is not the saturated-library signature; check that the right
                reference sequence was passed.""" positions=first(suspicious, 10)
    end
    return wt
end
