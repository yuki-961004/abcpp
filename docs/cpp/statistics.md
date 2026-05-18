# Statistics Utilities

## Purpose

`statistics.cpp` provides small numerical helpers used by ABC scaling,
summaries, weights, and posterior reporting.

## Main Functions And Classes

- `median()`
- `quantile_type7()`
- `mad()`
- `mean()`
- `weighted_mean()`
- `sample_sd()`
- `column_mads()`
- `kernel_mode()`

## Inputs

Vectors or matrices of numeric values, with optional weights or row-keep flags.

## Outputs

Scalar summaries or per-column vectors.

## Error Handling

Length mismatches for weighted inputs throw `std::invalid_argument`.
Empty or all-non-finite inputs generally return `NaN` or zero where that
behavior is useful for scaling safeguards.

## Numerical Assumptions

Quantiles follow R type 7. MAD uses the usual 1.4826 consistency multiplier.
Mode estimation uses a simple Gaussian-kernel grid search.

## Mutation

Inputs are copied where sorting or filtering is required. Caller data is not
mutated.

## Randomness

Statistics utilities are deterministic.

## R/Python Relationship

These helpers are internal C++ functions and are not exported as R/Python user
functions.

## Relationship To R abc

The scaling and summary behavior follows common R statistical conventions
where practical.

## Known Differences

Kernel-mode estimation is a compact backend utility rather than an exported R
API.

## Related Tests

- `tests/cpp/test_core.cpp`
