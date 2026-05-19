testthat::test_that("reduction none leaves summary dimension unchanged", {
  data <- abcpp_test_data()

  result <- abcpp::abc(
    target = data$target,
    params = data$param,
    sumstats = data$sumstat,
    control = list(
      method = "loclinear",
      tol = 0.20,
      hcorr = FALSE,
      transf = base::rep("none", 2L),
      reduction = "none"
    )
  )

  testthat::expect_equal(result$numstat, base::ncol(data$sumstat))
  testthat::expect_identical(result$reduction$method, "none")
})

testthat::test_that("PCA reduction returns requested dimension", {
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
      reduction = "pca",
      n_comp = 2L
    )
  )

  testthat::expect_equal(result$numstat, 2L)
  testthat::expect_identical(result$reduction$method, "PCA")
  testthat::expect_equal(base::ncol(result$reduction$rotation), 2L)
})

testthat::test_that("PLS reduction returns requested dimension", {
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
      reduction = "pls",
      n_comp = 2L
    )
  )

  testthat::expect_equal(result$numstat, 2L)
  testthat::expect_identical(result$reduction$method, "PLS")
  testthat::expect_equal(base::ncol(result$reduction$rotation), 2L)
})
