#include <pybind11/numpy.h>
#include <pybind11/pybind11.h>
#include <pybind11/stl.h>

#include "abcpp/abc.hpp"
#include "abcpp/matrix.hpp"
#include "abcpp/options.hpp"
#include "abcpp/summary.hpp"

#include <string>
#include <vector>

namespace py = pybind11;

namespace {

abcpp::Matrix numpy_to_matrix(
    py::array_t<double, py::array::c_style | py::array::forcecast> array
) {
    py::buffer_info info = array.request();
    if (info.ndim != 2) {
        throw py::value_error("Expected a two-dimensional numeric array.");
    }

    abcpp::Matrix out(
        static_cast<std::size_t>(info.shape[0]),
        static_cast<std::size_t>(info.shape[1])
    );
    const double* ptr = static_cast<const double*>(info.ptr);
    for (std::size_t row = 0; row < out.rows(); ++row) {
        for (std::size_t col = 0; col < out.cols(); ++col) {
            out(row, col) = ptr[row * out.cols() + col];
        }
    }
    return out;
}

std::vector<double> numpy_to_vector(
    py::array_t<double, py::array::c_style | py::array::forcecast> array
) {
    py::buffer_info info = array.request();
    if (info.ndim != 1) {
        throw py::value_error("Expected a one-dimensional numeric array.");
    }

    const double* ptr = static_cast<const double*>(info.ptr);
    return std::vector<double>(ptr, ptr + info.shape[0]);
}

std::vector<bool> numpy_to_bool_vector(
    py::array_t<bool, py::array::c_style | py::array::forcecast> array
) {
    py::buffer_info info = array.request();
    if (info.ndim != 1) {
        throw py::value_error("Expected a one-dimensional boolean array.");
    }

    const bool* ptr = static_cast<const bool*>(info.ptr);
    return std::vector<bool>(ptr, ptr + info.shape[0]);
}

std::vector<abcpp::Matrix> sequence_to_matrices(const py::sequence& values) {
    std::vector<abcpp::Matrix> out;
    out.reserve(static_cast<std::size_t>(py::len(values)));
    for (py::handle value : values) {
        out.push_back(numpy_to_matrix(value.cast<
            py::array_t<double, py::array::c_style | py::array::forcecast>
        >()));
    }
    return out;
}

py::array_t<double> matrix_to_numpy(const abcpp::Matrix& matrix) {
    py::array_t<double> out({
        static_cast<py::ssize_t>(matrix.rows()),
        static_cast<py::ssize_t>(matrix.cols())
    });

    py::buffer_info info = out.request();
    double* ptr = static_cast<double*>(info.ptr);
    for (std::size_t row = 0; row < matrix.rows(); ++row) {
        for (std::size_t col = 0; col < matrix.cols(); ++col) {
            ptr[row * matrix.cols() + col] = matrix(row, col);
        }
    }
    return out;
}

py::list bool_vector_to_python(const std::vector<bool>& values) {
    py::list out;
    for (bool value : values) {
        out.append(value);
    }
    return out;
}

std::vector<abcpp::transform> transforms_to_cpp(
    const std::vector<std::string>& values
) {
    std::vector<abcpp::transform> out;
    out.reserve(values.size());
    for (const std::string& value : values) {
        out.push_back(abcpp::parse_transform(value));
    }
    return out;
}

py::list transforms_to_python(
    const std::vector<abcpp::transform>& transforms
) {
    py::list out;
    for (abcpp::transform transform : transforms) {
        out.append(abcpp::transform_name(transform));
    }
    return out;
}

abcpp::AbcOptions control_to_options(const py::dict& control) {
    py::dict nnet = control["nnet"].cast<py::dict>();

    abcpp::AbcOptions options;
    options.tol = control["tol"].cast<double>();
    options.method = abcpp::parse_method(control["method"].cast<std::string>());
    options.hcorr = control["hcorr"].cast<bool>();
    options.transformations = transforms_to_cpp(
        control["transf"].cast<std::vector<std::string>>()
    );
    options.logit_bounds = numpy_to_matrix(control["logit_bounds"].cast<
        py::array_t<double, py::array::c_style | py::array::forcecast>
    >());
    options.subset = numpy_to_bool_vector(control["subset"].cast<
        py::array_t<bool, py::array::c_style | py::array::forcecast>
    >());
    options.prior_weights = numpy_to_vector(control["prior_weights"].cast<
        py::array_t<double, py::array::c_style | py::array::forcecast>
    >());
    options.kernel = abcpp::parse_kernel(control["kernel"].cast<std::string>());
    options.seed = static_cast<unsigned int>(control["seed"].cast<int>());
    options.reduction.method = abcpp::parse_reduction(
        control["reduction"].cast<std::string>()
    );
    options.reduction.n_comp = static_cast<std::size_t>(
        control["n_comp"].cast<int>()
    );
    options.nnet.numnet = nnet["numnet"].cast<int>();
    options.nnet.sizenet = nnet["sizenet"].cast<int>();
    options.nnet.lambda = nnet["lambda"].cast<std::vector<double>>();
    options.nnet.maxit = nnet["maxit"].cast<int>();
    options.nnet.rang = nnet["rang"].cast<double>();
    options.nnet.abstol = nnet["abstol"].cast<double>();
    options.nnet.reltol = nnet["reltol"].cast<double>();
    options.nnet.verbose = nnet["verbose"].cast<bool>();
    options.nnet.skip = nnet["skip"].cast<bool>();
    return options;
}

py::dict result_to_python(const abcpp::AbcResult& result) {
    py::dict reduction;
    reduction["method"] = abcpp::reduction_name(result.reduction.method);
    reduction["n_comp"] = result.reduction.n_comp;
    reduction["rotation"] = matrix_to_numpy(result.reduction.rotation);
    reduction["center"] = result.reduction.center;

    py::dict diagnostics;
    diagnostics["aic"] = result.diagnostics.aic;
    diagnostics["bic"] = result.diagnostics.bic;
    diagnostics["lambda"] = result.diagnostics.lambda;

    py::dict nnet;
    nnet["numnet"] = result.options.nnet.numnet;
    nnet["sizenet"] = result.options.nnet.sizenet;
    nnet["lambda"] = result.options.nnet.lambda;
    nnet["maxit"] = result.options.nnet.maxit;
    nnet["rang"] = result.options.nnet.rang;
    nnet["abstol"] = result.options.nnet.abstol;
    nnet["reltol"] = result.options.nnet.reltol;
    nnet["verbose"] = result.options.nnet.verbose;
    nnet["skip"] = result.options.nnet.skip;

    py::dict options;
    options["tol"] = result.options.tol;
    options["method"] = abcpp::method_name(result.options.method);
    options["kernel"] = abcpp::kernel_name(result.options.kernel);
    options["hcorr"] = result.options.hcorr;
    options["prior_weights"] = result.options.prior_weights;
    options["seed"] = result.options.seed;
    options["nnet"] = nnet;
    options["reduction"] = reduction;

    py::dict out;
    out["adj_values"] = matrix_to_numpy(result.adj_values);
    out["unadj_values"] = matrix_to_numpy(result.unadj_values);
    out["ss"] = matrix_to_numpy(result.accepted_sumstats);
    out["weights"] = matrix_to_numpy(result.weights);
    out["residuals"] = matrix_to_numpy(result.residuals);
    out["dist"] = result.distances;
    out["accepted_indices"] = result.accepted_indices;
    out["region"] = bool_vector_to_python(result.region);
    out["na_action"] = bool_vector_to_python(result.na_action);
    out["transf"] = transforms_to_python(result.transformations);
    out["logit_bounds"] = matrix_to_numpy(result.logit_bounds);
    out["method"] = abcpp::method_name(result.method);
    out["kernel"] = abcpp::kernel_name(result.kernel);
    out["hcorr"] = result.hcorr;
    out["lambda"] = result.lambda;
    out["numparam"] = result.numparam;
    out["numstat"] = result.numstat;
    out["aic"] = result.aic;
    out["bic"] = result.bic;
    out["status"] = result.status;
    out["message"] = result.message;
    out["options"] = options;
    out["diagnostics"] = diagnostics;
    out["reduction"] = reduction;
    return out;
}

py::dict summary_to_python(const abcpp::SummaryResult& summary) {
    py::list rows;
    for (const abcpp::SummaryColumn& column : summary.columns) {
        py::dict row;
        row["min"] = column.min;
        row["lower"] = column.q_lower;
        row["median"] = column.median;
        row["mean"] = column.mean;
        row["mode"] = column.mode;
        row["upper"] = column.q_upper;
        row["max"] = column.max;
        row["sd"] = column.sd;
        rows.append(row);
    }

    py::dict out;
    out["columns"] = rows;
    out["interval"] = summary.interval;
    out["unadjusted"] = summary.unadjusted;
    return out;
}

abcpp::AbcResult python_to_result(const py::dict& value) {
    abcpp::AbcResult result;
    result.adj_values = numpy_to_matrix(value["adj_values"].cast<
        py::array_t<double, py::array::c_style | py::array::forcecast>
    >());
    result.unadj_values = numpy_to_matrix(value["unadj_values"].cast<
        py::array_t<double, py::array::c_style | py::array::forcecast>
    >());
    result.weights = numpy_to_matrix(value["weights"].cast<
        py::array_t<double, py::array::c_style | py::array::forcecast>
    >());
    result.method = abcpp::parse_method(value["method"].cast<std::string>());
    return result;
}

}  // namespace

PYBIND11_MODULE(_core, m) {
    m.def(
        "abc",
        [](
            py::array_t<double, py::array::c_style | py::array::forcecast>
                target,
            py::array_t<double, py::array::c_style | py::array::forcecast>
                param,
            py::array_t<double, py::array::c_style | py::array::forcecast>
                sumstat,
            py::dict control
        ) {
            const abcpp::AbcOptions options = control_to_options(control);

            const abcpp::AbcResult result = abcpp::fit(
                numpy_to_matrix(target),
                numpy_to_matrix(param),
                numpy_to_matrix(sumstat),
                options
            );
            return result_to_python(result);
        },
        py::arg("target"),
        py::arg("param"),
        py::arg("sumstat"),
        py::arg("control")
    );

    m.def(
        "abc_matrix_list",
        [](
            py::array_t<double, py::array::c_style | py::array::forcecast>
                target,
            py::array_t<double, py::array::c_style | py::array::forcecast>
                param,
            py::sequence sumstats,
            py::dict control
        ) {
            const abcpp::AbcOptions options = control_to_options(control);

            const abcpp::AbcResult result = abcpp::fit(
                numpy_to_matrix(target),
                numpy_to_matrix(param),
                sequence_to_matrices(sumstats),
                options
            );
            return result_to_python(result);
        },
        py::arg("target"),
        py::arg("param"),
        py::arg("sumstats"),
        py::arg("control")
    );

    m.def(
        "summary",
        [](const py::dict& result, bool unadj, double intvl) {
            return summary_to_python(abcpp::summary(
                python_to_result(result),
                unadj,
                intvl
            ));
        },
        py::arg("result"),
        py::arg("unadj") = false,
        py::arg("intvl") = 0.95
    );
}
