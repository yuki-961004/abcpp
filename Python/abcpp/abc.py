from copy import deepcopy

import numpy

from . import _core


DEFAULT_CONTROL = {
    "method": "rejection",
    "tol": 0.01,
    "kernel": "epanechnikov",
    "hcorr": True,
    "transf": "none",
    "logit_bounds": None,
    "subset": None,
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


def _nested_merge(defaults, overrides):
    merged = deepcopy(defaults)
    for key, value in overrides.items():
        if (
            isinstance(value, dict)
            and isinstance(merged.get(key), dict)
        ):
            merged[key] = _nested_merge(merged[key], value)
        else:
            merged[key] = value
    return merged


def _prepare_control(control):
    if control is None:
        control = {}
    if not isinstance(control, dict):
        raise TypeError("control must be a dict or None")
    merged = _nested_merge(DEFAULT_CONTROL, control)
    if isinstance(merged["transf"], str):
        merged["transf"] = [merged["transf"]]
    if merged["logit_bounds"] is None:
        merged["logit_bounds"] = numpy.zeros((1, 2), dtype=float)
    if merged["subset"] is None:
        merged["subset"] = numpy.asarray([], dtype=bool)
    return merged


def _is_matrix_like(value):
    try:
        return numpy.asarray(value).ndim == 2
    except ValueError:
        return False


def abc(target, params, sumstats, control=None):
    """Run Approximate Bayesian Computation with the C++ backend."""
    control = _prepare_control(control)
    target_array = numpy.asarray(target, dtype=float)
    param_array = numpy.asarray(params, dtype=float)
    sumstat_is_mapping = isinstance(sumstats, dict)
    sumstat_items = list(sumstats.values()) if sumstat_is_mapping else sumstats
    sumstat_is_matrix_collection = (
        isinstance(sumstat_items, (list, tuple))
        and len(sumstat_items) > 0
        and all(_is_matrix_like(item) for item in sumstat_items)
    )
    if sumstat_is_matrix_collection:
        sumstat_value = [
            numpy.asarray(item, dtype=float)
            for item in sumstat_items
        ]
    else:
        sumstat_value = numpy.asarray(sumstats, dtype=float)

    if target_array.ndim == 1:
        target_array = target_array.reshape((1, -1))
    if param_array.ndim == 1:
        param_array = param_array.reshape((-1, 1))
    if not sumstat_is_matrix_collection and sumstat_value.ndim == 1:
        sumstat_value = sumstat_value.reshape((-1, 1))
    if (
        not sumstat_is_matrix_collection
        and param_array.ndim == 2
        and sumstat_value.ndim == 2
        and param_array.shape[0] == 1
        and param_array.shape[1] == sumstat_value.shape[0]
        and sumstat_value.shape[0] != 1
    ):
        param_array = param_array.T

    if sumstat_is_matrix_collection:
        return _core.abc_matrix_list(
            target_array,
            param_array,
            [numpy.asarray(item, dtype=float) for item in sumstat_value],
            control,
        )

    return _core.abc(target_array, param_array, sumstat_value, control)
