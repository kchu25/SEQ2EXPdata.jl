```@meta
CurrentModule = SEQ2EXPdata
```

# SEQ2EXPdata

SEQ2EXPdata is a Julia package for organizing biological sequence data and their associated expression labels. It is suitable for DNA, RNA, or protein sequence datasets, and helps keep your data consistent and analysis-ready.

## Overview

The main component of this package is the `SEQ2EXP_Dataset` type, which stores:
- Biological sequences as strings
- Corresponding expression labels (single values or multiple features per sequence)
- Optional feature names for multi-dimensional labels

## Quick Example

```julia
using SEQ2EXPdata

# Simple dataset with one label per sequence
ds = SEQ2EXP_Dataset(["ATCG", "GGTA"], [1.2, 3.4])

# Dataset with multiple features and names
# Note that the second dimension of the labels must always match the number of strings.
ds2 = SEQ2EXP_Dataset(
    ["ATCG", "GGTA"],
    [1.2 2.3; 3.4 4.5],
    feature_names=["exp1", "exp2"]
)
```

## API Reference

```@index
```

The constructor and the `@seq2exp` macro are documented in detail on the
[Constructing a Dataset](@ref "Constructing a `SEQ2EXP_Dataset`") page.

```@autodocs
Modules = [SEQ2EXPdata]
Filter = t -> t !== SEQ2EXPdata.SEQ2EXP_Dataset && t !== getfield(SEQ2EXPdata, Symbol("@seq2exp"))
```
