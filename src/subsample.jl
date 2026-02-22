"""
    subsample(ds::SEQ2EXP_Dataset{T}; n::Int=3000, rng::AbstractRNG=Random.GLOBAL_RNG) -> SEQ2EXP_Dataset{T}

Create a subsampled version of a `SEQ2EXP_Dataset` by uniformly sampling sequences (and their
corresponding labels) without replacement.

If the dataset already has `n` or fewer sequences, the original dataset is returned unchanged.

# Arguments
- `ds::SEQ2EXP_Dataset{T}`: The dataset to subsample.
- `n::Int=3000`: Maximum number of sequences in the subsampled dataset.
- `rng::AbstractRNG=Random.GLOBAL_RNG`: Random number generator for reproducibility.

# Returns
A new `SEQ2EXP_Dataset{T}` with at most `n` sequences. Fields `consensus` and
`most_common_length_indices` are reconstructed via the constructor when applicable
(i.e. when `GET_CONSENSUS` was used in the original dataset).

# Examples
```julia
ds = SEQ2EXP_Dataset(["ATCG", "GGTA", "CCCC", "TTTT"], [1.0, 2.0, 3.0, 4.0])
ds_sub = subsample(ds; n=2)
length(ds_sub.strings) == 2
```
"""
function subsample(ds::SEQ2EXP_Dataset{T}; n::Int=3000, rng::AbstractRNG=Random.GLOBAL_RNG) where T
    num_seqs = length(ds.strings)

    # If already within the limit, return as-is
    if num_seqs <= n
        return ds
    end

    # Uniformly sample n indices without replacement
    selected_indices = sort(Random.randperm(rng, num_seqs)[1:n])

    # Subsample strings
    sub_strings = ds.strings[selected_indices]

    # Subsample labels (vector or matrix)
    if ds.labels isa Vector
        sub_labels = ds.labels[selected_indices]
    else
        # Matrix labels: columns correspond to sequences
        sub_labels = ds.labels[:, selected_indices]
    end

    # Determine whether consensus should be reconstructed
    had_consensus = ds.consensus !== nothing

    # Reconstruct via the constructor, which handles consensus & most_common_length_indices
    return SEQ2EXP_Dataset(sub_strings, sub_labels, ds.feature_names; GET_CONSENSUS=had_consensus)
end
