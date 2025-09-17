# SEQ2EXPdata

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://kchu25.github.io/SEQ2EXPdata.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://kchu25.github.io/SEQ2EXPdata.jl/dev/)
[![Build Status](https://github.com/kchu25/SEQ2EXPdata.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/kchu25/SEQ2EXPdata.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/kchu25/SEQ2EXPdata.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/kchu25/SEQ2EXPdata.jl)

SEQ2EXPdata is a Julia package for organizing biological sequence data and their associated expression labels. It is suitable for DNA, RNA, or protein sequence datasets, and helps keep your data consistent and analysis-ready.

## What does it do?

- Stores your sequences and their expression labels together, so you don't have to juggle multiple arrays.
- Makes sure your data is consistent (all sequences the same length, labels match up, etc.).
- Lets you add feature names for your labels if you want.

## Quick Start

Here's how you might use SEQ2EXPdata in your own project:

```julia
using SEQ2EXPdata

# Simple example with one label per sequence
ds = SEQ2EXP_Dataset(["ATCG", "GGTA"], [1.2, 3.4])

# Example with multiple labels and feature names
# 3 sequences with 2 featuress
ds2 = SEQ2EXP_Dataset(
    ["ATCG", "GGTA", "CCAC"],
    [1.2 2.3 4.1; 
     3.4 4.5 1.2],
    feature_names=["exp1", "exp2"]
)

# The dataset displays nicely when shown
ds |> show
# Output: SEQ2EXP_Dataset with 2 sequences of length 4
#         Labels: Vector of length 2
#         No feature names provided.
```

## Documentation

Check out the [documentation](https://kchu25.github.io/SEQ2EXPdata.jl/dev/) for details on all the features.


