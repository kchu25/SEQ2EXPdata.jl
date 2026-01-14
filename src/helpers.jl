"""
    pad_sequences_to_maxlen(seqs::Vector{String}; max_len=nothing, padchar::Char = 'N', pad_dir::Symbol = :right)

Pad all sequences in the input vector to the maximum sequence length using the specified pad character (default 'N').
Returns a new vector of padded sequences.

# Arguments
- `seqs::Vector{String}`: Vector of sequences to pad
- `max_len`: Maximum length (default: maximum length in seqs)
- `padchar::Char`: Padding character (default: 'N')
- `pad_dir::Symbol`: Padding direction, either `:right` (default) or `:left`

# Examples
```julia
pad_sequences_to_maxlen(["ATCG", "AT"])           # "ATCG", "ATNN" (right padding)
pad_sequences_to_maxlen(["ATCG", "AT"], pad_dir=:left)  # "ATCG", "NNAT" (left padding)
```
"""
function pad_sequences_to_maxlen(seqs::Vector{String}; max_len=nothing, padchar::Char = 'N', pad_dir::Symbol = :right)
    if isnothing(max_len)
        maxlen = maximum(length.(seqs))
    end
    
    # Validate pad_dir
    if !(pad_dir in (:left, :right))
        throw(ArgumentError("pad_dir must be either :left or :right, got :$pad_dir"))
    end
    
    # Pad sequences based on direction
    if pad_dir == :right
        return [seq * repeat(string(padchar), maxlen - length(seq)) for seq in seqs]
    else  # :left
        return [repeat(string(padchar), maxlen - length(seq)) * seq for seq in seqs]
    end
end

"""
    get_most_common_length_indices(strings::Vector{String}; verbose::Bool=false)

Returns the indices of strings that have the most common length, without using StatsBase.

# Arguments
- `strings::Vector{String}`: Input vector of strings
- `verbose::Bool=false`: If true, prints statistics about the filtering

# Returns
- `Vector{Int}`: Indices of strings with the most common length
"""
function get_most_common_length_indices(strings::Vector{String}; verbose::Bool=false)
    # Calculate the length of each string
    lengths = length.(strings)
    
    # Count occurrences of each length manually
    length_counts = Dict{Int, Int}()
    for len in lengths
        length_counts[len] = get(length_counts, len, 0) + 1
    end
    
    # Find the most common length
    most_common_length = 0
    max_count = 0
    for (len, count) in length_counts
        if count > max_count
            max_count = count
            most_common_length = len
        end
    end
    
    # Get indices of strings that have the most common length
    indices = findall(len -> len == most_common_length, lengths)
    
    if verbose
        println("Most common length: ", most_common_length)
        println("Number of strings with this length: ", max_count)
        println("Total strings: ", length(strings))
        println("Filtered subset size: ", length(indices))
    end
    
    return Set(indices)
end
