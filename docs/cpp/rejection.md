# Rejection ABC

## Purpose

Rejection ABC accepts simulations closest to the observed summary statistics
and returns their parameter values without regression adjustment.

## Main Functions And Classes

- `abcpp::abc()`
- Internal distance, region-selection, and accepted-matrix helpers in
  `Cpp/src/abc.cpp`

## Inputs

- Scaled simulated summary statistics.
- Scaled target summary statistics.
- Good-row flags after finite-value and subset filtering.
- Tolerance `tol`.

## Outputs

- Accepted parameter values in `AbcResult::unadj_values`.
- Accepted region flags in `AbcResult::region`.
- Distances in `AbcResult::distances`.
- Unit weights for accepted draws.

## Error Handling

Invalid tolerance values throw `std::invalid_argument`. If no simulation row is
valid or accepted, the backend throws.

## Numerical Assumptions

Selection is based on Euclidean distance after MAD scaling. Ties are truncated
in original row order to preserve deterministic behavior.

## Mutation

No caller-owned input is mutated.

## Randomness

Rejection ABC is deterministic.

## R/Python Relationship

Both frontends expose this path through `abc(..., method = "rejection")`.

## Relationship To R abc

The rejection workflow is aligned with the R `abc` interface when no summary
reduction is used.

## Known Differences

Rows removed by subset or non-finite filtering are never accepted, including
when `tol = 1`.

## Related Tests

- `tests/cpp/test_core.cpp`
- `tests/testthat/test-r-abc-alignment.R`
- `tests/python/test_abc.py`
