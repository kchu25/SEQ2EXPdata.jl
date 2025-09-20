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

"""
    get_feature_counts(dataset::SEQ2EXP_Dataset) -> Int

Return the number of features (columns) in the labels array.
"""
get_feature_counts(dataset::SEQ2EXP_Dataset) = 
    dataset.labels isa Vector ? 1 : size(dataset.labels, 1)

"""
    get_sequence_length(strings::Vector{String}) -> Int

Get the length of the sequences in the dataset.
"""
get_sequence_length(dataset::SEQ2EXP_Dataset) = length(dataset.strings[1])
