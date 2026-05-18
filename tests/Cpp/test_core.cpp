#include "abcpp/abcpp.hpp"
#include "abcpp/linear_algebra.hpp"
#include "abcpp/matrix.hpp"
#include "abcpp/options.hpp"
#include "abcpp/reduction.hpp"
#include "abcpp/statistics.hpp"

#include <cmath>
#include <functional>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>
#include <vector>

namespace {

void require_true(bool value, const char* message) {
    if (!value) {
        throw std::runtime_error(message);
    }
}

void require_near(
    double value,
    double expected,
    double tolerance,
    const char* message
) {
    if (std::fabs(value - expected) > tolerance) {
        throw std::runtime_error(message);
    }
}

void require_finite(double value, const char* message) {
    require_true(std::isfinite(value), message);
}

template <typename ErrorType>
void require_throws(
    const std::function<void()>& callback,
    const char* message
) {
    bool threw = false;
    try {
        callback();
    } catch (const ErrorType&) {
        threw = true;
    }
    require_true(threw, message);
}

abcpp::Matrix make_param_matrix(std::size_t rows, std::size_t cols) {
    abcpp::Matrix param(rows, cols, 0.0);
    for (std::size_t row = 0; row < rows; ++row) {
        const double x = static_cast<double>(row + 1) /
            static_cast<double>(rows + 2);
        for (std::size_t col = 0; col < cols; ++col) {
            // 涓枃璇存槑: 姣忎竴鍒椾娇鐢ㄤ笉鍚屾枩�? 闃叉鍥炲綊娴嬭瘯閫€鍖栨垚甯告暟鍒?
            param(row, col) = 0.15 + x * static_cast<double>(col + 1);
        }
    }
    return param;
}

abcpp::Matrix make_sumstat_matrix(std::size_t rows, std::size_t cols) {
    abcpp::Matrix sumstat(rows, cols, 0.0);
    for (std::size_t row = 0; row < rows; ++row) {
        const double x = static_cast<double>(row + 1) / 11.0;
        for (std::size_t col = 0; col < cols; ++col) {
            // 涓枃璇存槑: 姝ｅ鸡鍜岀嚎鎬ч」娣峰悎, �?PCA, PLS, 鍥炲綊閮芥湁鐪熷疄淇″彿.
            sumstat(row, col) = std::sin(x + static_cast<double>(col)) +
                0.03 * static_cast<double>(row * (col + 1));
        }
    }
    return sumstat;
}

std::vector<double> make_target_from_row(
    const abcpp::Matrix& sumstat,
    std::size_t row
) {
    return sumstat.row(row);
}

void test_minimal_cpp_smoke() {
    abcpp::Matrix param(6, 2, 0.0);
    abcpp::Matrix sumstat(6, 2, 0.0);
    for (std::size_t row = 0; row < 6; ++row) {
        const double x = static_cast<double>(row);
        param(row, 0) = x;
        param(row, 1) = x + 0.5;
        sumstat(row, 0) = x;
        sumstat(row, 1) = x * 0.5;
    }

    abcpp::AbcOptions options;
    options.method = abcpp::Method::Rejection;
    options.tol = 0.5;
    options.reduction.method = abcpp::ReductionMethod::None;

    const abcpp::AbcResult fit = abcpp::abc(
        std::vector<double>{2.1, 1.05},
        param,
        sumstat,
        options
    );
    const abcpp::SummaryResult summary = abcpp::summary(fit);

    require_true(fit.status == "ok", "smoke status ok");
    require_true(fit.unadj_values.rows() == 3, "smoke accepted rows");
    require_true(fit.accepted_indices.size() == 3, "smoke indices");
    require_true(summary.columns.size() == 2, "smoke summary columns");
    require_finite(summary.columns[0].mean, "smoke summary finite");
}

void test_matrix_sumstat_list_flattens() {
    abcpp::Matrix param(5, 1, 0.0);
    std::vector<abcpp::Matrix> sumstats;
    sumstats.reserve(5);
    for (std::size_t row = 0; row < 5; ++row) {
        param(row, 0) = static_cast<double>(row);
        abcpp::Matrix stat(2, 2, 0.0);
        stat(0, 0) = static_cast<double>(row);
        stat(0, 1) = static_cast<double>(row) + 0.1;
        stat(1, 0) = static_cast<double>(row) + 0.2;
        stat(1, 1) = static_cast<double>(row) + 0.3;
        sumstats.push_back(stat);
    }

    abcpp::Matrix target(2, 2, 0.0);
    target(0, 0) = 2.0;
    target(0, 1) = 2.1;
    target(1, 0) = 2.2;
    target(1, 1) = 2.3;

    abcpp::AbcOptions options;
    options.method = abcpp::Method::Rejection;
    options.tol = 0.4;
    options.reduction.method = abcpp::ReductionMethod::None;

    const abcpp::AbcResult result = abcpp::abc(
        target,
        param,
        sumstats,
        options
    );

    require_true(result.numstat == 4, "matrix list flattened dimension");
    require_true(result.unadj_values.rows() == 2, "matrix list accepted rows");
    require_true(result.accepted_sumstats.cols() == 4,
                 "matrix list accepted stats columns");
    require_near(result.accepted_sumstats(0, 0), 1.0, 1e-12,
                 "matrix list flattened value");
}

void test_matrix_helpers_and_bounds() {
    /* =========================
     * Matrix Helpers
     * ========================= */

    const abcpp::Matrix matrix = abcpp::from_row_major(
        std::vector<double>{1.0, 2.0, 3.0, 4.0},
        2,
        2
    );

    require_true(matrix.rows() == 2, "matrix rows");
    require_true(matrix.cols() == 2, "matrix cols");
    require_near(matrix(1, 0), 3.0, 1e-12, "row-major value");
    require_true(matrix.row(0).size() == 2, "matrix row size");
    require_true(matrix.col(1).size() == 2, "matrix column size");

    abcpp::Matrix writable(2, 2, 0.0);
    writable.set_row(0, std::vector<double>{5.0, 6.0});
    require_near(writable(0, 1), 6.0, 1e-12, "set row value");

    const abcpp::Matrix subset = abcpp::subset_rows(
        matrix,
        std::vector<std::size_t>{1}
    );
    require_true(subset.rows() == 1, "subset row count");
    require_near(subset(0, 1), 4.0, 1e-12, "subset value");

    require_throws<std::invalid_argument>(
        []() {
            abcpp::from_row_major(std::vector<double>{1.0}, 2, 2);
        },
        "row-major wrong length throws"
    );
    require_throws<std::out_of_range>(
        [&matrix]() {
            static_cast<void>(matrix(2, 0));
        },
        "matrix index throws"
    );
    require_throws<std::out_of_range>(
        [&matrix]() {
            static_cast<void>(matrix.row(2));
        },
        "matrix row index throws"
    );
    require_throws<std::out_of_range>(
        [&matrix]() {
            static_cast<void>(matrix.col(2));
        },
        "matrix column index throws"
    );
    require_throws<std::invalid_argument>(
        [&writable]() {
            writable.set_row(0, std::vector<double>{1.0});
        },
        "matrix set row wrong length throws"
    );
}

void test_statistics_helpers() {
    /* =========================
     * Statistics Helpers
     * ========================= */

    const double nan = std::numeric_limits<double>::quiet_NaN();
    const std::vector<double> values{1.0, 2.0, 3.0, 4.0, nan};
    require_near(abcpp::median(values), 2.5, 1e-12, "median finite values");
    require_near(
        abcpp::quantile_type7(values, 0.25),
        1.75,
        1e-12,
        "type 7 quantile"
    );
    require_near(abcpp::quantile_type7(values, 0.0), 1.0, 1e-12, "min");
    require_near(abcpp::quantile_type7(values, 1.0), 4.0, 1e-12, "max");
    require_near(abcpp::mean(values), 2.5, 1e-12, "mean finite values");
    require_near(
        abcpp::sample_sd(std::vector<double>{1.0, 2.0, 3.0}),
        1.0,
        1e-12,
        "sample sd"
    );
    require_true(
        std::isnan(abcpp::weighted_mean(
            std::vector<double>{1.0, 2.0},
            std::vector<double>{0.0, 0.0}
        )),
        "zero weight weighted mean is NaN"
    );
    require_throws<std::invalid_argument>(
        []() {
            abcpp::weighted_mean(
                std::vector<double>{1.0},
                std::vector<double>{1.0, 2.0}
            );
        },
        "weighted mean length mismatch throws"
    );

    abcpp::Matrix matrix = abcpp::from_row_major(
        std::vector<double>{1.0, 2.0, 3.0, 4.0},
        2,
        2
    );
    const std::vector<double> means = abcpp::column_means(matrix);
    require_near(means[0], 2.0, 1e-12, "column mean");

    const std::vector<double> mads = abcpp::column_mads(
        matrix,
        std::vector<bool>{true, false}
    );
    require_near(mads[0], 0.0, 1e-12, "single row mad");

    const std::vector<double> sse = abcpp::column_weighted_sse(
        matrix,
        std::vector<double>{1.0, 2.0}
    );
    require_near(sse[0], 19.0, 1e-12, "weighted sse");
    require_throws<std::invalid_argument>(
        [&matrix]() {
            abcpp::column_weighted_sse(matrix, std::vector<double>{1.0});
        },
        "weighted sse length mismatch throws"
    );

    require_near(
        abcpp::kernel_mode(std::vector<double>{2.0, 2.0}, {}),
        2.0,
        1e-12,
        "constant mode"
    );
    require_true(
        std::isnan(abcpp::kernel_mode(std::vector<double>{}, {})),
        "empty mode is NaN"
    );
}

void test_linear_algebra_helpers() {
    /* =========================
     * Linear Algebra Helpers
     * ========================= */

    const abcpp::Matrix left = abcpp::from_row_major(
        std::vector<double>{1.0, 2.0, 3.0, 4.0},
        2,
        2
    );
    const abcpp::Matrix right = abcpp::from_row_major(
        std::vector<double>{2.0, 0.0, 1.0, 2.0},
        2,
        2
    );
    const abcpp::Matrix product = abcpp::multiply(left, right);
    require_near(product(0, 0), 4.0, 1e-12, "matrix product");
    require_near(product(1, 1), 8.0, 1e-12, "matrix product");

    const std::vector<double> vector_product = abcpp::multiply(
        left,
        std::vector<double>{1.0, 1.0}
    );
    require_near(vector_product[1], 7.0, 1e-12, "matrix vector product");

    const abcpp::Matrix transposed = abcpp::transpose(left);
    require_near(transposed(0, 1), 3.0, 1e-12, "transpose");

    const abcpp::Matrix with_intercept = abcpp::add_intercept(left);
    require_near(with_intercept(1, 0), 1.0, 1e-12, "intercept column");
    require_near(with_intercept(1, 2), 4.0, 1e-12, "intercept data");

    const std::vector<double> solved = abcpp::solve_linear_system(
        abcpp::from_row_major(std::vector<double>{2.0, 1.0, 1.0, 3.0}, 2, 2),
        std::vector<double>{1.0, 2.0}
    );
    require_near(solved[0], 0.2, 1e-10, "linear solve first");
    require_near(solved[1], 0.6, 1e-10, "linear solve second");

    const abcpp::Matrix inverted = abcpp::inverse(
        abcpp::from_row_major(std::vector<double>{2.0, 0.0, 0.0, 4.0}, 2, 2)
    );
    require_near(inverted(0, 0), 0.5, 1e-12, "inverse first diag");
    require_near(inverted(1, 1), 0.25, 1e-12, "inverse second diag");

    const abcpp::Matrix design = abcpp::from_row_major(
        std::vector<double>{1.0, 0.0, 1.0, 1.0, 1.0, 2.0},
        3,
        2
    );
    const abcpp::Matrix response = abcpp::from_row_major(
        std::vector<double>{1.0, 3.0, 5.0},
        3,
        1
    );
    const abcpp::Matrix coef = abcpp::weighted_least_squares(
        design,
        response,
        std::vector<double>{1.0, 1.0, 1.0},
        0.0
    );
    require_near(coef(0, 0), 1.0, 1e-6, "least squares intercept");
    require_near(coef(1, 0), 2.0, 1e-6, "least squares slope");
    require_near(abcpp::predict(design, coef)(2, 0), 5.0, 1e-6, "predict");

    require_throws<std::invalid_argument>(
        [&left]() {
            abcpp::multiply(left, abcpp::Matrix(3, 1));
        },
        "matrix product shape throws"
    );
    require_throws<std::invalid_argument>(
        [&left]() {
            abcpp::multiply(left, std::vector<double>{1.0});
        },
        "matrix vector shape throws"
    );
    require_throws<std::invalid_argument>(
        []() {
            abcpp::solve_linear_system(abcpp::Matrix(2, 3), {1.0, 2.0});
        },
        "linear solve shape throws"
    );
    require_throws<std::invalid_argument>(
        []() {
            abcpp::inverse(abcpp::Matrix(2, 3));
        },
        "inverse shape throws"
    );
    require_throws<std::invalid_argument>(
        [&design, &response]() {
            abcpp::weighted_least_squares(
                design,
                response,
                std::vector<double>{1.0},
                0.0
            );
        },
        "least squares shape throws"
    );
}

void test_rejection_accepts_expected_rows() {
    /* =========================
     * Rejection ABC
     * ========================= */

    abcpp::Matrix param(5, 1);
    abcpp::Matrix sumstat(5, 1);
    for (std::size_t row = 0; row < 5; ++row) {
        param(row, 0) = static_cast<double>(row + 1);
        sumstat(row, 0) = static_cast<double>(row);
    }

    abcpp::AbcOptions options;
    options.method = abcpp::Method::Rejection;
    options.tol = 0.4;

    const abcpp::AbcResult result = abcpp::abc(
        std::vector<double>{1.1},
        param,
        sumstat,
        options
    );

    require_true(result.unadj_values.rows() == 2, "rejection row count");
    require_true(result.region[1], "nearest row one accepted");
    require_true(result.region[2], "nearest row two accepted");
    require_true(result.weights.rows() == 2, "rejection weights row count");
    require_near(result.weights(0, 0), 1.0, 1e-12, "rejection weights");
    require_true(result.adj_values.empty(), "rejection has no adjusted values");
    require_true(result.accepted_indices.size() == 2, "accepted indices");
    require_true(result.status == "ok", "result status");
    require_true(result.numparam == 1, "result parameter count");
    require_true(result.numstat == 1, "result statistic count");
}

void test_loclinear_runs_and_summarizes() {
    const std::size_t n = 80;
    abcpp::Matrix param(n, 2);
    abcpp::Matrix sumstat(n, 3);

    for (std::size_t row = 0; row < n; ++row) {
        const double x = static_cast<double>(row) / 10.0;
        sumstat(row, 0) = x;
        sumstat(row, 1) = std::sin(x);
        sumstat(row, 2) = std::cos(x);
        param(row, 0) = 0.2 + 0.1 * x;
        param(row, 1) = 0.8 - 0.05 * x;
    }

    abcpp::AbcOptions options;
    options.method = abcpp::Method::LocLinear;
    options.tol = 0.35;
    options.hcorr = false;

    const abcpp::AbcResult result = abcpp::abc(
        std::vector<double>{3.1, std::sin(3.1), std::cos(3.1)},
        param,
        sumstat,
        options
    );

    require_true(result.adj_values.rows() > 0, "loclinear rows");
    require_true(result.adj_values.cols() == 2, "loclinear columns");
    require_true(result.residuals.rows() == result.adj_values.rows(),
                 "loclinear residual row count");
    require_true(result.aic != 0.0, "loclinear aic");
    require_true(result.bic != 0.0, "loclinear bic");

    const abcpp::SummaryResult summary = abcpp::summary(result);
    require_true(summary.columns.size() == 2, "summary columns");
    require_finite(summary.columns[0].mean, "summary finite");

    const abcpp::SummaryResult unadjusted = abcpp::summary(
        result,
        true,
        0.80
    );
    require_true(unadjusted.unadjusted, "summary unadjusted flag");
    require_near(unadjusted.interval, 0.80, 1e-12, "summary interval");
}

void test_reductions_keep_requested_dimension() {
    const std::size_t n = 60;
    abcpp::Matrix param(n, 2);
    abcpp::Matrix sumstat(n, 5);

    for (std::size_t row = 0; row < n; ++row) {
        const double x = static_cast<double>(row) / 20.0;
        param(row, 0) = 0.3 + 0.2 * x;
        param(row, 1) = 0.7 - 0.1 * x;
        for (std::size_t col = 0; col < 5; ++col) {
            sumstat(row, col) = std::sin(x + static_cast<double>(col));
        }
    }

    abcpp::AbcOptions options;
    options.method = abcpp::Method::Ridge;
    options.tol = 0.5;
    options.hcorr = false;
    options.reduction.method = abcpp::ReductionMethod::PCA;
    options.reduction.n_comp = 2;

    const abcpp::AbcResult pca_result = abcpp::abc(
        std::vector<double>{
            std::sin(1.0),
            std::sin(2.0),
            std::sin(3.0),
            std::sin(4.0),
            std::sin(5.0)
        },
        param,
        sumstat,
        options
    );

    require_true(pca_result.numstat == 2, "pca dimension");
    require_true(pca_result.reduction.method == abcpp::ReductionMethod::PCA,
                 "pca method stored");
    require_true(pca_result.reduction.rotation.cols() == 2,
                 "pca rotation dimension");

    options.reduction.method = abcpp::ReductionMethod::PLS;
    const abcpp::AbcResult pls_result = abcpp::abc(
        std::vector<double>{
            std::sin(1.0),
            std::sin(2.0),
            std::sin(3.0),
            std::sin(4.0),
            std::sin(5.0)
        },
        param,
        sumstat,
        options
    );

    require_true(pls_result.numstat == 2, "pls dimension");
    require_true(pls_result.reduction.method == abcpp::ReductionMethod::PLS,
                 "pls method stored");
    require_true(pls_result.reduction.rotation.cols() == 2,
                 "pls rotation dimension");

    options.reduction.method = abcpp::ReductionMethod::None;
    const abcpp::ReducedSummary none = abcpp::reduce_summary_statistics(
        param,
        sumstat,
        std::vector<double>{1.0, 2.0, 3.0, 4.0, 5.0},
        options.reduction
    );
    require_true(none.sumstat.cols() == 5, "none reduction keeps columns");

    options.reduction.method = abcpp::ReductionMethod::PCA;
    options.reduction.n_comp = 100;
    const abcpp::ReducedSummary clipped = abcpp::reduce_summary_statistics(
        param,
        sumstat,
        std::vector<double>{1.0, 2.0, 3.0, 4.0, 5.0},
        options.reduction
    );
    require_true(clipped.info.n_comp == 5, "pca clips component count");

    require_throws<std::invalid_argument>(
        [&param, &sumstat, &options]() {
            abcpp::reduce_summary_statistics(
                param,
                sumstat,
                std::vector<double>{1.0},
                options.reduction
            );
        },
        "reduction target mismatch throws"
    );
}

void test_reduction_none_and_pls_contracts() {
    /* =========================
     * Reduction Contracts
     * ========================= */

    const std::size_t n = 48;
    abcpp::Matrix param = make_param_matrix(n, 2);
    abcpp::Matrix sumstat = make_sumstat_matrix(n, 4);
    const std::vector<double> target = make_target_from_row(sumstat, 20);

    abcpp::AbcOptions options;
    options.method = abcpp::Method::LocLinear;
    options.tol = 0.35;
    options.hcorr = false;

    options.reduction.method = abcpp::ReductionMethod::None;
    const abcpp::AbcResult none_result = abcpp::abc(
        target,
        param,
        sumstat,
        options
    );

    require_true(none_result.numstat == 4, "none abc keeps dimension");
    require_true(none_result.reduction.method == abcpp::ReductionMethod::None,
                 "none abc stores method");
    require_true(none_result.reduction.n_comp == 4,
                 "none abc stores component count");
    require_true(none_result.reduction.rotation.empty(),
                 "none abc has empty rotation");
    require_true(none_result.reduction.center.empty(),
                 "none abc has empty center");

    abcpp::ReductionOptions none_options;
    none_options.method = abcpp::ReductionMethod::None;
    const abcpp::ReducedSummary none_reduced =
        abcpp::reduce_summary_statistics(
            param,
            sumstat,
            target,
            none_options
        );

    require_true(none_reduced.sumstat.rows() == sumstat.rows(),
                 "none direct keeps rows");
    require_true(none_reduced.sumstat.cols() == sumstat.cols(),
                 "none direct keeps columns");
    require_true(none_reduced.target.size() == target.size(),
                 "none direct keeps target length");
    require_near(none_reduced.sumstat(10, 2), sumstat(10, 2), 1e-12,
                 "none direct keeps values");
    require_near(none_reduced.target[2], target[2], 1e-12,
                 "none direct keeps target values");
    require_true(none_reduced.info.method == abcpp::ReductionMethod::None,
                 "none direct stores method");
    require_true(none_reduced.info.n_comp == sumstat.cols(),
                 "none direct stores component count");

    abcpp::ReductionOptions pls_options;
    pls_options.method = abcpp::ReductionMethod::PLS;
    pls_options.n_comp = 2;
    const abcpp::ReducedSummary pls_reduced =
        abcpp::reduce_summary_statistics(
            param,
            sumstat,
            target,
            pls_options
        );

    require_true(pls_reduced.sumstat.rows() == sumstat.rows(),
                 "pls direct keeps row count");
    require_true(pls_reduced.sumstat.cols() == 2,
                 "pls direct reduces columns");
    require_true(pls_reduced.target.size() == 2,
                 "pls direct reduces target");
    require_true(pls_reduced.info.method == abcpp::ReductionMethod::PLS,
                 "pls direct stores method");
    require_true(pls_reduced.info.n_comp == 2,
                 "pls direct stores component count");
    require_true(pls_reduced.info.rotation.rows() == sumstat.cols(),
                 "pls direct rotation rows");
    require_true(pls_reduced.info.rotation.cols() == 2,
                 "pls direct rotation columns");
    require_true(pls_reduced.info.center.size() == sumstat.cols(),
                 "pls direct center length");
    require_finite(pls_reduced.sumstat(0, 0), "pls direct finite score");
    require_finite(pls_reduced.target[0], "pls direct finite target");

    options.reduction.method = abcpp::ReductionMethod::PLS;
    options.reduction.n_comp = 2;
    const abcpp::AbcResult pls_result = abcpp::abc(
        target,
        param,
        sumstat,
        options
    );

    require_true(pls_result.numstat == 2, "pls abc reduces dimension");
    require_true(pls_result.reduction.method == abcpp::ReductionMethod::PLS,
                 "pls abc stores method");
    require_true(pls_result.reduction.n_comp == 2,
                 "pls abc stores component count");
    require_true(pls_result.reduction.rotation.rows() == sumstat.cols(),
                 "pls abc rotation rows");
    require_true(pls_result.reduction.rotation.cols() == 2,
                 "pls abc rotation columns");
    require_true(pls_result.reduction.center.size() == sumstat.cols(),
                 "pls abc center length");
    require_true(pls_result.adj_values.rows() > 0,
                 "pls abc adjusted rows");
}

void test_matrix_target_and_stacked_sumstat_inputs() {
    /* =========================
     * Matrix Summary Inputs
     * ========================= */

    const std::size_t n = 36;
    abcpp::Matrix param = make_param_matrix(n, 2);
    abcpp::Matrix stacked_sumstat(n * 2, 2, 0.0);

    for (std::size_t row = 0; row < n; ++row) {
        const double x = static_cast<double>(row + 1) / 13.0;
        stacked_sumstat(row * 2, 0) = x;
        stacked_sumstat(row * 2, 1) = std::sin(x);
        stacked_sumstat(row * 2 + 1, 0) = std::cos(x);
        stacked_sumstat(row * 2 + 1, 1) = x * x;
    }

    abcpp::Matrix target(2, 2, 0.0);
    target(0, 0) = stacked_sumstat(10 * 2, 0);
    target(0, 1) = stacked_sumstat(10 * 2, 1);
    target(1, 0) = stacked_sumstat(10 * 2 + 1, 0);
    target(1, 1) = stacked_sumstat(10 * 2 + 1, 1);

    abcpp::AbcOptions options;
    options.method = abcpp::Method::Rejection;
    options.tol = 0.25;
    options.reduction.method = abcpp::ReductionMethod::None;

    const abcpp::AbcResult none_result = abcpp::abc(
        target,
        param,
        stacked_sumstat,
        options
    );

    require_true(none_result.numstat == 4,
                 "matrix target none flatten dimension");
    require_true(none_result.unadj_values.rows() > 0,
                 "matrix target none accepted rows");

    options.method = abcpp::Method::LocLinear;
    options.hcorr = false;
    options.reduction.method = abcpp::ReductionMethod::PLS;
    options.reduction.n_comp = 2;

    const abcpp::AbcResult pls_result = abcpp::abc(
        target,
        param,
        stacked_sumstat,
        options
    );

    require_true(pls_result.numstat == 2,
                 "matrix target pls reduced dimension");
    require_true(pls_result.reduction.method == abcpp::ReductionMethod::PLS,
                 "matrix target pls method");
    require_true(pls_result.adj_values.rows() > 0,
                 "matrix target pls adjusted rows");
}

void test_invalid_inputs() {
    /* =========================
     * ABC Input Validation
     * ========================= */

    abcpp::Matrix param(5, 1);
    abcpp::Matrix sumstat(5, 1);
    abcpp::AbcOptions options;

    require_throws<std::invalid_argument>(
        [&param, &options]() {
            abcpp::Matrix wrong_sumstat(4, 1);
            abcpp::abc(std::vector<double>{1.0}, param, wrong_sumstat,
                       options);
        },
        "mismatch rows should throw"
    );

    require_throws<std::invalid_argument>(
        [&param, &sumstat, &options]() {
            abcpp::abc(std::vector<double>{1.0, 2.0}, param, sumstat,
                       options);
        },
        "mismatch cols should throw"
    );

    require_throws<std::invalid_argument>(
        [&param, &sumstat, &options]() {
            abcpp::AbcOptions local = options;
            local.tol = 1.5;
            abcpp::abc(std::vector<double>{1.0}, param, sumstat, local);
        },
        "tol greater than one should throw"
    );

    require_throws<std::invalid_argument>(
        [&param, &sumstat, &options]() {
            abcpp::AbcOptions local = options;
            local.tol = 0.0;
            abcpp::abc(std::vector<double>{1.0}, param, sumstat, local);
        },
        "zero tolerance should throw"
    );

    require_throws<std::invalid_argument>(
        [&param, &sumstat, &options]() {
            abcpp::AbcOptions local = options;
            local.subset = std::vector<bool>{true, false};
            abcpp::abc(std::vector<double>{1.0}, param, sumstat, local);
        },
        "subset wrong length should throw"
    );

    require_throws<std::invalid_argument>(
        [&param, &sumstat, &options]() {
            abcpp::AbcOptions local = options;
            local.lambda.clear();
            abcpp::abc(std::vector<double>{1.0}, param, sumstat, local);
        },
        "empty lambda should throw"
    );

    require_throws<std::invalid_argument>(
        [&param, &sumstat, &options]() {
            abcpp::AbcOptions local = options;
            local.subset = std::vector<bool>{false, false, false, false,
                                             false};
            abcpp::abc(std::vector<double>{1.0}, param, sumstat, local);
        },
        "no valid row should throw"
    );

    require_throws<std::runtime_error>(
        [&options]() {
            abcpp::Matrix local_param(5, 1, 1.0);
            abcpp::Matrix local_sumstat(5, 1, 2.0);
            abcpp::AbcOptions local = options;
            local.method = abcpp::Method::LocLinear;
            local.tol = 1.0;
            abcpp::abc(std::vector<double>{2.0}, local_param, local_sumstat,
                       local);
        },
        "zero accepted variance should throw"
    );

    require_throws<std::invalid_argument>(
        []() {
            abcpp::Matrix local_param(5, 2, 1.0);
            abcpp::Matrix local_sumstat(5, 1, 1.0);
            abcpp::AbcOptions local;
            local.method = abcpp::Method::LocLinear;
            local.transformations = {abcpp::Transform::Log,
                                     abcpp::Transform::Logit,
                                     abcpp::Transform::None};
            abcpp::abc(std::vector<double>{1.0}, local_param, local_sumstat,
                       local);
        },
        "transform count mismatch should throw"
    );

    require_throws<std::invalid_argument>(
        []() {
            abcpp::Matrix local_param(5, 1, 0.5);
            abcpp::Matrix local_sumstat(5, 1, 1.0);
            abcpp::AbcOptions local;
            local.method = abcpp::Method::LocLinear;
            local.transformations = {abcpp::Transform::Logit};
            abcpp::abc(std::vector<double>{1.0}, local_param, local_sumstat,
                       local);
        },
        "missing logit bounds should throw"
    );

    require_throws<std::invalid_argument>(
        []() {
            abcpp::Matrix local_param(5, 1, 0.5);
            abcpp::Matrix local_sumstat(5, 1, 1.0);
            abcpp::AbcOptions local;
            local.method = abcpp::Method::LocLinear;
            local.transformations = {abcpp::Transform::Logit};
            local.logit_bounds = abcpp::from_row_major(
                std::vector<double>{1.0, 0.0},
                1,
                2
            );
            abcpp::abc(std::vector<double>{1.0}, local_param, local_sumstat,
                       local);
        },
        "invalid logit bounds should throw"
    );
}

void test_options_parsing() {
    /* =========================
     * Option Parsing
     * ========================= */

    require_true(abcpp::parse_method("Rejection") ==
                 abcpp::Method::Rejection, "parse rejection");
    require_true(abcpp::parse_method("loclinear") ==
                 abcpp::Method::LocLinear, "parse loclinear");
    require_true(abcpp::parse_method("ridge") ==
                 abcpp::Method::Ridge, "parse ridge");
    require_true(abcpp::parse_method("neuralnet") ==
                 abcpp::Method::NeuralNet, "parse neuralnet");

    require_true(abcpp::parse_kernel("gaussian") ==
                 abcpp::Kernel::Gaussian, "parse gaussian");
    require_true(abcpp::parse_kernel("epanechnikov") ==
                 abcpp::Kernel::Epanechnikov, "parse epanechnikov");
    require_true(abcpp::parse_kernel("rectangular") ==
                 abcpp::Kernel::Rectangular, "parse rectangular");
    require_true(abcpp::parse_kernel("triangular") ==
                 abcpp::Kernel::Triangular, "parse triangular");
    require_true(abcpp::parse_kernel("biweight") ==
                 abcpp::Kernel::Biweight, "parse biweight");
    require_true(abcpp::parse_kernel("cosine") ==
                 abcpp::Kernel::Cosine, "parse cosine");

    require_true(abcpp::parse_transform("none") ==
                 abcpp::Transform::None, "parse no transform");
    require_true(abcpp::parse_transform("log") ==
                 abcpp::Transform::Log, "parse log");
    require_true(abcpp::parse_transform("logit") ==
                 abcpp::Transform::Logit, "parse logit");

    require_true(abcpp::parse_reduction("") ==
                 abcpp::ReductionMethod::None, "parse empty reduction");
    require_true(abcpp::parse_reduction("null") ==
                 abcpp::ReductionMethod::None, "parse null reduction");
    require_true(abcpp::parse_reduction("pca") ==
                 abcpp::ReductionMethod::PCA, "parse pca");
    require_true(abcpp::parse_reduction("pls") ==
                 abcpp::ReductionMethod::PLS, "parse pls");

    require_true(abcpp::method_name(abcpp::Method::Ridge) == "ridge",
                 "method name");
    require_true(abcpp::kernel_name(abcpp::Kernel::Cosine) == "cosine",
                 "kernel name");
    require_true(abcpp::transform_name(abcpp::Transform::Logit) == "logit",
                 "transform name");
    require_true(abcpp::reduction_name(abcpp::ReductionMethod::PCA) == "PCA",
                 "reduction name");

    require_true(abcpp::method_name(static_cast<abcpp::Method>(100)) ==
                 "unknown", "unknown method name");
    require_true(abcpp::kernel_name(static_cast<abcpp::Kernel>(100)) ==
                 "unknown", "unknown kernel name");
    require_true(abcpp::transform_name(static_cast<abcpp::Transform>(100)) ==
                 "unknown", "unknown transform name");
    require_true(abcpp::reduction_name(
        static_cast<abcpp::ReductionMethod>(100)) == "unknown",
        "unknown reduction name");

    require_throws<std::invalid_argument>(
        []() {
            abcpp::parse_method("bad");
        },
        "invalid method throws"
    );
    require_throws<std::invalid_argument>(
        []() {
            abcpp::parse_kernel("bad");
        },
        "invalid kernel throws"
    );
    require_throws<std::invalid_argument>(
        []() {
            abcpp::parse_transform("bad");
        },
        "invalid transform throws"
    );
    require_throws<std::invalid_argument>(
        []() {
            abcpp::parse_reduction("bad");
        },
        "invalid reduction throws"
    );
}

void test_neuralnet_runs() {
    const std::size_t n = 40;
    abcpp::Matrix param(n, 1);
    abcpp::Matrix sumstat(n, 2);
    for (std::size_t row = 0; row < n; ++row) {
        param(row, 0) = static_cast<double>(row) / 10.0;
        sumstat(row, 0) = param(row, 0) * 2.0;
        sumstat(row, 1) = param(row, 0) * 3.0;
    }

    abcpp::AbcOptions options;
    options.method = abcpp::Method::NeuralNet;
    options.tol = 0.5;
    options.hcorr = true;
    options.numnet = 2;
    options.sizenet = 2;
    options.maxit = 50;

    const abcpp::AbcResult result = abcpp::abc(
        std::vector<double>{2.0, 3.0},
        param,
        sumstat,
        options
    );
    require_true(result.adj_values.rows() > 0, "neuralnet runs");
    require_true(result.lambda.size() == 2, "neuralnet lambda count");
    require_true(result.residuals.rows() == result.adj_values.rows(),
                 "neuralnet residual rows");
}

void test_ridge_with_hcorr() {
    const std::size_t n = 40;
    abcpp::Matrix param(n, 1);
    abcpp::Matrix sumstat(n, 1);
    for (std::size_t row = 0; row < n; ++row) {
        param(row, 0) = static_cast<double>(row) / 10.0;
        sumstat(row, 0) = param(row, 0) * 2.0;
    }

    abcpp::AbcOptions options;
    options.method = abcpp::Method::Ridge;
    options.tol = 0.5;
    options.hcorr = true;
    options.kernel = abcpp::Kernel::Gaussian;

    const abcpp::AbcResult result = abcpp::abc(
        std::vector<double>{2.0},
        param,
        sumstat,
        options
    );
    require_true(result.adj_values.rows() > 0, "ridge hcorr runs");
    require_true(result.residuals.rows() == result.adj_values.rows(),
                 "ridge residual rows");
}

void test_transforms() {
    const std::size_t n = 40;
    abcpp::Matrix param(n, 2);
    abcpp::Matrix sumstat(n, 1);
    for (std::size_t row = 0; row < n; ++row) {
        param(row, 0) = std::exp(static_cast<double>(row) / 10.0);
        param(row, 1) = 0.1 + 0.8 * (static_cast<double>(row) / n);
        sumstat(row, 0) = static_cast<double>(row) / 10.0;
    }

    abcpp::AbcOptions options;
    options.method = abcpp::Method::LocLinear;
    options.tol = 0.5;
    options.transformations = {abcpp::Transform::Log, abcpp::Transform::Logit};
    abcpp::Matrix bounds(2, 2);
    bounds(0, 0) = 0.0; bounds(0, 1) = 1.0; // not used for log
    bounds(1, 0) = 0.0; bounds(1, 1) = 1.0;
    options.logit_bounds = bounds;

    const abcpp::AbcResult result = abcpp::abc(
        std::vector<double>{2.0},
        param,
        sumstat,
        options
    );
    require_true(result.adj_values.rows() > 0, "transforms run");
    require_true(result.unadj_values(0, 0) > 0.0, "log back transform");
    require_true(result.unadj_values(0, 1) > 0.0 &&
                 result.unadj_values(0, 1) < 1.0,
                 "logit back transform");
}

void test_all_kernels_and_nonfinite_rows() {
    /* =========================
     * Kernels and NA Action
     * ========================= */

    abcpp::Matrix param = make_param_matrix(40, 1);
    abcpp::Matrix sumstat = make_sumstat_matrix(40, 2);
    sumstat(3, 0) = std::numeric_limits<double>::quiet_NaN();
    param(5, 0) = std::numeric_limits<double>::infinity();

    const std::vector<abcpp::Kernel> kernels{
        abcpp::Kernel::Epanechnikov,
        abcpp::Kernel::Rectangular,
        abcpp::Kernel::Gaussian,
        abcpp::Kernel::Triangular,
        abcpp::Kernel::Biweight,
        abcpp::Kernel::Cosine
    };

    for (abcpp::Kernel kernel : kernels) {
        abcpp::AbcOptions options;
        options.method = abcpp::Method::LocLinear;
        options.kernel = kernel;
        options.tol = 0.35;
        options.hcorr = false;

        const abcpp::AbcResult result = abcpp::abc(
            make_target_from_row(sumstat, 10),
            param,
            sumstat,
            options
        );

        require_true(!result.na_action[3], "nonfinite sumstat row excluded");
        require_true(!result.na_action[5], "nonfinite param row excluded");
        require_true(result.weights.rows() > 0, "kernel weights rows");
        for (std::size_t row = 0; row < result.weights.rows(); ++row) {
            require_true(result.weights(row, 0) >= 0.0,
                         "kernel weights nonnegative");
        }
        if (kernel == abcpp::Kernel::Gaussian) {
            require_true(result.unadj_values.rows() == 38,
                         "gaussian keeps all finite rows");
        }
    }
}

void test_subset_limits_accepted_rows() {
    /* =========================
     * Explicit Subset
     * ========================= */

    abcpp::Matrix param = make_param_matrix(10, 1);
    abcpp::Matrix sumstat = make_sumstat_matrix(10, 1);

    abcpp::AbcOptions options;
    options.method = abcpp::Method::Rejection;
    options.tol = 1.0;
    options.subset = std::vector<bool>{true, false, true, false, true,
                                       false, true, false, true, false};

    const abcpp::AbcResult result = abcpp::abc(
        make_target_from_row(sumstat, 0),
        param,
        sumstat,
        options
    );

    require_true(result.unadj_values.rows() == 5, "subset accepted rows");
    require_true(result.region[0], "subset keeps first row");
    require_true(!result.region[1], "subset removes second row");
}

}  // namespace

int main() {
    try {
        test_minimal_cpp_smoke();
        test_matrix_sumstat_list_flattens();
        test_matrix_helpers_and_bounds();
        test_statistics_helpers();
        test_linear_algebra_helpers();
        test_rejection_accepts_expected_rows();
        test_loclinear_runs_and_summarizes();
        test_reductions_keep_requested_dimension();
        test_reduction_none_and_pls_contracts();
        test_matrix_target_and_stacked_sumstat_inputs();
        test_invalid_inputs();
        test_options_parsing();
        test_neuralnet_runs();
        test_ridge_with_hcorr();
        test_transforms();
        test_all_kernels_and_nonfinite_rows();
        test_subset_limits_accepted_rows();
    } catch (const std::exception& error) {
        std::cerr << error.what() << "\n";
        return 1;
    }

    std::cout << "abcpp core tests passed\n";
    return 0;
}
