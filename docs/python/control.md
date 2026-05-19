# Python control

`abcpp.abc()` has four user-facing inputs:

```python
fit = abcpp.abc(target, params, sumstats, control=None)
```

`control` is a nested dictionary. Missing fields are filled from
`abcpp.abc.DEFAULT_CONTROL` with a nested merge.

```python
{
    "method": "rejection",
    "tol": 0.01,
    "kernel": "epanechnikov",
    "hcorr": True,
    "transf": "none",
    "seed": 1004,
    "reduction": "none",
    "n_comp": 0,
    "nnet": {
        "numnet": 10,
        "sizenet": 5,
        "lambda": [0.0001, 0.001, 0.01],
        "maxit": 500,
        "rang": 0.7,
        "abstol": 1e-4,
        "reltol": 1e-8,
        "verbose": False,
        "skip": False,
    },
}
```

Partial overrides preserve the rest of the defaults:

```python
fit = abcpp.abc(
    target=target,
    params=params,
    sumstats=sumstats,
    control={
        "method": "neuralnet",
        "nnet": {"sizenet": 8, "maxit": 1000},
    },
)
```

The Python layer does not implement ABC. It converts inputs, merges control,
calls `abcpp._core`, and returns the complete result dictionary.
