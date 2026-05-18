# Options And Validation

## Purpose

`options.cpp` parses user-facing strings into backend enum values and converts
backend enum values back into stable names.

## Main Functions And Classes

- `abcpp::AbcOptions`
- `parse_method()`
- `parse_kernel()`
- `parse_transform()`
- `parse_reduction()`
- `method_name()`
- `kernel_name()`
- `transform_name()`
- `reduction_name()`

## Inputs

Strings supplied by R/Python wrappers or C++ callers.

## Outputs

Backend enums and user-facing names.

## Error Handling

Unknown methods, kernels, transforms, or reductions throw
`std::invalid_argument`.

## Numerical Assumptions

No numerical assumptions are made in this module.

## Mutation

Parsing functions do not mutate inputs.

## Randomness

Options parsing is deterministic.

## R/Python Relationship

R and Python wrappers keep defaults in their own languages, then pass strings
to these C++ parsers.

## Relationship To R abc

Method names and transform names are aligned with common R `abc::abc()` usage
where applicable.

## Known Differences

`reduction` is an abcpp extension and includes `none`, `pca`, and `pls`.

## Related Tests

- `tests/cpp/test_core.cpp`
- `tests/testthat/test-validation.R`
- `tests/python/test_validation.py`
