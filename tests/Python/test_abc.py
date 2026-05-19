import numpy
import numpy.testing
import pytest

abcpp = pytest.importorskip("abcpp")


EXPECTED_KEYS = {
    "adj_values",
    "unadj_values",
    "ss",
    "weights",
    "residuals",
    "dist",
    "accepted_indices",
    "region",
    "na_action",
    "transf",
    "logit_bounds",
    "method",
    "kernel",
    "hcorr",
    "lambda",
    "numparam",
    "numstat",
    "aic",
    "bic",
    "status",
    "message",
    "options",
    "diagnostics",
    "reduction",
}


def test_output_contains_expected_fields_with_defaults(toy_data):
    result = abcpp.abc(
        target=toy_data["target"],
        params=toy_data["param"],
        sumstats=toy_data["sumstat"],
    )

    assert EXPECTED_KEYS.issubset(set(result.keys()))
    assert result["method"] == "rejection"
    assert result["numparam"] == 2
    assert result["numstat"] == 4


def test_partial_control_overrides_defaults(toy_data):
    tol = 0.125
    result = abcpp.abc(
        target=toy_data["target"],
        params=toy_data["param"],
        sumstats=toy_data["sumstat"],
        control={"tol": tol},
    )

    region = numpy.asarray(result["region"], dtype=bool)
    expected_count = int(numpy.ceil(toy_data["param"].shape[0] * tol))
    assert int(region.sum()) == expected_count
    assert result["unadj_values"].shape[0] == expected_count
    assert result["options"]["method"] == "rejection"

    numpy.testing.assert_allclose(
        result["unadj_values"],
        toy_data["param"][region],
        rtol=0,
        atol=1e-12,
    )


def test_loclinear_runs(toy_data):
    result = abcpp.abc(
        target=toy_data["target"],
        params=toy_data["param"],
        sumstats=toy_data["sumstat"],
        control={
            "method": "loclinear",
            "tol": 0.20,
            "hcorr": False,
            "transf": ["none", "none"],
        },
    )

    assert result["method"] == "loclinear"
    assert result["adj_values"].shape[1] == 2
    assert numpy.isfinite(result["adj_values"]).all()


def test_prior_weights_scale_regression_weights(toy_data):
    prior_weights = numpy.arange(1, toy_data["param"].shape[0] + 1) / 10.0
    control = {
        "method": "loclinear",
        "tol": 0.20,
        "hcorr": False,
        "kernel": "gaussian",
        "transf": ["none", "none"],
    }
    no_prior = abcpp.abc(
        target=toy_data["target"],
        params=toy_data["param"],
        sumstats=toy_data["sumstat"],
        control=control,
    )
    weighted = abcpp.abc(
        target=toy_data["target"],
        params=toy_data["param"],
        sumstats=toy_data["sumstat"],
        control={**control, "prior_weights": prior_weights},
    )

    accepted = numpy.asarray(weighted["accepted_indices"], dtype=int)
    numpy.testing.assert_array_equal(
        accepted,
        numpy.asarray(no_prior["accepted_indices"], dtype=int),
    )
    numpy.testing.assert_allclose(
        weighted["weights"].reshape(-1),
        no_prior["weights"].reshape(-1) * prior_weights[accepted],
        rtol=0,
        atol=1e-12,
    )
    numpy.testing.assert_allclose(
        weighted["options"]["prior_weights"],
        prior_weights,
    )


def test_ridge_runs(toy_data):
    result = abcpp.abc(
        target=toy_data["target"],
        params=toy_data["param"],
        sumstats=toy_data["sumstat"],
        control={
            "method": "ridge",
            "tol": 0.20,
            "hcorr": False,
            "transf": ["none", "none"],
            "nnet": {"lambda": [0.001, 0.01]},
        },
    )

    assert result["method"] == "ridge"
    assert result["adj_values"].shape[1] == 2
    assert numpy.isfinite(result["adj_values"]).all()


def test_neuralnet_runs_with_nested_nnet_control(toy_data):
    result = abcpp.abc(
        target=toy_data["target"],
        params=toy_data["param"],
        sumstats=toy_data["sumstat"],
        control={
            "method": "neuralnet",
            "tol": 0.20,
            "hcorr": False,
            "transf": ["none", "none"],
            "seed": 1004,
            "nnet": {
                "numnet": 3,
                "sizenet": 4,
                "lambda": [0.001],
                "rang": 0.5,
                "abstol": 1e-4,
                "reltol": 1e-8,
                "verbose": False,
                "skip": True,
            },
        },
    )

    assert result["method"] == "neuralnet"
    assert result["adj_values"].shape[1] == 2
    assert numpy.isfinite(result["adj_values"]).all()
    assert len(result["lambda"]) == 3
    assert result["options"]["nnet"]["sizenet"] == 4
    assert result["options"]["nnet"]["skip"] is True


def test_summary_runs(toy_data):
    result = abcpp.abc(
        target=toy_data["target"],
        params=toy_data["param"],
        sumstats=toy_data["sumstat"],
        control={"tol": 0.10},
    )
    summary = abcpp.summary(result)

    assert len(summary["columns"]) == 2
    assert numpy.isfinite(summary["columns"][0]["mean"])
    assert summary["unadjusted"] is False
    assert summary["columns"][0]["min"] <= summary["columns"][0]["max"]


def test_summary_unadjusted_override_runs(toy_data):
    result = abcpp.abc(
        target=toy_data["target"],
        params=toy_data["param"],
        sumstats=toy_data["sumstat"],
        control={
            "method": "loclinear",
            "tol": 0.20,
            "hcorr": False,
        },
    )
    summary = abcpp.summary(result, unadj=True, intvl=0.50)

    assert summary["unadjusted"] is True
    assert summary["interval"] == 0.50
    assert len(summary["columns"]) == 2
