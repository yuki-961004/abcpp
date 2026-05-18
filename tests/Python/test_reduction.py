import numpy
import pytest

abcpp = pytest.importorskip("abcpp")


def test_reduction_none_keeps_original_dimension(toy_data):
    result = abcpp.abc(
        target=toy_data["target"],
        param=toy_data["param"],
        sumstat=toy_data["sumstat"],
        tol=0.20,
        method="loclinear",
        hcorr=False,
        transf=["none", "none"],
        reduce="none",
    )

    assert result["numstat"] == toy_data["sumstat"].shape[1]
    assert result["reduction"]["method"] == "none"


def test_reduction_none_and_reduce_none_are_equivalent(toy_data):
    result_default = abcpp.abc(
        target=toy_data["target"],
        param=toy_data["param"],
        sumstat=toy_data["sumstat"],
        tol=0.20,
        method="rejection",
    )
    result_alias = abcpp.abc(
        target=toy_data["target"],
        param=toy_data["param"],
        sumstat=toy_data["sumstat"],
        tol=0.20,
        method="rejection",
        reduce="none",
    )

    assert result_default["numstat"] == result_alias["numstat"]
    assert result_default["reduction"]["method"] == "none"
    assert result_alias["reduction"]["method"] == "none"


def test_pca_reduction_returns_requested_dimension(toy_data):
    result = abcpp.abc(
        target=toy_data["target"],
        param=toy_data["param"],
        sumstat=toy_data["sumstat"],
        tol=0.20,
        method="ridge",
        hcorr=False,
        transf=["none", "none"],
        reduce="pca",
        ncomp=2,
    )

    assert result["numstat"] == 2
    assert result["reduction"]["method"] == "PCA"
    assert result["reduction"]["rotation"].shape[1] == 2
    assert numpy.isfinite(result["adj_values"]).all()


def test_pls_reduction_returns_requested_dimension(toy_data):
    result = abcpp.abc(
        target=toy_data["target"],
        param=toy_data["param"],
        sumstat=toy_data["sumstat"],
        tol=0.20,
        method="ridge",
        hcorr=False,
        transf=["none", "none"],
        reduction="pls",
        ncomp=2,
    )

    assert result["numstat"] == 2
    assert result["reduction"]["method"] == "PLS"
    assert result["reduction"]["rotation"].shape[1] == 2
    assert numpy.isfinite(result["adj_values"]).all()
