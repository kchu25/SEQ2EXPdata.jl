# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.9]

### Changed
- `get_X` and `get_XY` now mirror the `.X` virtual field: when a consensus is present they
  return the **mutation encoding** (sparse, relative to consensus) instead of the standard
  one-hot tensor. Previously `get_X` always returned the standard one-hot, so it could
  silently disagree with `dataset.X`. Use `get_onehot` / `dataset.onehot_sequences` to always
  get the dense standard one-hot tensor.

### Added
- Exported the one-hot accessors so they work without qualification:
  `get_onehot`, `get_onehot_mut`, `get_X`, `get_Y`, `get_XY`, `get_X_dim`, `get_Y_dim`,
  `get_prefix_offset`, `get_label`, `get_label_names`.
- Documented **mutation encoding** in the README: how to enable it (`GET_CONSENSUS=true`),
  how to access it (`dataset.X_mut`, `get_onehot_mut`), how it differs from standard one-hot,
  and the relevant caveats (trimming alignment, ambiguous-character handling, `.X` behavior).
- Tests covering `get_X` / `.X` / `get_XY` consistency with and without a consensus.

[1.0.9]: https://github.com/kchu25/SEQ2EXPdata.jl/releases/tag/v1.0.9
