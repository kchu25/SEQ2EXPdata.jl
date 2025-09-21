
# Type markers for multiple dispatch
struct Nucleotide end
struct AminoAcid end
const TYPE_MAP = Dict(:Nucleotide => Nucleotide, :AminoAcid => AminoAcid)

# Fast lookup using direct indexing - returns the index of the nucleotide (1-based)
function get_nucleotide_index(nucleotide::Char)
    if nucleotide == 'A'
        return 1
    elseif nucleotide == 'C'
        return 2
    elseif nucleotide == 'G'
        return 3
    elseif nucleotide == 'T' || nucleotide == 'U'
        return 4
    else
        return 0  # Unknown nucleotides (including 'N')
    end
end

# Standard 20 amino acids in alphabetical order
const AMINO_ACID_LETTERS = [
    'A',  # Alanine
    'C',  # Cysteine  
    'D',  # Aspartic acid
    'E',  # Glutamic acid
    'F',  # Phenylalanine
    'G',  # Glycine
    'H',  # Histidine
    'I',  # Isoleucine
    'K',  # Lysine
    'L',  # Leucine
    'M',  # Methionine
    'N',  # Asparagine
    'P',  # Proline
    'Q',  # Glutamine
    'R',  # Arginine
    'S',  # Serine
    'T',  # Threonine
    'V',  # Valine
    'W',  # Tryptophan
    'Y'   # Tyrosine
]

# Nucleotide characters (including RNA)
const NUCLEOTIDE_LETTERS = Set(['A', 'C', 'G', 'T', 'U', 'N'])

# Amino acid characters as a set for fast lookup
const AMINO_ACID_SET = Set(AMINO_ACID_LETTERS)

# Mapping from amino acid letters to their indices (1-based)
const AMINO_ACID_TO_INDEX = Dict(
    amino_acid => index 
    for (index, amino_acid) in enumerate(AMINO_ACID_LETTERS)
)

# Helper function to validate sequence lengths
function validate_sequence_lengths(sequences::AbstractVector{String})
    sequence_lengths = length.(sequences)
    @assert length(unique(sequence_lengths)) == 1 "All sequences must have the same length"
    return first(sequence_lengths)  # Return the common length
end

"""
    sequences_to_tensor(sequences::AbstractVector{String}, ::Type{Nucleotide}; T=DEFAULT_FLOAT_TYPE)
    sequences_to_tensor(sequences::AbstractVector{String}, ::Type{AminoAcid}; T=DEFAULT_FLOAT_TYPE)

Convert a vector of biological sequences to a 4D tensor for batch processing using multiple dispatch.

# Arguments
- `sequences::AbstractVector{String}`: Vector of biological sequences to encode
- `::Type{Nucleotide}` or `::Type{AminoAcid}`: Sequence type for dispatch
- `T`: Element type for the output tensor (default: DEFAULT_FLOAT_TYPE)

# Returns
- `Array{T,4}`: A 4D tensor where:
  - **Nucleotides**: `channels x sequence_length x 1 x num_sequences` (4 x L x 1 x N)
  - **Amino acids**: `channels x sequence_length x 1 x num_sequences` (20 x L x 1 x N)

# Throws
- `AssertionError`: If sequences have different lengths
    validate_sequence_lengths(sequences)
# Examples
```julia
# For nucleotides (DNA/RNA)
dna_seqs = ["ATCG", "GCTA", "TTAA"]
dna_tensor = sequences_to_tensor(dna_seqs, Nucleotide)  # 4 x 4 x 1 x 3 tensor

# For amino acids
protein_seqs = ["ACDE", "FGHI", "KLMN"]  
protein_tensor = sequences_to_tensor(protein_seqs, AminoAcid)  # 20 x 4 x 1 x 3 tensor
```
"""

# Optimized batch processing - pre-allocate output tensor
function sequences_to_tensor(
    sequences::AbstractVector{String}, 
    ::Type{Nucleotide}; 
    T = Float32
)
    validate_sequence_lengths(sequences)
    
    num_sequences = length(sequences)
    seq_length = length(first(sequences))
    
    # Pre-allocate the entire tensor - much more efficient
    tensor = zeros(T, 4, seq_length, 1, num_sequences)
    
    @inbounds for (seq_idx, sequence) in enumerate(sequences)
        for (pos_idx, nucleotide) in enumerate(sequence)
            uppercase_nucleotide = uppercase(nucleotide)
            nucleotide_index = get_nucleotide_index(uppercase_nucleotide)
            
            # Only set the relevant position to 1 (like amino acids)
            if nucleotide_index > 0
                tensor[nucleotide_index, pos_idx, 1, seq_idx] = one(T)
            end
            # Unknown nucleotides remain zero
        end
    end
    
    return tensor
end

# Optimized amino acid batch processing
function sequences_to_tensor(
    sequences::AbstractVector{String}, 
    ::Type{AminoAcid}; 
    T = Float32
)
    validate_sequence_lengths(sequences)
    
    num_sequences = length(sequences)
    seq_length = length(first(sequences))
    num_amino_acids = length(AMINO_ACID_LETTERS)
    
    # Pre-allocate the entire tensor
    tensor = zeros(T, num_amino_acids, seq_length, 1, num_sequences)
    
    @inbounds for (seq_idx, sequence) in enumerate(sequences)
        for (pos_idx, amino_acid) in enumerate(sequence)
            uppercase_aa = uppercase(amino_acid)
            if haskey(AMINO_ACID_TO_INDEX, uppercase_aa)
                aa_index = AMINO_ACID_TO_INDEX[uppercase_aa]
                tensor[aa_index, pos_idx, 1, seq_idx] = one(T)
            end
            # Unknown amino acids remain zero
        end
    end
    
    return tensor
end

# Convenience method with default nucleotide behavior for backward compatibility
sequences_to_tensor(sequences::AbstractVector{String}; T = DEFAULT_FLOAT_TYPE) = 
    sequences_to_tensor(sequences, Nucleotide; T = T)

"""
    sequences_to_tensor_auto(sequences::AbstractVector{String}; T=Float32)

Automatically infer sequence type and convert to tensor.

# Arguments
- `sequences::AbstractVector{String}`: Vector of biological sequences
- `T`: Element type for the output tensor (default: Float32)

# Returns
- `Array{T,4}`: Encoded tensor with automatically inferred sequence type
- Throws `ArgumentError` if sequence type cannot be determined

# Examples
```julia
# Automatically detects DNA and encodes as nucleotides
dna_seqs = ["ATCG", "GCTA", "TTAA"]
dna_tensor = sequences_to_tensor_auto(dna_seqs)  # 4 x 4 x 1 x 3 tensor

# Automatically detects protein and encodes as amino acids
protein_seqs = ["ACDEFGHI", "KLMNPQRS"]  
protein_tensor = sequences_to_tensor_auto(protein_seqs)  # 20 x 8 x 1 x 2 tensor
```
"""
function sequences_to_tensor_auto(sequences::AbstractVector{String}; T = Float32)
    seq_type = infer_sequence_type(sequences)
    
    if seq_type === Nucleotide
        return sequences_to_tensor(sequences, Nucleotide; T = T)
    elseif seq_type === AminoAcid
        return sequences_to_tensor(sequences, AminoAcid; T = T)
    else
        throw(ArgumentError("Cannot infer sequence type - sequences contain non-standard biological characters"))
    end
end

"""
    infer_sequence_type(sequences::AbstractVector{String})

Automatically infer whether sequences are nucleotides or amino acids based on their character content.

# Arguments
- `sequences::AbstractVector{String}`: Vector of biological sequences

# Returns
- `Type{Nucleotide}`: If sequences contain only nucleotide characters (A, C, G, T, U, N)
- `Type{AminoAcid}`: If sequences contain amino acid characters beyond nucleotides
- `nothing`: If sequences contain characters not found in standard biological alphabets

# Examples
```julia
dna_seqs = ["ATCG", "GCTA", "TTAA"]
infer_sequence_type(dna_seqs)  # Returns Nucleotide

protein_seqs = ["ACDE", "FGHI", "KLMN"]  
infer_sequence_type(protein_seqs)  # Returns AminoAcid

mixed_seqs = ["ATCGX", "INVALID"]
infer_sequence_type(mixed_seqs)  # Returns nothing
```
"""
function infer_sequence_type(sequences::AbstractVector{String})
    # Get all unique characters from all sequences
    unique_chars = Set{Char}()
    for sequence in sequences
        for char in uppercase(sequence)
            push!(unique_chars, char)
        end
    end
    
    # Check nucleotides first since they're a subset of amino acids
    if issubset(unique_chars, NUCLEOTIDE_LETTERS)
        @info "Inferred sequence type: Nucleotide"
        return Nucleotide
    end
    
    # Check if all characters are amino acids
    if issubset(unique_chars, AMINO_ACID_SET)
        @info "Inferred sequence type: AminoAcid"
        return AminoAcid
    end
    
    # Contains characters not in standard biological alphabets
    @info "Could not infer sequence type - contains non-standard characters"
    return nothing
end