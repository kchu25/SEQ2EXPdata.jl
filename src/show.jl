function Base.show(io::IO, dataset::SEQ2EXP_Dataset)
    println(io, "SEQ2EXP_Dataset with $(length(dataset.strings)) sequences of length $(length(dataset.strings[1]))")
    if isa(dataset.labels, Matrix)
        num_features, num_sequences = size(dataset.labels)
        println(io, "Labels: $num_features features for $num_sequences data points")
    else
        println(io, "Labels: 1 feature for $(length(dataset.labels)) data points")
    end
    if dataset.feature_names !== nothing
        println(io, "Feature names provided with length $(length(dataset.feature_names))")
    else
        println(io, "No feature names provided.")
    end
end



