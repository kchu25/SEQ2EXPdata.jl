# SEQ2EXPdata.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://kchu25.github.io/SEQ2EXPdata.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://kchu25.github.io/SEQ2EXPdata.jl/dev/)
[![Build Status](https://github.com/kchu25/SEQ2EXPdata.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/kchu25/SEQ2EXPdata.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/kchu25/SEQ2EXPdata.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/kchu25/SEQ2EXPdata.jl)

**Structured biological sequence data with associated numerical measurements.**

SEQ2EXPdata is a Julia package for organizing biological sequence data with their associated numerical labels (e.g., expression levels, binding affinities, or other measurements). It works with DNA, RNA, or protein sequences and ensures your data stays consistent and analysis-ready.

## What does it do?

- Stores your sequences and their expression labels together, so you don't have to juggle multiple arrays.
- Makes sure your data is consistent (all sequences the same length, labels match up, etc.).
- Lets you add feature names for your labels if you want.
- Optionally computes consensus sequences from your sequence data; useful when e.g. the dataset is a mutagenesis study.

## Installation

```julia
using Pkg
Pkg.add("SEQ2EXPdata")
```

## Quick Start

### Single-Target Measurements
```julia
using SEQ2EXPdata

# DNA sequences with expression levels
sequences = ["ATCG", "GGTA", "CCAC"]
expression_levels = [1.2, 3.4, 2.1]

dataset = SEQ2EXP_Dataset(sequences, expression_levels)
```

### Multi-Target Measurements 
```julia
# Multiple measurements per sequence
# columns = responses/labels for each sequence
sequences = ["ATCG", "GGTA", "CCAC"]
measurements = [1.2 2.3 4.1;    # free energies
                3.4 4.5 1.2]    # binding affinities

dataset = SEQ2EXP_Dataset(
    sequences, 
    measurements,
    feature_names=["free energy", "binding_affinity"]
)

# Display dataset info
dataset
# Output: SEQ2EXP_Dataset with 3 sequences of length 4
#         Labels: 2 features for 3 data points
#         Feature names provided with length 2
```

### Consensus Sequences
```julia
# Useful for mutagenesis studies
mutant_sequences = ["ATCG", "ATCA", "ATGG"]
fitness_scores = [1.0, 2.0, 3.0]

dataset = SEQ2EXP_Dataset(
    mutant_sequences, 
    fitness_scores; 
    GET_CONSENSUS=true
)

has_consensus(dataset)  # true
get_consensus(dataset)  # "ATCG" (most frequent nucleotide per position)
```

## Concise Syntax with @seq2exp Macro

```julia
# Equivalent to SEQ2EXP_Dataset constructor calls
ds1 = @seq2exp ["ATCG", "GGTA"] [1.2, 3.4]

ds2 = @seq2exp ["ATCG", "GGTA", "CCAC"] [1.2 2.3 4.1; 3.4 4.5 1.2] ["exp", "binding"]

ds3 = @seq2exp ["ATCG", "ATCA", "ATGG"] [1.0, 2.0, 3.0] nothing GET_CONSENSUS=true
```

## Data Access

```julia
# Extract sequences and labels
sequences, labels = get_sequence_and_labels(dataset)

# Get metadata
feature_names = get_feature_names(dataset)      # Vector{String} or nothing
sequence_length = get_sequence_length(dataset)  # Integer
num_features = get_feature_counts(dataset)      # Number of labels for each sequence
```
## Machine Learning Integration

### One-Hot Encoding

SEQ2EXPdata converts biological sequences into machine learning-ready tensors using standard one-hot encoding:

```julia
# Create dataset
sequences = ["ATCG", "GGCG"] 
labels = [1.2, 2.3]
dataset = SEQ2EXP_Dataset(sequences, labels)

# Convert to one-hot encoding
onehot_dataset = OnehotSEQ2EXP_Dataset(dataset)
```

**Encoding scheme:**
- **DNA/RNA**: number of alphabets = 4 (A, C, G, T/U)
- **Proteins**: number of alphabets = 20 (standard amino acids, alphabetical order)
- **Output**: 4D tensor `(number of alphabets × sequence_length × 1 × num_sequences)`

**Visual example for DNA sequence "ATCG":**
```
Position:  A  T  C  G
Channel 1: 1  0  0  0  (A)
Channel 2: 0  0  1  0  (C) 
Channel 3: 0  0  0  1  (G)
Channel 4: 0  1  0  0  (T/U)
```

```julia
# Access the data
onehot_dataset.X   # Input tensor for your model (virtual field)
onehot_dataset.Y   # Target values (virtual field)

# Or, use accessors
X = get_X(onehot_dataset)
Y = get_Y(onehot_dataset)
X, Y = get_XY(onehot_dataset)

# Get dimensions
get_X_dim(onehot_dataset) # The shape of each encoded string, e.g. (4, 100) for a onehot encoded nucleotide string of length 100.
get_Y_dim(onehot_dataset) # Equal to `get_feature_counts`
```

### Trimming Common Prefixes/Suffixes

In mutagenesis studies, sequences often share a common prefix and/or suffix. The `OnehotSEQ2EXP_Dataset` constructor trims these by default, so only the variable region is one-hot encoded (while storing the prefix offset for reference):

```julia
seqs    = ["AAATCGGG", "AAAGGTGG", "AAACCCGG"]  # Common prefix 'AAA', suffix 'GG'
labels  = [1.0, 2.0, 3.0]
dataset = SEQ2EXP_Dataset(seqs, labels)

onehot_dataset = OnehotSEQ2EXP_Dataset(dataset; trim=true)  # trim=true by default
get_X_dim(onehot_dataset)         # (4, 3) -- only the variable region is encoded
get_prefix_offset(onehot_dataset) # 3 (number of trimmed prefix bases)
```

This makes downstream ML models focus on the mutagenized region, while still allowing you to recover the original sequence coordinates if needed.


### Integration with ML Frameworks
```julia
using Flux

# Create dataset and convert to one-hot
sequences = ["ATCG", "GGCG", "TTAG"]
labels = [1.2, 2.3, 3.1]
dataset = SEQ2EXP_Dataset(sequences, labels)
onehot_dataset = OnehotSEQ2EXP_Dataset(dataset)

# Use in Flux DataLoader
dataloader = Flux.DataLoader(
    get_XY(onehot_dataset),
    batchsize=32
)
```

## Use Cases

- **Mutagenesis studies**: Track sequence variants and their functional measurements
- **Protein engineering**: Store designed sequences with experimental validation data  
- **Gene expression**: Associate promoter sequences with transcription levels
- **Binding studies**: Link DNA/RNA sequences to protein binding affinities
- **ML training**: Prepare sequence-function datasets for deep learning models

## API Reference

### Core Types
- `SEQ2EXP_Dataset` - Main data structure for sequences and labels
- `OnehotSEQ2EXP_Dataset` - One-hot encoded version for ML workflows

### Constructors
- `SEQ2EXP_Dataset(sequences, labels; feature_names=nothing, GET_CONSENSUS=false)`
- `@seq2exp sequences labels [feature_names] [GET_CONSENSUS=true]`

### Utility Functions
- `get_sequence_and_labels(dataset)` - Extract data as tuple
- `get_feature_names(dataset)` - Get feature labels
- `get_sequence_length(dataset)` - Sequence length
- `get_feature_counts(dataset)` - Number of labels for each sequence
- `has_consensus(dataset)` - Check if consensus exists
- `get_consensus(dataset)` - Retrieve consensus sequence

## Documentation

- [**User Guide**](https://kchu25.github.io/SEQ2EXPdata.jl/dev/) - Detailed usage examples and workflows
- [**API Reference**](https://kchu25.github.io/SEQ2EXPdata.jl/dev/api/) - Complete function documentation

## License

MIT License - see [LICENSE](LICENSE) file for details.
