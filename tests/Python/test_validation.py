import pytest
import numpy

abcpp = pytest.importorskip("abcpp")


def test_dimension_mismatch_raises(toy_data):
    with pytest.raises(Exception, match="target summary dimension"):
        abcpp.abc(
            target=toy_data["target"][:-1],
            param=toy_data["param"],
            sumstat=toy_data["sumstat"],
            tol=0.10,
            method="rejection",
        )

    with pytest.raises(Exception, match="param.rows"):
        abcpp.abc(
            target=toy_data["target"],
            param=toy_data["param"][:-1, :],
            sumstat=toy_data["sumstat"],
            tol=0.10,
            method="rejection",
        )


def test_invalid_method_raises(toy_data):
    with pytest.raises(Exception, match="Unknown ABC method"):
        abcpp.abc(
            target=toy_data["target"],
            param=toy_data["param"],
            sumstat=toy_data["sumstat"],
            tol=0.10,
            method="bad_method",
        )


def test_invalid_reduction_raises(toy_data):
    with pytest.raises(Exception, match="Unknown summary reduction"):
        abcpp.abc(
            target=toy_data["target"],
            param=toy_data["param"],
            sumstat=toy_data["sumstat"],
            tol=0.10,
            method="rejection",
            reduce="bad_reduction",
        )


def test_invalid_tolerance_raises(toy_data):
    with pytest.raises(Exception, match="tol must be"):
        abcpp.abc(
            target=toy_data["target"],
            param=toy_data["param"],
            sumstat=toy_data["sumstat"],
            tol=0,
            method="rejection",
        )


def test_matrix_target_and_stacked_summary_statistics_work(toy_data):
    target_matrix = numpy.asarray([toy_data["target"][:2]])
    sumstat_matrix = toy_data["sumstat"][:, :2]

    result_none = abcpp.abc(
        target=target_matrix,
        param=toy_data["param"],
        sumstat=sumstat_matrix,
        tol=0.10,
        method="rejection",
        reduction="none",
    )

    assert result_none["numstat"] == 2

    stacked_sumstat = numpy.reshape(sumstat_matrix, (-1, 1))
    target_stacked = numpy.reshape(toy_data["target"][:2], (2, 1))

    result_pls = abcpp.abc(
        target=target_stacked,
        param=toy_data["param"],
        sumstat=stacked_sumstat,
        tol=0.30,
        method="loclinear",
        hcorr=False,
        reduction="pls",
        ncomp=1,
    )

    assert result_pls["numstat"] == 1
    assert result_pls["reduction"]["method"] == "PLS"


def test_matrix_target_and_list_summary_statistics_work():
    param = numpy.arange(5, dtype=float).reshape((-1, 1))
    sumstats = [
        numpy.asarray(
            [[value, value + 0.1], [value + 0.2, value + 0.3]],
            dtype=float,
        )
        for value in range(5)
    ]
    target = numpy.asarray([[2.0, 2.1], [2.2, 2.3]], dtype=float)

    result = abcpp.abc(
        target=target,
        param=param,
        sumstat=sumstats,
        tol=0.40,
        method="rejection",
        reduction="none",
    )

    assert result["numstat"] == 4
    assert result["unadj_values"].shape[0] == 2
    assert result["ss"].shape[1] == 4
    assert len(abcpp.summary(result)["columns"]) == 1


def test_matrix_target_and_dict_summary_statistics_work():
    param = numpy.arange(5, dtype=float).reshape((-1, 1))
    sumstats = {
        f"sim_{value}": numpy.asarray(
            [[value, value + 0.1], [value + 0.2, value + 0.3]],
            dtype=float,
        )
        for value in range(5)
    }
    target = numpy.asarray([[2.0, 2.1], [2.2, 2.3]], dtype=float)

    result = abcpp.abc(
        target=target,
        param=param,
        sumstat=sumstats,
        tol=0.40,
        method="rejection",
        reduction="none",
    )

    assert result["numstat"] == 4
    assert result["unadj_values"].shape[0] == 2
    assert result["ss"].shape[1] == 4


def test_one_row_parameter_matrix_is_treated_as_one_parameter(toy_data):
    param_row = numpy.reshape(toy_data["param"][:, 0], (1, -1))

    result = abcpp.abc(
        target=toy_data["target"],
        param=param_row,
        sumstat=toy_data["sumstat"],
        tol=0.10,
        method="rejection",
    )

    assert result["numparam"] == 1
    assert result["unadj_values"].shape[1] == 1


def test_one_dimensional_param_and_sumstat_are_reshaped():
    param = numpy.linspace(0.0, 1.0, 30)
    sumstat = param + 0.01

    result = abcpp.abc(
        target=[0.51],
        param=param,
        sumstat=sumstat,
        tol=0.20,
        method="rejection",
    )

    assert result["numparam"] == 1
    assert result["numstat"] == 1
    assert result["unadj_values"].shape[1] == 1
