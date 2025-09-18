function Base.show(io::IO, dataset::SEQ2EXP_Dataset)
    println(io, "SEQ2EXP_Dataset with $(length(dataset.strings)) sequences of length $(length(dataset.strings[1]))")
    if isa(dataset.labels, Matrix)
        println(io, "Labels: Matrix of size $(size(dataset.labels))")
    else
        println(io, "Labels: Vector of length $(length(dataset.labels))")
    end
    if dataset.feature_names !== nothing
        println(io, "Feature names provided with length $(length(dataset.feature_names))")
    else
        println(io, "No feature names provided.")
    end
end



