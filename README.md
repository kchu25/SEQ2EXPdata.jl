# SEQ2EXPdata

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://kchu25.github.io/SEQ2EXPdata.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://kchu25.github.io/SEQ2EXPdata.jl/dev/)
[![Build Status](https://github.com/kchu25/SEQ2EXPdata.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/kchu25/SEQ2EXPdata.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/kchu25/SEQ2EXPdata.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/kchu25/SEQ2EXPdata.jl)

SEQ2EXPdata is a Julia package for organizing biological sequence data and their associated real-valued (e.g. expression) labels. It is suitable for DNA, RNA, or protein sequence datasets, and helps keep your data consistent and analysis-ready.

## What does it do?

- Stores your sequences and their expression labels together, so you don't have to juggle multiple arrays.
- Makes sure your data is consistent (all sequences the same length, labels match up, etc.).
- Lets you add feature names for your labels if you want.
- Optionally computes consensus sequences from your sequence data; useful when e.g. the dataset is a mutagenesis study.

## Quick Start

Here's how you might use SEQ2EXPdata in your own project:

```julia
using SEQ2EXPdata

# Simple example with one label per sequence
ds = SEQ2EXP_Dataset(["ATCG", "GGTA"], [1.2, 3.4])

# Example with multiple labels and feature names
# 3 sequences with 2 features
ds2 = SEQ2EXP_Dataset(
    ["ATCG", "GGTA", "CCAC"],
    [1.2 2.3 4.1; 
     3.4 4.5 1.2],
    feature_names=["exp1", "exp2"]
)

# The dataset displays nicely when shown
ds2 |> show
# Output: SEQ2EXP_Dataset with 2 sequences of length 4
#         Labels: Matrix of size (2, 2)
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
nfeatures = get_feature_counts(ds2)
```


## Documentation

Check out the [documentation](https://kchu25.github.io/SEQ2EXPdata.jl/dev/) for details on all the features.


