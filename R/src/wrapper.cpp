#include <Rcpp.h>
#include <R_ext/Rdynload.h>

#include "abcpp/abc.hpp"
#include "abcpp/matrix.hpp"
#include "abcpp/options.hpp"

namespace {

abcpp::Matrix r_matrix_to_cpp(Rcpp::NumericMatrix matrix) {
    abcpp::Matrix out(
        static_cast<std::size_t>(matrix.nrow()),
        static_cast<std::size_t>(matrix.ncol())
    );

    for (int row = 0; row < matrix.nrow(); ++row) {
        for (int col = 0; col < matrix.ncol(); ++col) {
            out(
                static_cast<std::size_t>(row),
                static_cast<std::size_t>(col)
            ) = matrix(row, col);
        }
    }
    return out;
}

Rcpp::NumericMatrix cpp_matrix_to_r(const abcpp::Matrix& matrix) {
    Rcpp::NumericMatrix out(
        static_cast<int>(matrix.rows()),
        static_cast<int>(matrix.cols())
    );

    for (std::size_t row = 0; row < matrix.rows(); ++row) {
        for (std::size_t col = 0; col < matrix.cols(); ++col) {
            out(
                static_cast<int>(row),
                static_cast<int>(col)
            ) = matrix(row, col);
        }
    }
    return out;
}

std::vector<abcpp::transform> r_transforms_to_cpp(
    const Rcpp::CharacterVector& transforms
) {
    std::vector<abcpp::transform> out;
    out.reserve(static_cast<std::size_t>(transforms.size()));
    for (R_xlen_t i = 0; i < transforms.size(); ++i) {
        out.push_back(abcpp::parse_transform(
            Rcpp::as<std::string>(transforms[i])
        ));
    }
    return out;
}

Rcpp::CharacterVector cpp_transforms_to_r(
    const std::vector<abcpp::transform>& transforms
) {
    Rcpp::CharacterVector out(
        static_cast<R_xlen_t>(transforms.size())
    );
    for (std::size_t i = 0; i < transforms.size(); ++i) {
        out[static_cast<R_xlen_t>(i)] = abcpp::transform_name(transforms[i]);
    }
    return out;
}

Rcpp::LogicalVector cpp_bool_to_r(const std::vector<bool>& values) {
    Rcpp::LogicalVector out(static_cast<R_xlen_t>(values.size()));
    for (std::size_t i = 0; i < values.size(); ++i) {
        out[static_cast<R_xlen_t>(i)] = values[i];
    }
    return out;
}

Rcpp::IntegerVector cpp_indices_to_r(
    const std::vector<std::size_t>& values
) {
    Rcpp::IntegerVector out(static_cast<R_xlen_t>(values.size()));
    for (std::size_t i = 0; i < values.size(); ++i) {
        out[static_cast<R_xlen_t>(i)] = static_cast<int>(values[i] + 1);
    }
    return out;
}

std::vector<bool> r_subset_to_cpp(Rcpp::LogicalVector subset) {
    std::vector<bool> out(static_cast<std::size_t>(subset.size()), true);
    for (R_xlen_t i = 0; i < subset.size(); ++i) {
        out[static_cast<std::size_t>(i)] = subset[i] == TRUE;
    }
    return out;
}

std::vector<abcpp::Matrix> r_matrix_list_to_cpp(const Rcpp::List& matrices) {
    std::vector<abcpp::Matrix> out;
    out.reserve(static_cast<std::size_t>(matrices.size()));
    for (R_xlen_t i = 0; i < matrices.size(); ++i) {
        out.push_back(r_matrix_to_cpp(Rcpp::NumericMatrix(matrices[i])));
    }
    return out;
}

abcpp::AbcOptions make_options(
    SEXP tol_sexp,
    SEXP method_sexp,
    SEXP hcorr_sexp,
    SEXP transf_sexp,
    SEXP logit_bounds_sexp,
    SEXP subset_sexp,
    SEXP prior_weights_sexp,
    SEXP kernel_sexp,
    SEXP numnet_sexp,
    SEXP sizenet_sexp,
    SEXP lambda_sexp,
    SEXP maxit_sexp,
    SEXP rang_sexp,
    SEXP abstol_sexp,
    SEXP reltol_sexp,
    SEXP verbose_sexp,
    SEXP skip_sexp,
    SEXP seed_sexp,
    SEXP reduction_sexp,
    SEXP n_comp_sexp
) {
    const Rcpp::NumericMatrix logit_bounds(logit_bounds_sexp);
    const Rcpp::LogicalVector subset(subset_sexp);
    const Rcpp::NumericVector prior_weights(prior_weights_sexp);
    const Rcpp::NumericVector lambda(lambda_sexp);

    abcpp::AbcOptions options;
    options.tol = Rcpp::as<double>(tol_sexp);
    options.method = abcpp::parse_method(Rcpp::as<std::string>(method_sexp));
    options.hcorr = Rcpp::as<bool>(hcorr_sexp);
    options.transformations = r_transforms_to_cpp(
        Rcpp::CharacterVector(transf_sexp)
    );
    options.logit_bounds = r_matrix_to_cpp(logit_bounds);
    options.subset = r_subset_to_cpp(subset);
    options.prior_weights = Rcpp::as<std::vector<double>>(prior_weights);
    options.kernel = abcpp::parse_kernel(Rcpp::as<std::string>(kernel_sexp));
    options.nnet.numnet = Rcpp::as<int>(numnet_sexp);
    options.nnet.sizenet = Rcpp::as<int>(sizenet_sexp);
    options.nnet.lambda = Rcpp::as<std::vector<double>>(lambda);
    options.nnet.maxit = Rcpp::as<int>(maxit_sexp);
    options.nnet.rang = Rcpp::as<double>(rang_sexp);
    options.nnet.abstol = Rcpp::as<double>(abstol_sexp);
    options.nnet.reltol = Rcpp::as<double>(reltol_sexp);
    options.nnet.verbose = Rcpp::as<bool>(verbose_sexp);
    options.nnet.skip = Rcpp::as<bool>(skip_sexp);
    options.seed = static_cast<unsigned int>(Rcpp::as<int>(seed_sexp));
    options.reduction.method = abcpp::parse_reduction(
        Rcpp::as<std::string>(reduction_sexp)
    );
    options.reduction.n_comp = static_cast<std::size_t>(
        Rcpp::as<int>(n_comp_sexp)
    );
    return options;
}

SEXP result_to_r(const abcpp::AbcResult& result) {
    Rcpp::List reduction_info = Rcpp::List::create(
        Rcpp::Named("method") = abcpp::reduction_name(result.reduction.method),
        Rcpp::Named("n_comp") = static_cast<int>(result.reduction.n_comp),
        Rcpp::Named("rotation") = cpp_matrix_to_r(result.reduction.rotation),
        Rcpp::Named("center") = result.reduction.center
    );

    Rcpp::List diagnostics = Rcpp::List::create(
        Rcpp::Named("aic") = result.diagnostics.aic,
        Rcpp::Named("bic") = result.diagnostics.bic,
        Rcpp::Named("lambda") = result.diagnostics.lambda
    );

    Rcpp::List nnet_info = Rcpp::List::create(
        Rcpp::Named("numnet") = result.options.nnet.numnet,
        Rcpp::Named("sizenet") = result.options.nnet.sizenet,
        Rcpp::Named("lambda") = result.options.nnet.lambda,
        Rcpp::Named("maxit") = result.options.nnet.maxit,
        Rcpp::Named("rang") = result.options.nnet.rang,
        Rcpp::Named("abstol") = result.options.nnet.abstol,
        Rcpp::Named("reltol") = result.options.nnet.reltol,
        Rcpp::Named("verbose") = result.options.nnet.verbose,
        Rcpp::Named("skip") = result.options.nnet.skip
    );

    Rcpp::List option_info = Rcpp::List::create(
        Rcpp::Named("tol") = result.options.tol,
        Rcpp::Named("method") = abcpp::method_name(result.options.method),
        Rcpp::Named("kernel") = abcpp::kernel_name(result.options.kernel),
        Rcpp::Named("hcorr") = result.options.hcorr,
        Rcpp::Named("prior.weights") = result.options.prior_weights,
        Rcpp::Named("seed") = static_cast<int>(result.options.seed),
        Rcpp::Named("nnet") = nnet_info,
        Rcpp::Named("reduction") = reduction_info
    );

    return Rcpp::List::create(
        Rcpp::Named("adj.values") = cpp_matrix_to_r(result.adj_values),
        Rcpp::Named("unadj.values") = cpp_matrix_to_r(result.unadj_values),
        Rcpp::Named("ss") = cpp_matrix_to_r(result.accepted_sumstats),
        Rcpp::Named("weights") = cpp_matrix_to_r(result.weights),
        Rcpp::Named("residuals") = cpp_matrix_to_r(result.residuals),
        Rcpp::Named("dist") = result.distances,
        Rcpp::Named("accepted.indices") =
            cpp_indices_to_r(result.accepted_indices),
        Rcpp::Named("region") = cpp_bool_to_r(result.region),
        Rcpp::Named("na.action") = cpp_bool_to_r(result.na_action),
        Rcpp::Named("transf") = cpp_transforms_to_r(result.transformations),
        Rcpp::Named("logit.bounds") = cpp_matrix_to_r(result.logit_bounds),
        Rcpp::Named("method") = abcpp::method_name(result.method),
        Rcpp::Named("kernel") = abcpp::kernel_name(result.kernel),
        Rcpp::Named("hcorr") = result.hcorr,
        Rcpp::Named("lambda") = result.lambda,
        Rcpp::Named("numparam") = result.numparam,
        Rcpp::Named("numstat") = result.numstat,
        Rcpp::Named("aic") = result.aic,
        Rcpp::Named("bic") = result.bic,
        Rcpp::Named("status") = result.status,
        Rcpp::Named("message") = result.message,
        Rcpp::Named("options") = option_info,
        Rcpp::Named("diagnostics") = diagnostics,
        Rcpp::Named("reduction") = reduction_info
    );
}

}  // namespace

extern "C" SEXP _abcpp_abc(
    SEXP target_sexp,
    SEXP param_sexp,
    SEXP sumstat_sexp,
    SEXP tol_sexp,
    SEXP method_sexp,
    SEXP hcorr_sexp,
    SEXP transf_sexp,
    SEXP logit_bounds_sexp,
    SEXP subset_sexp,
    SEXP prior_weights_sexp,
    SEXP kernel_sexp,
    SEXP numnet_sexp,
    SEXP sizenet_sexp,
    SEXP lambda_sexp,
    SEXP maxit_sexp,
    SEXP rang_sexp,
    SEXP abstol_sexp,
    SEXP reltol_sexp,
    SEXP verbose_sexp,
    SEXP skip_sexp,
    SEXP seed_sexp,
    SEXP reduction_sexp,
    SEXP n_comp_sexp
) {
    BEGIN_RCPP

    const Rcpp::NumericMatrix target(target_sexp);
    const Rcpp::NumericMatrix param(param_sexp);
    const Rcpp::NumericMatrix sumstat(sumstat_sexp);
    const abcpp::AbcOptions options = make_options(
        tol_sexp,
        method_sexp,
        hcorr_sexp,
        transf_sexp,
        logit_bounds_sexp,
        subset_sexp,
        prior_weights_sexp,
        kernel_sexp,
        numnet_sexp,
        sizenet_sexp,
        lambda_sexp,
        maxit_sexp,
        rang_sexp,
        abstol_sexp,
        reltol_sexp,
        verbose_sexp,
        skip_sexp,
        seed_sexp,
        reduction_sexp,
        n_comp_sexp
    );

    const abcpp::AbcResult result = abcpp::fit(
        r_matrix_to_cpp(target),
        r_matrix_to_cpp(param),
        r_matrix_to_cpp(sumstat),
        options
    );

    return result_to_r(result);

    END_RCPP
}

extern "C" SEXP _abcpp_abc_matrix_list(
    SEXP target_sexp,
    SEXP param_sexp,
    SEXP sumstats_sexp,
    SEXP tol_sexp,
    SEXP method_sexp,
    SEXP hcorr_sexp,
    SEXP transf_sexp,
    SEXP logit_bounds_sexp,
    SEXP subset_sexp,
    SEXP prior_weights_sexp,
    SEXP kernel_sexp,
    SEXP numnet_sexp,
    SEXP sizenet_sexp,
    SEXP lambda_sexp,
    SEXP maxit_sexp,
    SEXP rang_sexp,
    SEXP abstol_sexp,
    SEXP reltol_sexp,
    SEXP verbose_sexp,
    SEXP skip_sexp,
    SEXP seed_sexp,
    SEXP reduction_sexp,
    SEXP n_comp_sexp
) {
    BEGIN_RCPP

    const Rcpp::NumericMatrix target(target_sexp);
    const Rcpp::NumericMatrix param(param_sexp);
    const Rcpp::List sumstats(sumstats_sexp);
    const abcpp::AbcOptions options = make_options(
        tol_sexp,
        method_sexp,
        hcorr_sexp,
        transf_sexp,
        logit_bounds_sexp,
        subset_sexp,
        prior_weights_sexp,
        kernel_sexp,
        numnet_sexp,
        sizenet_sexp,
        lambda_sexp,
        maxit_sexp,
        rang_sexp,
        abstol_sexp,
        reltol_sexp,
        verbose_sexp,
        skip_sexp,
        seed_sexp,
        reduction_sexp,
        n_comp_sexp
    );

    const abcpp::AbcResult result = abcpp::fit(
        r_matrix_to_cpp(target),
        r_matrix_to_cpp(param),
        r_matrix_list_to_cpp(sumstats),
        options
    );

    return result_to_r(result);

    END_RCPP
}

static const R_CallMethodDef CallEntries[] = {
    {
        "_abcpp_abc",
        reinterpret_cast<DL_FUNC>(&_abcpp_abc),
        23
    },
    {
        "_abcpp_abc_matrix_list",
        reinterpret_cast<DL_FUNC>(&_abcpp_abc_matrix_list),
        23
    },
    {nullptr, nullptr, 0}
};

extern "C" void R_init_abcpp(DllInfo* dll) {
    R_registerRoutines(dll, nullptr, CallEntries, nullptr, nullptr);
    R_useDynamicSymbols(dll, FALSE);
}
