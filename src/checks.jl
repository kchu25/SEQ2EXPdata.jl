
# Check if strings are of the same length
function check_all_strings_same_length(strings::Vector{String})
    lengths = length.(strings)
    return all(lengths .== lengths[1])
end

# Ensure number of strings matches the number of labels
function check_equal_strings_and_labels(
    strings::Vector{String}, labels::Union{Vector{T}, Matrix{T}}) where T <: Real
    return length(strings) == size(labels, ndims(labels))
end

# Ensure feature names are same length as the first dimension of labels
function check_feature_names_length(labels::Union{Vector{T}, Matrix{T}}, feature_names::Union{Vector{String}, Nothing}) where T <: Real
    if feature_names !== nothing
        if isa(labels, Matrix)
            @assert size(labels, 1) == length(feature_names) "Feature names length must match the number of rows in labels."
        elseif isa(labels, Vector)
            @info "length of feature_names $(length(feature_names))"
            @assert length(feature_names) == 1 "Feature names length must be 1."
        end
    end
end