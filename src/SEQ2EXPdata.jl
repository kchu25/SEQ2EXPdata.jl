"""
    SEQ2EXPdata

A Julia package for handling biological sequence data and corresponding expression labels.

Provides the `SEQ2EXP_Dataset` type and utility functions for validation and manipulation of sequence-expression datasets.
"""
module SEQ2EXPdata

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

    function SEQ2EXP_Dataset(
        strings::Vector{String}, 
        labels::Union{Vector{T}, Matrix{T}}, 
        feature_names::Union{Vector{String}, Nothing}=nothing;
        GET_CONSENSUS=false
        ) where T

        check_all_strings_same_length(strings) || throw(ArgumentError("All strings must be of the same length."))
        check_equal_strings_and_labels(strings, labels) || 
            throw(ArgumentError("Number of strings must match number of labels."))
        check_feature_names_length(labels, feature_names)

        consensus = GET_CONSENSUS ? get_consensus(strings) : nothing
        new{T}(strings, labels, feature_names, consensus)
    end
end


include("checks.jl")
include("consensus.jl")
include("show.jl")

"""
    has_consensus(ds::SEQ2EXP_Dataset) -> Bool

Check if the dataset has a consensus sequence.
"""
has_consensus(ds::SEQ2EXP_Dataset) = ds.consensus !== nothing

"""
    get_consensus(ds::SEQ2EXP_Dataset) -> String

Get the consensus sequence from the dataset. Throws an error if no consensus exists.
"""
function get_consensus(ds::SEQ2EXP_Dataset) 
    has_consensus(ds) || throw(ArgumentError("Dataset does not have a consensus sequence."))
    return ds.consensus
end

"""
    get_sequence_and_labels(dataset::SEQ2EXP_Dataset) -> (Vector{String}, Union{Vector, Matrix})

Return the sequences and labels as a tuple.
"""
get_sequence_and_labels(dataset::SEQ2EXP_Dataset) = (dataset.strings, dataset.labels)

"""
    get_feature_names(dataset::SEQ2EXP_Dataset) -> Union{Vector{String}, Nothing}

Get the feature names from the dataset, or `nothing` if not provided.
"""
get_feature_names(dataset::SEQ2EXP_Dataset) = dataset.feature_names


export SEQ2EXP_Dataset, has_consensus, get_consensus, get_sequence_and_labels, get_feature_names

end
