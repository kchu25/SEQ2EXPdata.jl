"""
    longest_common_prefix(sequences)

Find the longest common prefix shared by all sequences in the input array.

# Arguments
- `sequences`: An array of sequences (strings, arrays, or any indexable collections)

# Returns
- The longest common prefix as the same type as the input sequences
- If no common prefix exists, returns an empty sequence of the same type

# Examples
```julia
longest_common_prefix(["hello", "help", "helicopter"])  # returns "hel"
longest_common_prefix(["abc", "def"])                   # returns ""
longest_common_prefix([[1,2,3,4], [1,2,5,6]])         # returns [1,2]
```

# Notes
- The length of the returned prefix can be used as an "offset" to skip the common 
  beginning when processing the sequences
- Requires at least one sequence in the input array
- All sequences are compared character-by-character (or element-by-element)
"""
function longest_common_prefix(sequences)
    prefix = sequences[1]
    for seq in sequences[2:end]
        n = findfirst(i -> prefix[i] ≠ seq[i], 1:min(length(prefix), length(seq)))
        prefix = isnothing(n) ? prefix : prefix[1:n-1]
    end
    return prefix
end

"""
    longest_common_suffix(sequences)

Find the longest common suffix shared by all sequences in the input array.

# Arguments
- `sequences`: An array of sequences (strings, arrays, or any indexable collections)

# Returns
- The longest common suffix as the same type as the input sequences
- If no common suffix exists, returns an empty sequence of the same type

# Examples
```julia
longest_common_suffix(["testing", "running", "jumping"])  # returns "ing"
longest_common_suffix(["abc", "def"])                     # returns ""
longest_common_suffix([[1,2,3,4], [5,6,3,4]])           # returns [3,4]
```

# Notes
- Implemented by reversing all sequences, finding the common prefix of the reversed 
  sequences, then reversing the result
- The length of the returned suffix indicates how many characters/elements to 
  trim from the end of each sequence
"""
function longest_common_suffix(sequences)
    reversed_seqs = [reverse(seq) for seq in sequences]
    suffix = longest_common_prefix(reversed_seqs)
    return reverse(suffix)
end


"""
    trim_common_ends(sequences) -> (prefix_offset, trimmed_sequences)

Remove the longest common prefix and suffix from all sequences, returning the 
prefix offset and the unique middle portions.

# Arguments
- `sequences`: An array of sequences (strings, arrays, or any indexable collections)

# Returns
- `prefix_offset`: Integer indicating the length of the common prefix (offset to unique content)
- `trimmed_sequences`: An array of sequences with common prefix and suffix removed
- Each trimmed sequence contains only the portion that differs between sequences
- If sequences become empty after trimming, returns empty sequences

# Examples
```julia
trim_common_ends(["prefix_A_suffix", "prefix_B_suffix"])  
# returns (7, ["_A_", "_B_"])

trim_common_ends(["hello", "help", "helicopter"])         
# returns (3, ["lo", "p", "icopter"])

trim_common_ends([[1,2,3,4,5], [1,2,9,4,5]])           
# returns (2, [[3], [9]])
```

# Notes
- Combines `longest_common_prefix` and `longest_common_suffix` to isolate the 
  unique portions of each sequence
- Useful for finding the "core differences" between similar sequences
- The prefix offset indicates where the unique content begins in the original sequences
- The suffix length indicates how many elements were excluded from the end
- Use the prefix offset to map positions in trimmed sequences back to original sequences
"""
function trim_common_ends(sequences::Vector{String})
    prefix = longest_common_prefix(sequences)
    suffix = longest_common_suffix(sequences)
    plen, slen = length(prefix), length(suffix)
    prefix_offset, trimmed_sequences = plen, [seq[plen+1:end-slen] for seq in sequences]
    return prefix_offset, trimmed_sequences
end