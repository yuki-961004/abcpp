# Matrix Container

## Purpose

`matrix.cpp` implements a minimal row-major matrix container for the backend.

## Main Functions And Classes

- `abcpp::Matrix`
- `from_row_major()`
- `subset_rows()`

## Inputs

Row and column counts, row-major data vectors, and row indices.

## Outputs

Matrix objects, row vectors, column vectors, or row subsets.

## Error Handling

Out-of-range indexes throw `std::out_of_range`. Incompatible row-major data or
row assignment lengths throw `std::invalid_argument`.

## Numerical Assumptions

The container stores double values and does not impose numerical policy beyond
bounds checking.

## Mutation

Mutable element access and `set_row()` mutate the target matrix. Read helpers
return copies.

## Randomness

Matrix utilities are deterministic.

## R/Python Relationship

Rcpp and pybind11 bindings convert language arrays into `abcpp::Matrix`.

## Relationship To R abc

This is an internal C++ representation and has no direct R `abc` counterpart.

## Known Differences

The container is intentionally small and does not aim to replace Eigen, R
matrices, or NumPy arrays.

## Related Tests

- `tests/cpp/test_core.cpp`
