```@meta
CurrentModule = SEQ2EXPdata
```

# Constructing a `SEQ2EXP_Dataset`

A [`SEQ2EXP_Dataset`](@ref) pairs biological sequences with their expression
labels. This page lists **every** argument accepted by the constructor and
explains what it does.

## Signature

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

## Positional arguments

| Argument        | Type                                   | Required | Default   | Description |
|-----------------|----------------------------------------|----------|-----------|-------------|
| `strings`       | `Vector{String}`                       | ✅ yes   | —         | The biological sequences (DNA, RNA, or protein). If the sequences are **not** all the same length, they are automatically padded (see `pad_dir`). |
| `labels`        | `Vector{T}` or `Matrix{T}` (`T<:Real`) | ✅ yes   | —         | Expression labels. Use a `Vector` for a single label per sequence, or a `Matrix` for multiple features per sequence. |
| `feature_names` | `Vector{String}` or `Nothing`          | ❌ no    | `nothing` | Optional names for each feature (row) in a `Matrix` of `labels`. Its length must match the number of features. |

### `labels` shape

- **Vector** — one label per sequence. `length(labels)` must equal
  `length(strings)`.
- **Matrix** — multiple features per sequence. The **second dimension** (number
  of columns) must equal `length(strings)`; each column holds all features for
  one sequence. When `feature_names` is given, its length must match the number
  of rows (features).

## Keyword arguments

| Keyword         | Type            | Default            | Description |
|-----------------|-----------------|--------------------|-------------|
| `GET_CONSENSUS` | `Bool`          | `false`            | When `true`, compute and store a consensus sequence. If sequences vary in length, the consensus is computed only over the subset of sequences that have the **most common** length. |
| `type`          | `Type{<:Real}`  | inferred from `labels` | Target numeric type for `labels`. If different from the input element type, the labels are converted (e.g. `type=Float32`). |
| `pad_dir`       | `Symbol`        | `:right`           | Padding direction for variable-length sequences. Must be `:right` or `:left`; anything else throws an `ArgumentError`. Padding uses the character `'N'`. |

## Padding behavior

Padding only happens when the input sequences differ in length:

- All sequences are padded to the length of the **longest** sequence.
- The pad character is `'N'`.
- `pad_dir = :right` appends `'N'` (e.g. `"AT"` → `"ATNN"`).
- `pad_dir = :left` prepends `'N'` (e.g. `"AT"` → `"NNAT"`).

## Validation

The constructor throws an `ArgumentError` when:

- `pad_dir` is not `:left` or `:right`.
- The number of labels does not match the number of sequences.
- `feature_names` is provided but its length does not match the number of
  features in `labels`.

## Examples

```julia
using SEQ2EXPdata

# 1. Single label per sequence
ds = SEQ2EXP_Dataset(["ATCG", "GGTA"], [1.2, 3.4])

# 2. Multiple features with names
ds2 = SEQ2EXP_Dataset(
    ["ATCG", "GGTA"],
    [1.2 2.3; 3.4 4.5],
    feature_names = ["exp1", "exp2"],
)

# 3. Left-padding variable-length sequences
ds3 = SEQ2EXP_Dataset(["ATCG", "AT"], [1.0, 2.0], pad_dir = :left)
# sequences become "ATCG", "NNAT"

# 4. Force a specific label type and compute the consensus
ds4 = SEQ2EXP_Dataset(
    ["ATCG", "ATCA"],
    [1.0, 2.0];
    type = Float32,
    GET_CONSENSUS = true,
)
```

## Convenience macro

The [`@seq2exp`](@ref) macro provides a lighter-weight syntax:

```julia
ds1 = @seq2exp ["ATCG", "GGTA"] [1.2, 3.4]
ds2 = @seq2exp ["ATCG", "GGTA"] [1.2 2.3; 3.4 4.5] ["exp1", "exp2"]
ds3 = @seq2exp ["ATCG", "ATCA"] [1.0, 2.0] nothing GET_CONSENSUS=true
```

Note: the macro forwards `sequences`, `labels`, and `feature_names`, and
supports the `GET_CONSENSUS` keyword. Use the full constructor when you need
`type` or `pad_dir`.

## Docstring

```@docs
SEQ2EXP_Dataset
@seq2exp
```
