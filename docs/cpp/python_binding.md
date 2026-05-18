# Python Binding

## Purpose

`Python/src/py_abcpp.cpp` is the pybind11 binding layer. It translates NumPy
arrays into C++ backend types and returns Python dictionaries.

## Main Functions And Classes

- `_core.abc`
- `_core.summary`
- Python helper `abcpp.abc()`
- Python helper `abcpp.summary()`

## Inputs

NumPy-compatible arrays and scalar options prepared by
`Python/abcpp/__init__.py`.

## Outputs

Python dictionaries containing backend result fields and summary fields.

## Error Handling

Shape errors in the binding throw Python `ValueError`. Backend exceptions
propagate through pybind11 as Python exceptions.

## Numerical Assumptions

The binding performs no numerical algorithm beyond type conversion.

## Mutation

Inputs are copied into backend matrices and vectors. Python arrays are not
mutated.

## Randomness

The binding passes the user seed into C++. It does not generate randomness.

## R/Python Relationship

This is the only Python compiled entry point. Internal C++ helper functions
are not exported as Python functions.

## Relationship To R abc

Python names mirror the compact abcpp interface and use Python naming
conventions for output fields.

## Known Differences

Python coverage tools cover the wrapper Python code, but not C++ source lines
inside the compiled extension unless separate native coverage is configured.

## Related Tests

- `tests/python/test_abc.py`
- `tests/python/test_reduction.py`
- `tests/python/test_validation.py`
