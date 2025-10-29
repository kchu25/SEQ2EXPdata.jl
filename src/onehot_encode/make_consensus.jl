
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
