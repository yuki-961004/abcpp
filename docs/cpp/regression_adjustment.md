# Regression Adjustment

## Purpose

Regression adjustment corrects accepted parameters toward the target summary
statistics after the rejection step.

## Main Functions And Classes

- Internal local-linear adjustment helpers in `Cpp/src/abc.cpp`
- Ridge adjustment helpers in `Cpp/src/abc.cpp`
- Neural adjustment helpers in `Cpp/src/abc.cpp`
- `abcpp::AbcResult`

## Inputs

- Accepted scaled summary statistics.
- Accepted transformed parameters.
- Kernel weights.
- Target design row.
- Options for heteroscedastic correction, ridge lambda, and neural settings.

## Outputs

- Regression-adjusted posterior values in `AbcResult::adj_values`.
- Residuals in `AbcResult::residuals`.
- Weights in `AbcResult::weights`.
- AIC and BIC for local-linear adjustment.

## Error Handling

Dimension errors are caught before regression. Singular systems are stabilized
with small diagonal regularization or throw if still unusable.

## Numerical Assumptions

The local-linear and ridge paths use weighted least squares. Heteroscedastic
correction models log squared residuals with small lower bounds.

## Mutation

Regression helpers work on local matrices and do not mutate caller inputs.

## Randomness

Local-linear and ridge adjustment are deterministic. Neural adjustment uses
seeded random initial weights and lambda sampling.

## R/Python Relationship

R and Python call this through `abc()` with `method = "loclinear"`, `"ridge"`,
or `"neuralnet"`.

## Relationship To R abc

The adjustment contracts and input names are inspired by R `abc::abc()`.

## Known Differences

The neural path does not call R `nnet`, so exact pointwise equality with R
`abc` is not expected.

## Related Tests

- `tests/cpp/test_core.cpp`
- `tests/testthat/test-r-abc-alignment.R`
- `tests/python/test_abc.py`
