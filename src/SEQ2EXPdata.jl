"""
    SEQ2EXPdata

A Julia package for handling biological sequence data and corresponding expression labels.

Provides the `SEQ2EXP_Dataset` type and utility functions for validation and manipulation of sequence-expression datasets.
"""
module SEQ2EXPdata

include("helpers.jl")
"""
    SEQ2EXP_Dataset{T<:Real}(strings, labels; feature_names=nothing)

A container for biological sequence data and corresponding expression labels.

# Arguments
- `strings::Vector{String}`: Vector of biological sequences (all must be the same length).
- `labels::Union{Vector{T}, Matrix{T}}`: Expression labels for each sequence. Can be a vector (single label per sequence) or a matrix (multiple labels per sequence).
- `feature_names::Union{Vector{String}, Nothing}`: Optional names for each feature (column) in `labels`.

# Examples
```julia
ds = SEQ2EXP_Dataset(["ATCG", "GGTA"], [1.2, 3.4])
ds2 = SEQ2EXP_Dataset(["ATCG", "GGTA"], [1.2 2.3; 3.4 4.5], feature_names=["exp1", "exp2"])
```
"""
struct SEQ2EXP_Dataset{T <: Real}
    strings::Vector{String}
    labels::Union{Vector{T}, Matrix{T}}
    feature_names::Union{Vector{String}, Nothing}
    consensus::Union{String, Nothing}
    most_common_length_indices::Union{Set{Int}, Nothing}

    function SEQ2EXP_Dataset(
        strings::Vector{String}, 
        labels::Union{Vector{T}, Matrix{T}}, 
        feature_names::Union{Vector{String}, Nothing}=nothing;
        GET_CONSENSUS::Bool=false,
        type::Type{<:Real}=T
        ) where T

        # Convert labels to the specified type if different from T
        if type != T
            converted_labels = labels isa Vector ? Vector{type}(labels) : Matrix{type}(labels)
        else
            converted_labels = labels
        end

        most_common_length_indices = nothing
        consensus = nothing
        
        if !check_all_strings_same_length(strings)
            @info "Strings are of varying lengths. Apply padding."
            if GET_CONSENSUS
                most_common_length_indices = get_most_common_length_indices(strings; verbose=true)
                consensus = get_consensus(strings[collect(most_common_length_indices)])
            end
            strings = pad_sequences_to_maxlen(strings)
        else
            # All strings same length
            if GET_CONSENSUS
                consensus = get_consensus(strings)
            end
        end
            
        check_equal_strings_and_labels(strings, converted_labels) || 
            throw(ArgumentError("Number of strings must match number of labels."))
        if !isnothing(feature_names)
            check_feature_names_length(converted_labels, feature_names)
        end

        new{type}(strings, converted_labels, feature_names, consensus, most_common_length_indices)
    end
end




"""
    @seq2exp sequences labels [feature_names] [GET_CONSENSUS=false]

A convenient macro for creating SEQ2EXP_Dataset instances with cleaner syntax.

# Arguments
- `sequences`: Vector of biological sequences
- `labels`: Vector or Matrix of expression values  
- `feature_names` (optional): Vector of feature names
- `GET_CONSENSUS` (optional): Boolean flag to compute consensus sequence

# Examples
```julia
# Simple case
ds1 = @seq2exp ["ATCG", "GGTA"] [1.2, 3.4]

# With feature names
ds2 = @seq2exp ["ATCG", "GGTA"] [1.2 2.3; 3.4 4.5] ["exp1", "exp2"]

# With consensus computation
ds3 = @seq2exp ["ATCG", "ATCA"] [1.0, 2.0] nothing GET_CONSENSUS=true
```
"""
macro seq2exp(sequences, labels, feature_names=nothing, options...)
    # Parse keyword arguments
    kwargs = Expr[]
    for opt in options
        if isa(opt, Expr) && opt.head == :(=) && opt.args[1] == :GET_CONSENSUS
            push!(kwargs, Expr(:kw, :GET_CONSENSUS, esc(opt.args[2])))
        end
    end
    
    quote
        SEQ2EXP_Dataset($(esc(sequences)), $(esc(labels)), $(esc(feature_names)); $(kwargs...))
    end
end


include("checks.jl")
include("consensus.jl")
include("show.jl")
include("utils.jl")
include("onehot_encode/Onehot.jl")


export SEQ2EXP_Dataset, 
       @seq2exp,
       has_consensus, 
       get_consensus, 
       get_sequence_and_labels, 
       get_feature_names, 
       get_sequence_length, 
       get_feature_counts,
       OnehotSEQ2EXP_Dataset,
       get_feature_dimension,
       get_label_dimension,
       consensus_to_bitmatrix,
       consensus_to_bitmatrix_auto


end
