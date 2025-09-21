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
sequences = ["ATCG", "GGTA", "CCAC"]
measurements = [1.2 2.3 4.1;    # expression levels
                3.4 4.5 1.2]    # binding affinities

dataset = SEQ2EXP_Dataset(
    sequences, 
    measurements,
    feature_names=["expression", "binding_affinity"]
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
num_features = get_feature_counts(dataset)      # Number of label dimensions
```

## Machine Learning Integration

### One-Hot Encoding
```julia
# Convert to ML-ready format
onehot_dataset = OnehotSEQ2EXP_Dataset(dataset)

# Access one-hot encoded sequences (4D tensor: channels × length × 1 × N)
X = onehot_dataset.onehot_sequences  # For model input
y = onehot_dataset.raw_data.labels   # For model targets

# Display one-hot dataset
onehot_dataset
# Output: OnehotSEQ2EXP_Dataset with 3 sequences of length 4
#         One-hot tensor shape: (4, 4, 1, 3)
#         Labels: 2 features for 3 data points
#         Feature names: ["expression", "binding_affinity"]
```

### Integration with ML Frameworks
```julia
using Flux

# Create dataset and convert to one-hot
sequences = ["ATCG", "GGCG", "TTAG"]
labels = [1.2, 2.3, 3.1]
dataset = SEQ2EXP_Dataset(sequences, labels)
onehot_data = OnehotSEQ2EXP_Dataset(dataset)

# Use in Flux DataLoader
dataloader = Flux.DataLoader(
    (data=onehot_data.onehot_sequences, label=onehot_data.raw_data.labels),
    batchsize=32
)
```

## Use Cases

- **🧪 Mutagenesis studies**: Track sequence variants and their functional measurements
- **🔬 Protein engineering**: Store designed sequences with experimental validation data  
- **📈 Gene expression**: Associate promoter sequences with transcription levels
- **🧬 Binding studies**: Link DNA/RNA sequences to protein binding affinities
- **🤖 ML training**: Prepare sequence-function datasets for deep learning models

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
- `get_feature_counts(dataset)` - Number of label dimensions
- `has_consensus(dataset)` - Check if consensus exists
- `get_consensus(dataset)` - Retrieve consensus sequence

## Documentation

- [**User Guide**](https://kchu25.github.io/SEQ2EXPdata.jl/dev/) - Detailed usage examples and workflows
- [**API Reference**](https://kchu25.github.io/SEQ2EXPdata.jl/dev/api/) - Complete function documentation

## License

MIT License - see [LICENSE](LICENSE) file for details.