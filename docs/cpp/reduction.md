# Summary Reduction

## Purpose

`reduction.cpp` reduces high-dimensional summary statistics before distance
selection and regression adjustment.

## Main Functions And Classes

- `abcpp::reduce_summary_statistics()`
- `abcpp::ReducedSummary`
- `abcpp::ReductionInfo`
- `abcpp::ReductionOptions`

## Inputs

- Parameter matrix.
- Summary-statistic matrix.
- Target summary-statistic vector.
- Reduction method `None`, `PCA`, or `PLS`.
- Requested component count.

## Outputs

- Reduced summary matrix.
- Reduced target vector.
- Reduction metadata with method, component count, rotation, and center.

## Error Handling

Target and summary dimension mismatches throw `std::invalid_argument`.
Unsupported reduction methods also throw.

## Numerical Assumptions

PCA uses centered summary statistics and a Jacobi eigen decomposition. PLS uses
a compact iterative NIPALS-style routine and projects summaries through the
resulting weights and loadings.

## Mutation

Input matrices are copied before centering or deflation.

## Randomness

Reduction is deterministic.

## R/Python Relationship

Both frontends expose reduction only through `abc()` arguments `reduction`,
`reduce`, and `ncomp`.

## Relationship To R abc

PCA and PLS are abcpp extensions for matrix-like summary workflows and are not
claimed as a direct copy of all R `abc` functionality.

## Known Differences

The implementation is intentionally lightweight and C++ native.

## Related Tests

- `tests/cpp/test_core.cpp`
- `tests/testthat/test-reduction.R`
- `tests/python/test_reduction.py`
