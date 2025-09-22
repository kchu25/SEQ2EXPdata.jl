include("encode.jl")
include("trim.jl")
"""
    OnehotSEQ2EXP_Dataset{T}(raw_data::SEQ2EXP_Dataset{T})

A container for a sequence-expression dataset and its one-hot encoded representation.

# Fields
- `raw_data::SEQ2EXP_Dataset{T}`: The original dataset with sequences and labels.
- `onehot_sequences::AbstractArray{T, 4}`: The one-hot encoded tensor of the sequences (channels × length × 1 × N).

# Example
```julia
seqs = ["ATCG", "GGTA"]
labels = [1.0, 2.0]
ds = SEQ2EXP_Dataset(seqs, labels)
ods = OnehotSEQ2EXP_Dataset(ds)
```
"""
struct OnehotSEQ2EXP_Dataset{T}
    raw_data::SEQ2EXP_Dataset
    onehot_sequences::AbstractArray{T, 4} # TODO: use BitMatrix?
    prefix_offset::Int # For trimming, if needed
    X_dim::Tuple{Int, Int}  # (number of alphabets, length)
    Y_dim::Int # Number of label features
    
    # Constructor that infers T from raw_data's type parameter
    function OnehotSEQ2EXP_Dataset(raw_data::SEQ2EXP_Dataset{T}; trim=true) where {T<:AbstractFloat}

        prefix_offset, strs2encode = 0, raw_data.strings;
        if trim
            prefix_offset, strs2encode = trim_common_ends(strs2encode)
        end

        onehot_sequences = sequences_to_tensor_auto(strs2encode; T=T)
        X_dim = (size(onehot_sequences, 1), size(onehot_sequences, 2))
        Y_dim = ndims(raw_data.labels) == 1 ? 1 : size(raw_data.labels, 1)

        new{T}(raw_data, onehot_sequences, prefix_offset, X_dim, Y_dim)
    end
end


"""
    Base.getproperty(dataset::OnehotSEQ2EXP_Dataset, sym::Symbol)

Allow dot-access to `X` and `Y` as virtual fields for a `OnehotSEQ2EXP_Dataset`.

- `ods.X` returns the one-hot encoded tensor (same as `ods.onehot_sequences`).
- `ods.Y` returns the label array (same as `ods.raw_data.labels`).
- All other fields are accessed as usual.

This enables convenient and familiar ML-style access to features and labels without storing redundant fields.
"""
function Base.getproperty(dataset::OnehotSEQ2EXP_Dataset, sym::Symbol)
    if sym === :X
        return dataset.onehot_sequences
    elseif sym === :Y
        return dataset.raw_data.labels
    else
        return getfield(dataset, sym)
    end
end

# Accessors
get_onehot(dataset::OnehotSEQ2EXP_Dataset) = dataset.onehot_sequences
get_label(dataset::OnehotSEQ2EXP_Dataset) = dataset.raw_data.labels
get_label_names(dataset::OnehotSEQ2EXP_Dataset) = dataset.raw_data.feature_names

# Convenient accessors for features (X) and labels (Y)
get_X(dataset::OnehotSEQ2EXP_Dataset) = dataset.onehot_sequences
get_Y(dataset::OnehotSEQ2EXP_Dataset) = dataset.raw_data.labels
get_XY(dataset::OnehotSEQ2EXP_Dataset) = (get_X(dataset), get_Y(dataset))

# Dimensions
get_X_dim(dataset::OnehotSEQ2EXP_Dataset) = dataset.X_dim
get_Y_dim(dataset::OnehotSEQ2EXP_Dataset) = dataset.Y_dim

# Prefix offset
get_prefix_offset(dataset::OnehotSEQ2EXP_Dataset) = dataset.prefix_offset

"""
    Base.show(io::IO, dataset::OnehotSEQ2EXP_Dataset)

Custom display for `OnehotSEQ2EXP_Dataset`.

Prints the number and length of sequences, the shape of the one-hot tensor, label information, and feature names if available.
"""
function Base.show(io::IO, dataset::OnehotSEQ2EXP_Dataset)
    nseq = length(dataset.raw_data.strings)
    seq_len = length(dataset.raw_data.strings[1])
    println(io, "OnehotSEQ2EXP_Dataset with $nseq sequences of length $seq_len")
    # Show onehot tensor shape
    println(io, "One-hot tensor shape: ", size(dataset.onehot_sequences))
    # Show label info if available
    if hasproperty(dataset.raw_data, :labels)
        labels = dataset.raw_data.labels
        println(io, "Label array shape: ", size(labels))
        if isa(labels, Matrix)
            num_features, num_sequences = size(labels)
            println(io, "Labels: $num_features features for $num_sequences data points")
        else
            println(io, "Labels: 1 feature for $(length(labels)) data points")
        end
    else
        println(io, "No labels field in raw_data.")
    end
    # Show feature names if available
    if hasproperty(dataset.raw_data, :feature_names) && dataset.raw_data.feature_names !== nothing
        println(io, "Feature names provided with length $(length(dataset.raw_data.feature_names))")
    else
        println(io, "No feature names provided.")
    end
end