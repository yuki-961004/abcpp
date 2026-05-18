testthat::test_that("abcpp::abc returns the expected object fields", {
  data <- abcpp_test_data()

  result <- abcpp::abc(
    target = data$target,
    param = data$param,
    sumstat = data$sumstat,
    tol = 0.10,
    method = "rejection",
    transf = base::rep("none", 2L)
  )

  testthat::expect_s3_class(result, "abcpp")
  testthat::expect_true(
    base::all(abcpp_expected_fields() %in% base::names(result))
  )
  testthat::expect_identical(result$method, "rejection")
  testthat::expect_equal(result$numparam, 2L)
  testthat::expect_equal(result$numstat, 4L)
})

testthat::test_that("rejection ABC accepts the expected number of rows", {
  data <- abcpp_test_data()
  tol <- 0.125

  result <- abcpp::abc(
    target = data$target,
    param = data$param,
    sumstat = data$sumstat,
    tol = tol,
    method = "rejection",
    transf = base::rep("none", 2L)
  )

  expected_count <- base::ceiling(base::nrow(data$param) * tol)
  testthat::expect_equal(base::sum(result$region), expected_count)
  testthat::expect_equal(base::nrow(result$unadj.values), expected_count)

  accepted_distance <- result$dist[result$region]
  rejected_distance <- result$dist[!result$region]
  testthat::expect_lte(
    base::max(accepted_distance),
    base::min(rejected_distance)
  )
})

testthat::test_that("loclinear ABC can run", {
  data <- abcpp_test_data()

  result <- abcpp::abc(
    target = data$target,
    param = data$param,
    sumstat = data$sumstat,
    tol = 0.20,
    method = "loclinear",
    hcorr = FALSE,
    transf = base::rep("none", 2L)
  )

  testthat::expect_identical(result$method, "loclinear")
  testthat::expect_equal(base::ncol(result$adj.values), 2L)
  testthat::expect_true(base::all(base::is.finite(result$adj.values)))
})

testthat::test_that("ridge ABC can run", {
  data <- abcpp_test_data()

  result <- abcpp::abc(
    target = data$target,
    param = data$param,
    sumstat = data$sumstat,
    tol = 0.20,
    method = "ridge",
    hcorr = FALSE,
    transf = base::rep("none", 2L),
    lambda = c(0.001, 0.01)
  )

  testthat::expect_identical(result$method, "ridge")
  testthat::expect_equal(base::ncol(result$adj.values), 2L)
  testthat::expect_true(base::all(base::is.finite(result$adj.values)))
})

testthat::test_that("neuralnet ABC can run", {
  data <- abcpp_test_data()

  result <- abcpp::abc(
    target = data$target,
    param = data$param,
    sumstat = data$sumstat,
    tol = 0.20,
    method = "neuralnet",
    hcorr = FALSE,
    transf = base::rep("none", 2L),
    numnet = 3L,
    sizenet = 4L,
    lambda = c(0.001),
    seed = 1004L
  )

  testthat::expect_identical(result$method, "neuralnet")
  testthat::expect_equal(base::ncol(result$adj.values), 2L)
  testthat::expect_true(base::all(base::is.finite(result$adj.values)))
  testthat::expect_equal(base::length(result$lambda), 3L)
})
