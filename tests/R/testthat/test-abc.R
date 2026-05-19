testthat::test_that("abcpp::abc returns the expected object fields", {
  data <- abcpp_test_data()

  result <- abcpp::abc(
    target = data$target,
    params = data$param,
    sumstats = data$sumstat
  )

  testthat::expect_s3_class(result, "abcpp")
  testthat::expect_true(
    base::all(abcpp_expected_fields() %in% base::names(result))
  )
  testthat::expect_identical(result$method, "rejection")
  testthat::expect_equal(result$numparam, 2L)
  testthat::expect_equal(result$numstat, 4L)
})

testthat::test_that("partial control overrides defaults", {
  data <- abcpp_test_data()

  result <- abcpp::abc(
    target = data$target,
    params = data$param,
    sumstats = data$sumstat,
    control = list(tol = 0.125)
  )

  expected_count <- base::ceiling(base::nrow(data$param) * 0.125)
  testthat::expect_equal(base::sum(result$region), expected_count)
  testthat::expect_equal(result$options$method, "rejection")
  testthat::expect_equal(result$options$tol, 0.125)
})

testthat::test_that("loclinear ABC can run", {
  data <- abcpp_test_data()

  result <- abcpp::abc(
    target = data$target,
    params = data$param,
    sumstats = data$sumstat,
    control = list(
      method = "loclinear",
      tol = 0.20,
      hcorr = FALSE,
      transf = base::rep("none", 2L)
    )
  )

  testthat::expect_identical(result$method, "loclinear")
  testthat::expect_equal(base::ncol(result$adj.values), 2L)
  testthat::expect_true(base::all(base::is.finite(result$adj.values)))
})

testthat::test_that("ridge ABC can run", {
  data <- abcpp_test_data()

  result <- abcpp::abc(
    target = data$target,
    params = data$param,
    sumstats = data$sumstat,
    control = list(
      method = "ridge",
      tol = 0.20,
      hcorr = FALSE,
      transf = base::rep("none", 2L),
      nnet = list(lambda = c(0.001, 0.01))
    )
  )

  testthat::expect_identical(result$method, "ridge")
  testthat::expect_equal(base::ncol(result$adj.values), 2L)
  testthat::expect_true(base::all(base::is.finite(result$adj.values)))
})

testthat::test_that("neuralnet ABC can run with nested nnet control", {
  data <- abcpp_test_data()

  result <- abcpp::abc(
    target = data$target,
    params = data$param,
    sumstats = data$sumstat,
    control = list(
      method = "neuralnet",
      tol = 0.20,
      hcorr = FALSE,
      transf = base::rep("none", 2L),
      seed = 1004L,
      nnet = list(
        numnet = 3L,
        sizenet = 4L,
        lambda = c(0.001),
        rang = 0.5,
        abstol = 1e-4,
        reltol = 1e-8,
        verbose = FALSE,
        skip = TRUE
      )
    )
  )

  testthat::expect_identical(result$method, "neuralnet")
  testthat::expect_equal(base::ncol(result$adj.values), 2L)
  testthat::expect_true(base::all(base::is.finite(result$adj.values)))
  testthat::expect_equal(base::length(result$lambda), 3L)
  testthat::expect_equal(result$options$nnet$sizenet, 4L)
  testthat::expect_true(result$options$nnet$skip)
})
