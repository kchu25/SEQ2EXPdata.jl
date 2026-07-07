# SEQ2EXPdata.jl

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

Requesting a consensus with `GET_CONSENSUS=true` also enables **mutation encoding** when the
data is one-hot encoded (see [Mutation Encoding](#mutation-encoding-sparse-relative-to-consensus) below).

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

### Mutation Encoding (sparse, relative to consensus)

For mutagenesis studies you can encode **only the positions that differ from a consensus
sequence**, instead of every base. This produces a much sparser tensor that emphasizes
variation, which can help representation learning.

**How to enable it:** request a consensus at construction time by passing `GET_CONSENSUS=true`
to `SEQ2EXP_Dataset` (or the `@seq2exp` macro). When a consensus is present, the
`OnehotSEQ2EXP_Dataset` constructor automatically computes the mutation encoding alongside the
standard one-hot tensor — no extra flag is needed:

```julia
sequences = ["ATCG", "ATCA", "ATGG"]
labels    = [1.0, 2.0, 3.0]

# Enable by requesting a consensus
dataset = SEQ2EXP_Dataset(sequences, labels; GET_CONSENSUS=true)
# or, with the macro:
# dataset = @seq2exp ["ATCG", "ATCA", "ATGG"] [1.0, 2.0, 3.0] nothing GET_CONSENSUS=true

onehot_dataset = OnehotSEQ2EXP_Dataset(dataset)

# Access the mutation encoding
onehot_dataset.X_mut                 # 4D tensor (alphabets × length × 1 × N), or `nothing`
onehot_dataset.onehot_sequences_mut  # same thing (the underlying field)
get_onehot_mut(onehot_dataset)       # accessor form
```

Without `GET_CONSENSUS=true` there is no consensus, so `onehot_dataset.X_mut` is `nothing`.

**How it differs from standard one-hot:** standard encoding sets exactly one `1` per position;
mutation encoding leaves a position all-zero when it matches the consensus and sets a single `1`
only at the *mutated* base.

Visual example — consensus `"ATCG"`, sequence `"ATGG"` (position 3 mutated C→G):
```
Position:  A  T  G  G
Channel 1: 0  0  0  0  (A)
Channel 2: 0  0  0  0  (C)
Channel 3: 0  0  1  0  (G)   <- only the mutated position is marked
Channel 4: 0  0  0  0  (T/U)
```

> **Important — what `.X` / `get_X` return:** when a mutation encoding is present, both
> `onehot_dataset.X` and `get_X(onehot_dataset)` return the **mutation** encoding (not the
> standard one-hot). If you specifically need the dense standard one-hot tensor, use
> `onehot_dataset.onehot_sequences` or `get_onehot(onehot_dataset)`.
>
> Two other caveats: [common prefixes/suffixes are trimmed first](#trimming-common-prefixessuffixes)
> (so the consensus is aligned to the trimmed region), and a mutation to an ambiguous/unknown
> character is silently skipped (not marked as a mutation).

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

### Constructing a `SEQ2EXP_Dataset`

```julia
SEQ2EXP_Dataset(
    strings,
    labels,
    feature_names = nothing;   # positional (optional)
    GET_CONSENSUS = false,     # keyword
    type = eltype(labels),     # keyword
    pad_dir = :right,          # keyword
)
```

**Positional arguments**

| Argument        | Type                                   | Required | Default   | Description |
|-----------------|----------------------------------------|----------|-----------|-------------|
| `strings`       | `Vector{String}`                       | yes      | —         | Biological sequences (DNA, RNA, or protein). If lengths vary, they are automatically padded (see `pad_dir`). |
| `labels`        | `Vector{T}` or `Matrix{T}` (`T<:Real`) | yes      | —         | Expression labels. `Vector` = one label per sequence; `Matrix` = multiple features per sequence. |
| `feature_names` | `Vector{String}` or `Nothing`          | no       | `nothing` | Optional names for each feature (row) of a `Matrix` of `labels`. Length must match the number of features. |

`labels` shape:
- **Vector** — `length(labels)` must equal `length(strings)`.
- **Matrix** — the **second dimension** (columns) must equal `length(strings)`; each column holds all features for one sequence. When `feature_names` is given, its length must equal the number of rows (features).

**Keyword arguments**

| Keyword         | Type            | Default                  | Description |
|-----------------|-----------------|--------------------------|-------------|
| `GET_CONSENSUS` | `Bool`          | `false`                  | Compute and store a consensus sequence. If sequences vary in length, the consensus is computed only over the subset with the **most common** length. Enables mutation encoding downstream. |
| `type`          | `Type{<:Real}`  | inferred from `labels`   | Target numeric type for `labels`; converts if different (e.g. `type=Float32`). |
| `pad_dir`       | `Symbol`        | `:right`                 | Padding direction for variable-length sequences. Must be `:right` or `:left`. Padding uses the character `'N'`. |

**Padding** happens only when sequences differ in length: all are padded to the longest length using `'N'`. `:right` appends (`"AT"` → `"ATNN"`); `:left` prepends (`"AT"` → `"NNAT"`).

**Validation** — the constructor throws an `ArgumentError` when:
- `pad_dir` is not `:left` or `:right`,
- the number of labels does not match the number of sequences, or
- `feature_names` is given but its length does not match the number of features.

```julia
# 1. Single label per sequence
SEQ2EXP_Dataset(["ATCG", "GGTA"], [1.2, 3.4])

# 2. Multiple features with names
SEQ2EXP_Dataset(["ATCG", "GGTA"], [1.2 2.3; 3.4 4.5], feature_names=["exp1", "exp2"])

# 3. Left-padding variable-length sequences  ->  "ATCG", "NNAT"
SEQ2EXP_Dataset(["ATCG", "AT"], [1.0, 2.0], pad_dir=:left)

# 4. Force a label type and compute the consensus
SEQ2EXP_Dataset(["ATCG", "ATCA"], [1.0, 2.0]; type=Float32, GET_CONSENSUS=true)
```

**Convenience macro** — `@seq2exp` forwards `sequences`, `labels`, `feature_names`, and the `GET_CONSENSUS` keyword. Use the full constructor when you need `type` or `pad_dir`.

```julia
@seq2exp sequences labels [feature_names] [GET_CONSENSUS=true]
```

### Utility Functions
- `get_sequence_and_labels(dataset)` - Extract data as tuple
- `get_feature_names(dataset)` - Get feature labels
- `get_sequence_length(dataset)` - Sequence length
- `get_feature_counts(dataset)` - Number of labels for each sequence
- `has_consensus(dataset)` - Check if consensus exists
- `get_consensus(dataset)` - Retrieve consensus sequence
- `get_onehot(onehot_dataset)` - Standard one-hot tensor
- `get_onehot_mut(onehot_dataset)` - Mutation encoding tensor (or `nothing` if no consensus)

## Documentation

- [**User Guide**](https://kchu25.github.io/SEQ2EXPdata.jl/dev/) - Detailed usage examples and workflows
- [**API Reference**](https://kchu25.github.io/SEQ2EXPdata.jl/dev/api/) - Complete function documentation

## License

MIT License - see [LICENSE](LICENSE) file for details.
