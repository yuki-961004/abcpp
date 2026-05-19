# Result Layout

## Purpose

`result.hpp` defines the backend result structures returned by ABC and summary
operations.

## Main Functions And Classes

- `abcpp::AbcResult`
- `abcpp::ReductionInfo`
- `abcpp::SummaryColumn`
- `abcpp::SummaryResult`

## Inputs

Result objects are assembled by `abcpp::opt::run()` / `abcpp::fit()` and summarized by
`abcpp::summary()`.

## Outputs

The result layout includes adjusted draws, unadjusted draws, accepted summary
statistics, weights, residuals, distances, accepted-region flags, metadata,
and reduction information.

## Error Handling

The structs do not throw by themselves. Errors arise in producers and
consumers when dimensions are incompatible.

## Numerical Assumptions

No direct numerical assumptions are made by the structs.

## Mutation

Struct fields are mutable C++ values. Public backend functions return them by
value.

## Randomness

Result objects only record outputs. They do not generate randomness.

## R/Python Relationship

R and Python bindings translate `AbcResult` into language-native lists or
dictionaries.

## Relationship To R abc

Several field names are aligned with R `abc` concepts, such as unadjusted
values, adjusted values, distances, and accepted region.

## Known Differences

The exact R/Python output field spelling differs by language convention:
R uses names such as `unadj.values`, while Python uses `unadj_values`.

## Related Tests

- `tests/testthat/test-abc.R`
- `tests/python/test_abc.py`
- `tests/cpp/test_core.cpp`
