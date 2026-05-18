# ABC Backend

## Purpose

`abc.cpp` is the public C++ backend entry point. It coordinates validation,
optional summary reduction, distance calculation, sample selection, parameter
transformation, regression adjustment, and result assembly.

## Main Functions And Classes

- `abcpp::abc()`
- `abcpp::AbcOptions`
- `abcpp::AbcResult`
- `abcpp::SummaryResult`
- `abcpp::summary()`

## Inputs

- Target summary statistics as a vector or matrix.
- Simulated parameter matrix.
- Simulated summary-statistic matrix.
- `AbcOptions` for method, tolerance, transforms, kernel, neural settings,
  ridge penalties, subset filtering, seed, and reduction.

## Outputs

- `AbcResult`, including unadjusted draws, adjusted draws, accepted summaries,
  weights, residuals, distances, region flags, metadata, and reduction info.
- `SummaryResult` for posterior summaries.

## Error Handling

The backend throws `std::invalid_argument` for incompatible dimensions,
invalid tolerance, empty lambda values, invalid transforms, invalid logit
bounds, and missing valid rows. Runtime failures such as zero accepted summary
variance use `std::runtime_error`.

## Numerical Assumptions

Distances are Euclidean after MAD scaling of summary statistics. Small epsilons
protect divisions, log residual variances, and inverse-like operations.

## Mutation

The public entry points copy inputs into local matrices before transformation
or scaling. Caller-owned inputs are not mutated.

## Randomness

Only the neural-network adjustment uses randomness. It is controlled by
`AbcOptions::seed`.

## R/Python Relationship

R and Python wrappers call only `abcpp::abc()` and `abcpp::summary()`.
Internal backend helpers are intentionally not exported as user-facing
R/Python functions.

## Relationship To R abc

The design is inspired by common ABC workflows and the R `abc::abc()`
interface. The backend is not a direct copy of every R `abc` user-facing
function.

## Known Differences

The neural-network path is implemented in C++ and does not call R `nnet`.
Pointwise draws can differ from R `abc`, especially for neural adjustment.

## Related Tests

- `tests/cpp/test_core.cpp`
- `tests/testthat/test-r-abc-alignment.R`
- `tests/python/test_abc.py`
