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

testthat::test_that("R wrapper accepts null control and data frame inputs", {
  data <- abcpp_test_data()
  params <- base::as.data.frame(data$param)
  sumstats <- base::as.data.frame(data$sumstat)
  base::names(params) <- c("theta_a", "theta_b")
  base::names(sumstats) <- base::paste0("stat_", base::seq_len(
    base::ncol(sumstats)
  ))

  result <- abcpp::abc(
    target = data$target,
    params = params,
    sumstats = sumstats,
    control = NULL
  )

  testthat::expect_identical(result$options$method, "rejection")
  testthat::expect_equal(result$names$parameter.names, base::names(params))
  testthat::expect_equal(result$names$statistics.names, base::names(sumstats))
  testthat::expect_equal(base::colnames(result$unadj.values), base::names(params))
})

testthat::test_that("R wrapper rejects non-list control", {
  data <- abcpp_test_data()

  testthat::expect_error(
    abcpp::abc(
      target = data$target,
      params = data$param,
      sumstats = data$sumstat,
      control = "bad"
    ),
    "control must be a list"
  )
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

testthat::test_that("logit transforms use explicit bounds", {
  data <- abcpp_test_data()

  result <- abcpp::abc(
    target = data$target,
    params = data$param,
    sumstats = data$sumstat,
    control = list(
      method = "loclinear",
      tol = 0.20,
      hcorr = FALSE,
      transf = base::rep("logit", 2L),
      logit.bounds = base::matrix(
        base::c(0, 1, 0, 1),
        nrow = 2L,
        byrow = TRUE
      )
    )
  )

  testthat::expect_true(base::all(base::is.finite(result$adj.values)))
  testthat::expect_true(base::all(result$adj.values > 0))
  testthat::expect_true(base::all(result$adj.values < 1))
})

testthat::test_that("prior.weights scale regression weights", {
  data <- abcpp_test_data()
  prior_weights <- base::seq_len(base::nrow(data$param)) / 10

  no_prior <- abcpp::abc(
    target = data$target,
    params = data$param,
    sumstats = data$sumstat,
    control = list(
      method = "loclinear",
      tol = 0.20,
      hcorr = FALSE,
      kernel = "gaussian",
      transf = base::rep("none", 2L)
    )
  )
  weighted <- abcpp::abc(
    target = data$target,
    params = data$param,
    sumstats = data$sumstat,
    control = list(
      method = "loclinear",
      tol = 0.20,
      hcorr = FALSE,
      kernel = "gaussian",
      transf = base::rep("none", 2L),
      prior.weights = prior_weights
    )
  )

  testthat::expect_equal(weighted$accepted.indices, no_prior$accepted.indices)
  testthat::expect_equal(
    base::as.vector(weighted$weights),
    base::as.vector(no_prior$weights) *
      prior_weights[weighted$accepted.indices]
  )
  testthat::expect_equal(weighted$options$prior.weights, prior_weights)
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
