base::library("abcpp", character.only = TRUE)

make_summary_fixture <- function(method = "loclinear", adj_values = NULL) {
    unadj_values <- base::matrix(
        data = c(1, 2, 3, 4, 5, 6),
        nrow = 3L,
        ncol = 2L
    )
    if (base::is.null(adj_values)) {
        adj_values <- base::matrix(
            data = c(10, 20, 30, 40, 50, 60),
            nrow = 3L,
            ncol = 2L
        )
    }

    base::structure(
        base::list(
            unadj.values = unadj_values,
            adj.values = adj_values,
            method = method
        ),
        class = "abcpp"
    )
}

testthat::test_that("summary uses unadjusted values for rejection", {
    object <- make_summary_fixture(method = "rejection")
    result <- base::summary(object)

    testthat::expect_s3_class(result, "summary.abcpp")
    testthat::expect_true(result$unadjusted)
    testthat::expect_equal(result$method, "rejection")
    testthat::expect_equal(base::unname(result$statistics["Mean", 1L]), 2)
})

testthat::test_that("summary uses adjusted values by default", {
    object <- make_summary_fixture(method = "loclinear")
    result <- base::summary(object)

    testthat::expect_false(result$unadjusted)
    testthat::expect_equal(result$method, "loclinear")
    testthat::expect_equal(base::unname(result$statistics["Mean", 1L]), 20)
})

testthat::test_that("summary unadj flag overrides adjusted values", {
    object <- make_summary_fixture(method = "ridge")
    result <- base::summary(object, unadj = TRUE)

    testthat::expect_true(result$unadjusted)
    testthat::expect_equal(base::unname(result$statistics["Mean", 1L]), 2)
})

testthat::test_that("summary falls back when adjusted values are missing", {
    object <- make_summary_fixture(method = "loclinear", adj_values = NULL)
    object$adj.values <- NULL
    result <- base::summary(object)

    testthat::expect_true(result$unadjusted)
    testthat::expect_equal(base::unname(result$statistics["Mean", 1L]), 2)
})

testthat::test_that("summary interval controls lower and upper quantiles", {
    object <- make_summary_fixture(method = "loclinear")
    result <- base::summary(object, intvl = 0.50)
    expected_lower <- stats::quantile(object$adj.values[, 1L], probs = 0.25)
    expected_upper <- stats::quantile(object$adj.values[, 1L], probs = 0.75)

    testthat::expect_equal(result$interval, 0.50)
    testthat::expect_equal(
        base::unname(result$statistics["Lower", 1L]),
        base::unname(expected_lower)
    )
    testthat::expect_equal(
        base::unname(result$statistics["Upper", 1L]),
        base::unname(expected_upper)
    )
})

testthat::test_that("summary output contains expected fields and rows", {
    object <- make_summary_fixture(method = "neuralnet")
    result <- base::summary(object)

    testthat::expect_named(
        result,
        base::c("statistics", "unadjusted", "interval", "method")
    )
    testthat::expect_equal(
        base::rownames(result$statistics),
        base::c("Min", "Lower", "Median", "Mean", "Upper", "Max", "SD")
    )
})
