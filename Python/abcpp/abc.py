import numpy

from . import _core


def _is_matrix_like(value):
    try:
        return numpy.asarray(value).ndim == 2
    except ValueError:
        return False


def abc(
    target,
    param,
    sumstat,
    tol,
    method,
    hcorr=True,
    transf="none",
    logit_bounds=None,
    subset=None,
    kernel="epanechnikov",
    numnet=10,
    sizenet=5,
    lambda_values=None,
    maxit=500,
    reduction=None,
    n_comp=None,
    seed=1004,
):
    """Run Approximate Bayesian Computation with the C++ backend."""
    target_array = numpy.asarray(target, dtype=float)
    param_array = numpy.asarray(param, dtype=float)
    sumstat_is_mapping = isinstance(sumstat, dict)
    sumstat_items = list(sumstat.values()) if sumstat_is_mapping else sumstat
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
        sumstat_value = numpy.asarray(sumstat, dtype=float)

    if target_array.ndim == 1:
        target_array = target_array.reshape((1, -1))
    if param_array.ndim == 1:
        param_array = param_array.reshape((-1, 1))
    if not sumstat_is_matrix_collection and sumstat_value.ndim == 1:
        sumstat_value = sumstat_value.reshape((-1, 1))
    if (
        not sumstat_is_matrix_collection
        and
        param_array.ndim == 2
        and sumstat_value.ndim == 2
        and param_array.shape[0] == 1
        and param_array.shape[1] == sumstat_value.shape[0]
        and sumstat_value.shape[0] != 1
    ):
        param_array = param_array.T

    if logit_bounds is None:
        logit_bounds = numpy.zeros((1, 2), dtype=float)
    if subset is None:
        subset = numpy.asarray([], dtype=bool)
    if lambda_values is None:
        lambda_values = numpy.asarray([0.0001, 0.001, 0.01], dtype=float)
    if isinstance(transf, str):
        transf = [transf]
    if reduction is None:
        reduction = "none"
    if n_comp is None:
        n_comp = 0

    common_args = dict(
        target=target_array,
        param=param_array,
        tol=float(tol),
        method=str(method),
        hcorr=bool(hcorr),
        transf=list(transf),
        logit_bounds=numpy.asarray(logit_bounds, dtype=float),
        subset=numpy.asarray(subset, dtype=bool),
        kernel=str(kernel),
        numnet=int(numnet),
        sizenet=int(sizenet),
        lambda_values=numpy.asarray(lambda_values, dtype=float),
        maxit=int(maxit),
        reduction=str(reduction),
        n_comp=int(n_comp),
        seed=int(seed),
    )

    if sumstat_is_matrix_collection:
        return _core.abc_matrix_list(
            sumstats=[numpy.asarray(item, dtype=float) for item in sumstat_value],
            **common_args,
        )

    return _core.abc(sumstat=sumstat_value, **common_args)
