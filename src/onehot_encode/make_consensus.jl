
"""
    consensus_to_bitmatrix(consensus::String, ::Type{Nucleotide})
    consensus_to_bitmatrix(consensus::String, ::Type{AminoAcid})

Convert a biological consensus sequence to a bit matrix following alphabet order.

For nucleotides: 4 rows (A, C, G, T/U in order) × sequence_length columns
For amino acids: 20 rows (A-Y in alphabetical order) × sequence_length columns

# Arguments
- `consensus::String`: Consensus sequence with only valid biological characters
- `::Type{Nucleotide}` or `::Type{AminoAcid}`: Sequence type for dispatch

# Returns
- `BitMatrix`: A binary matrix where each column is the one-hot encoding of a position

# Throws
- `ArgumentError`: If consensus contains invalid characters (e.g., 'N' for nucleotides)

# Examples
```julia
# Nucleotide consensus (4 rows)
dna_consensus = "ATCG"
bit_mat = consensus_to_bitmatrix(dna_consensus, Nucleotide)
# Returns 4x4 BitMatrix:
# A: [1 0 0 0]
# C: [0 0 1 0]
# G: [0 0 0 1]
# T: [0 1 0 0]

# Amino acid consensus (20 rows)
protein_consensus = "ACDE"
bit_mat = consensus_to_bitmatrix(protein_consensus, AminoAcid)
# Returns 20x4 BitMatrix with one-hot encoding
```
"""
function consensus_to_bitmatrix(consensus::String, ::Type{Nucleotide})
    seq_length = length(consensus)
    bit_matrix = falses(4, seq_length)
    
    for (pos_idx, nucleotide) in enumerate(uppercase(consensus))
        # Validate that nucleotide is in the valid set
        if !(nucleotide in VALID_NUCLEOTIDES)
            throw(ArgumentError("Invalid nucleotide '$nucleotide' at position $pos_idx. Only A, C, G, T, U are allowed (no ambiguous bases like N)."))
        end
        
        nucleotide_index = get_nucleotide_index(nucleotide)
        bit_matrix[nucleotide_index, pos_idx] = true
    end
    
    return bit_matrix
end

function consensus_to_bitmatrix(consensus::String, ::Type{AminoAcid})
    seq_length = length(consensus)
    num_amino_acids = length(AMINO_ACID_LETTERS)
    bit_matrix = falses(num_amino_acids, seq_length)
    
    for (pos_idx, amino_acid) in enumerate(uppercase(consensus))
        # Validate that amino acid is in the valid set
        if !haskey(AMINO_ACID_TO_INDEX, amino_acid)
            throw(ArgumentError("Invalid amino acid '$amino_acid' at position $pos_idx. Only the 20 standard amino acids (A-Y) are allowed."))
        end
        
        aa_index = AMINO_ACID_TO_INDEX[amino_acid]
        bit_matrix[aa_index, pos_idx] = true
    end
    
    return bit_matrix
end

"""
    consensus_to_bitmatrix_auto(consensus::String)

Automatically infer sequence type and convert consensus to bit matrix.

# Arguments
- `consensus::String`: Consensus sequence

# Returns
- `BitMatrix`: Binary one-hot encoding matrix

# Examples
```julia
# Automatically detects DNA
dna_bit_mat = consensus_to_bitmatrix_auto("ATCG")  # 4x4 BitMatrix

# Automatically detects protein
protein_bit_mat = consensus_to_bitmatrix_auto("ACDE")  # 20x4 BitMatrix
```
"""
function consensus_to_bitmatrix_auto(consensus::String)
    seq_type = infer_sequence_type([consensus])
    
    if seq_type === Nucleotide
        return consensus_to_bitmatrix(consensus, Nucleotide)
    elseif seq_type === AminoAcid
        return consensus_to_bitmatrix(consensus, AminoAcid)
    else
        throw(ArgumentError("Cannot infer sequence type for consensus - contains non-standard biological characters"))
    end
end

"""
    make_mutation_encoding(sequences::Vector{String}, consensus::String, prefix_offset::Int; T::Type=Float64)

Create a sparse one-hot encoding that marks only positions where sequences differ from the consensus.

# Arguments
- `sequences`: Vector of sequences to encode
- `consensus`: Consensus sequence to compare against
- `prefix_offset`: Number of bases trimmed from the prefix (for adjusting consensus position)
- `T`: Element type for the output tensor (default: Float64)

# Returns
- A 4D tensor (channels × length × 1 × N) where 1s indicate mutations relative to consensus
  - For nucleotides: 4 channels (A, C, G, T/U)
  - For proteins: 20 channels (amino acids in alphabetical order)

# Details
Unlike standard one-hot encoding where every position has exactly one '1', mutation encoding
only marks positions that differ from the consensus sequence. This creates a much sparser
representation that emphasizes variation, which can be beneficial for representation learning
in mutagenesis studies.

# Example
```julia
seqs = ["ATCG", "ATCA", "ATGG"]
consensus = "ATCG"
mut_encoding = make_mutation_encoding(seqs, consensus, 0; T=Float32)
# Only positions differing from consensus will have 1s
```
"""
function make_mutation_encoding(sequences::Vector{String}, consensus::String, prefix_offset::Int; T::Type=Float64)
    if isempty(sequences)
        throw(ArgumentError("sequences cannot be empty"))
    end
    
    # Infer sequence type
    seq_type = infer_sequence_type(sequences)
    alphabet_size = seq_type == Nucleotide ? 4 : 20
    
    # Adjust consensus for any prefix trimming
    consensus_adjusted = if prefix_offset > 0 && length(consensus) > prefix_offset
        consensus[prefix_offset+1:end]
    else
        consensus
    end
    
    # Get dimensions
    seq_length = length(sequences[1])
    num_sequences = length(sequences)
    
    # Initialize output tensor (all zeros)
    tensor = zeros(T, alphabet_size, seq_length, 1, num_sequences)
    
    # Encode only mutations (positions different from consensus)
    for (seq_idx, seq) in enumerate(sequences)
        for (pos_idx, char) in enumerate(seq)
            # Get corresponding consensus position
            if pos_idx <= length(consensus_adjusted)
                consensus_char = consensus_adjusted[pos_idx]
                
                # Only encode if different from consensus
                if uppercase(char) != uppercase(consensus_char)
                    char_idx = if seq_type == Nucleotide
                        get_nucleotide_index(uppercase(char))
                    else
                        get(AMINO_ACID_TO_INDEX, uppercase(char), 0)
                    end
                    
                    if char_idx > 0
                        tensor[char_idx, pos_idx, 1, seq_idx] = one(T)
                    end
                end
            else
                # Position beyond consensus length - encode normally
                char_idx = if seq_type == Nucleotide
                    get_nucleotide_index(uppercase(char))
                else
                    get(AMINO_ACID_TO_INDEX, uppercase(char), 0)
                end
                
                if char_idx > 0
                    tensor[char_idx, pos_idx, 1, seq_idx] = one(T)
                end
            end
        end
    end
    
    return tensor
end
