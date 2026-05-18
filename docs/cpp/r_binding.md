# R Binding

## Purpose

`R/src/wrapper.cpp` is the Rcpp binding layer. It translates R inputs into C++
backend types and translates `AbcResult` back into an R list.

## Main Functions And Classes

- `_abcpp_abc()`
- R helper `abcpp::abc()` in `R/R/abc.R`
- `abcpp::Matrix`
- `abcpp::AbcOptions`

## Inputs

R vectors, matrices, data frames converted by `R/R/abc.R`, plus scalar
options and character parameters.

## Outputs

An R list with class `abcpp`, containing backend result fields and restored
parameter/statistic names.

## Error Handling

C++ exceptions are returned to R through Rcpp. R wrapper defaults normalize
missing optional inputs before calling C++.

## Numerical Assumptions

The binding does not implement numerical algorithms. It only converts types.

## Mutation

The binding copies R inputs into C++ matrices and vectors. R inputs are not
mutated.

## Randomness

The binding passes the user seed into C++. It does not generate randomness.

## R/Python Relationship

This is the only R compiled entry point. There is no per-C++-function R
wrapper.

## Relationship To R abc

The R wrapper uses familiar argument names inspired by `abc::abc()`.

## Known Differences

`summary.abcpp()` is an R S3 helper and is implemented in R, not C++.

## Related Tests

- `R/tests/testthat/test-summary.R`
- `tests/testthat/test-abc.R`
- `tests/testthat/test-validation.R`
