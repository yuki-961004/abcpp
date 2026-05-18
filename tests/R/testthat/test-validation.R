testthat::test_that("dimension mismatch raises an error", {
  data <- abcpp_test_data()

  testthat::expect_error(
    abcpp::abc(
      target = data$target[-1L],
      param = data$param,
      sumstat = data$sumstat,
      tol = 0.10,
      method = "rejection"
    ),
    "target summary dimension"
  )

  testthat::expect_error(
    abcpp::abc(
      target = data$target,
      param = data$param[-1L, ],
      sumstat = data$sumstat,
      tol = 0.10,
      method = "rejection"
    ),
    "param.rows"
  )
})

testthat::test_that("invalid method and reduction raise errors", {
  data <- abcpp_test_data()

  testthat::expect_error(
    abcpp::abc(
      target = data$target,
      param = data$param,
      sumstat = data$sumstat,
      tol = 0.10,
      method = "bad_method"
    ),
    "Unknown ABC method"
  )

  testthat::expect_error(
    abcpp::abc(
      target = data$target,
      param = data$param,
      sumstat = data$sumstat,
      tol = 0.10,
      method = "rejection",
      reduce = "bad_reduction"
    ),
    "Unknown summary reduction"
  )
})

testthat::test_that("invalid tolerance raises an error", {
  data <- abcpp_test_data()

  testthat::expect_error(
    abcpp::abc(
      target = data$target,
      param = data$param,
      sumstat = data$sumstat,
      tol = 0,
      method = "rejection"
    ),
    "tol must be"
  )
})

testthat::test_that("subset changes accepted rows consistently", {
  data <- abcpp_test_data()
  subset <- base::rep(TRUE, base::nrow(data$param))
  subset[base::seq(from = 1L, to = base::length(subset), by = 2L)] <- FALSE

  result <- abcpp::abc(
    target = data$target,
    param = data$param,
    sumstat = data$sumstat,
    tol = 0.10,
    method = "rejection",
    transf = base::rep("none", 2L),
    subset = subset
  )

  testthat::expect_true(base::all(!result$region[!subset]))
  testthat::expect_true(base::all(result$na.action == subset))
})

testthat::test_that("matrix target and stacked summary statistics work", {
  data <- abcpp_test_data()
  target_matrix <- base::matrix(data$target[1L:2L], nrow = 1L)
  sumstat_matrix <- data$sumstat[, 1L:2L]

  result_none <- abcpp::abc(
    target = target_matrix,
    param = data$param,
    sumstat = sumstat_matrix,
    tol = 0.10,
    method = "rejection",
    reduction = "none"
  )

  testthat::expect_equal(result_none$numstat, 2L)

  stacked_sumstat <- base::matrix(
    base::as.vector(base::t(sumstat_matrix)),
    ncol = 1L
  )
  target_stacked <- base::matrix(data$target[1L:2L], nrow = 2L)

  result_pls <- abcpp::abc(
    target = target_stacked,
    param = data$param,
    sumstat = stacked_sumstat,
    tol = 0.30,
    method = "loclinear",
    hcorr = FALSE,
    reduction = "pls",
    ncomp = 1L
  )

  testthat::expect_equal(result_pls$numstat, 1L)
  testthat::expect_identical(result_pls$reduction$method, "PLS")
})

testthat::test_that("matrix target and list summary statistics work", {
  param <- base::matrix(seq(0, 4), ncol = 1L)
  sumstats <- base::lapply(seq(0, 4), function(value) {
    base::matrix(
      base::c(value, value + 0.1, value + 0.2, value + 0.3),
      nrow = 2L,
      byrow = TRUE
    )
  })
  target <- base::matrix(
    base::c(2, 2.1, 2.2, 2.3),
    nrow = 2L,
    byrow = TRUE
  )

  result <- abcpp::abc(
    target = target,
    param = param,
    sumstat = sumstats,
    tol = 0.40,
    method = "rejection",
    reduction = "none"
  )

  testthat::expect_equal(result$numstat, 4L)
  testthat::expect_equal(base::nrow(result$unadj.values), 2L)
  testthat::expect_equal(base::ncol(result$ss), 4L)
  testthat::expect_s3_class(base::summary(result), "summary.abcpp")
})

testthat::test_that("one-row parameter matrix is treated as one parameter", {
  data <- abcpp_test_data()
  param_row <- base::matrix(data$param[, 1L], nrow = 1L)

  result <- abcpp::abc(
    target = data$target,
    param = param_row,
    sumstat = data$sumstat,
    tol = 0.10,
    method = "rejection"
  )

  testthat::expect_equal(result$numparam, 1L)
  testthat::expect_equal(base::ncol(result$unadj.values), 1L)
})
