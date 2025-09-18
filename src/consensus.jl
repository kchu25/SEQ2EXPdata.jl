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

Note: 
- If multiple characters are equally frequent at a position, it will arbitrarily choose one.
- Make sure to run `check_all_strings_same_length` before using this function 
    to ensure all strings are of equal length.
"""
function get_consensus(strings::Vector{String})
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
    end
    
    return String(consensus_chars)
end
