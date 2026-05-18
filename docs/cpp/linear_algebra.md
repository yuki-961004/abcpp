# Linear Algebra Utilities

## Purpose

`linear_algebra.cpp` provides the small dense matrix operations needed by the
backend without adding a heavy runtime dependency.

## Main Functions And Classes

- `transpose()`
- `multiply()`
- `add_intercept()`
- `solve_linear_system()`
- `inverse()`
- `weighted_least_squares()`
- `predict()`

## Inputs

`abcpp::Matrix` objects, vectors, and regression weights.

## Outputs

Matrices or vectors produced by linear algebra and regression operations.

## Error Handling

Shape mismatches throw `std::invalid_argument`. Singular systems are lightly
regularized and can throw `std::runtime_error` if still singular.

## Numerical Assumptions

Gaussian elimination with pivoting is used for small systems. Weighted least
squares adds a small diagonal stabilizer.

## Mutation

Solvers take matrix arguments by value when they need to mutate working state.
Caller inputs are not mutated.

## Randomness

Linear algebra utilities are deterministic.

## R/Python Relationship

These utilities are internal and are reached only through `abc()`.

## Relationship To R abc

They replace R-side regression helpers with a C++ backend implementation.

## Known Differences

The routines are designed for abcpp's small dense backend needs, not as a
general matrix library.

## Related Tests

- `tests/cpp/test_core.cpp`
