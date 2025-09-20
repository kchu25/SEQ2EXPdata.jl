# SEQ2EXPdata

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://kchu25.github.io/SEQ2EXPdata.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://kchu25.github.io/SEQ2EXPdata.jl/dev/)
[![Build Status](https://github.com/kchu25/SEQ2EXPdata.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/kchu25/SEQ2EXPdata.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/kchu25/SEQ2EXPdata.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/kchu25/SEQ2EXPdata.jl)

SEQ2EXPdata is a Julia package for organizing biological sequence data with their associated numerical labels (e.g., expression levels, binding affinities, or other measurements). It works with DNA, RNA, or protein sequences and ensures your data stays consistent and analysis-ready.

## What does it do?

- Stores your sequences and their expression labels together, so you don't have to juggle multiple arrays.
- Makes sure your data is consistent (all sequences the same length, labels match up, etc.).
- Lets you add feature names for your labels if you want.
- Optionally computes consensus sequences from your sequence data; useful when e.g. the dataset is a mutagenesis study.

## Quick Start

Here's how you might use SEQ2EXPdata in your own project:

```julia
using SEQ2EXPdata

""" Scalar-valued example: mapping DNA sequences to their expression values.
Each sequence has one corresponding numerical label:
- DNA sequence "ATCG" maps to expression value 1.2
- DNA sequence "GGTA" maps to expression value 3.4
"""
ds = SEQ2EXP_Dataset(["ATCG", "GGTA"], [1.2, 3.4])

""" Vector-valued example with named features for each sequence
"ATCG" has exp1=1.2 and exp2=3.4
"GGTA" has exp1=2.3 and exp2=4.5  
"CCAC" has exp1=4.1 and exp2=1.2 """
ds2 = SEQ2EXP_Dataset(
    ["ATCG", "GGTA", "CCAC"],
    [1.2 2.3 4.1; 
     3.4 4.5 1.2],
    feature_names=["exp1", "exp2"]
)

# The dataset displays nicely when shown
ds2 |> show
# Output: SEQ2EXP_Dataset with 3 sequences of length 4
#         Labels: 2 features for 3 data points
#         Feature names provided with length 2

# You can also create datasets with consensus sequences
ds3 = SEQ2EXP_Dataset(
    ["ATCG", "ATCA", "ATGG"], 
    [1.0, 2.0, 3.0]; 
    GET_CONSENSUS=true
)

# Check if consensus exists and retrieve it
has_consensus(ds3)  # returns true
get_consensus(ds3)  # returns "ATCG" (most frequent at each position)
```

## @seq2exp Macro

For more concise dataset creation, you can use the `@seq2exp` macro:

```julia
# Simple case - equivalent to SEQ2EXP_Dataset(["ATCG", "GGTA"], [1.2, 3.4])
ds_macro1 = @seq2exp ["ATCG", "GGTA"] [1.2, 3.4]

# With feature names - equivalent to above ds2 example
ds_macro2 = @seq2exp ["ATCG", "GGTA", "CCAC"] [1.2 2.3 4.1; 3.4 4.5 1.2] ["exp1", "exp2"]

# With consensus computation
ds_macro3 = @seq2exp ["ATCG", "ATCA", "ATGG"] [1.0, 2.0, 3.0] nothing GET_CONSENSUS=true

# To see what the macro expands to (useful for debugging):
# @macroexpand @seq2exp ["ATCG", "GGTA"] [1.2, 3.4]
```

## Utility Functions

You can access the underlying data and metadata easily:

```julia
# Get sequences and labels as a tuple
seqs, labs = get_sequence_and_labels(ds2)

# Get feature names (or nothing if not provided)
fnames = get_feature_names(ds2)

# Get the length of the sequences
len = get_sequence_length(ds2)

# Get the number of features (columns) in the labels
nfeatures = get_feature_counts(ds2)  # 1 for vector labels, number of rows for matrix labels
```


## Documentation

Check out the [documentation](https://kchu25.github.io/SEQ2EXPdata.jl/dev/) for details on all the features.

## One-hot Encoding

You can convert a `SEQ2EXP_Dataset` to a one-hot encoded dataset for machine learning workflows:

```julia
using SEQ2EXPdata
# ... create your SEQ2EXP_Dataset as above ...
seqs = ["ATCG", "GGTA"]
labels = [1.0, 2.0]
ds = SEQ2EXP_Dataset(seqs, labels)

ods = OnehotSEQ2EXP_Dataset(ds)
# ods.onehot_sequences is a 4D tensor (channels × length × 1 × N)
# ods.raw_data is the original dataset

# Show the one-hot encoded dataset
ods |> show
# Output: OnehotSEQ2EXP_Dataset with 2 sequences of length 4
#         One-hot tensor shape: (4, 4, 1, 2)
#         Labels: 1 feature for 2 data points
#         No feature names provided.
```


