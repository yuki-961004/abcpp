testthat::test_that("reduce none leaves summary dimension unchanged", {
  data <- abcpp_test_data()

  result <- abcpp::abc(
    target = data$target,
    param = data$param,
    sumstat = data$sumstat,
    tol = 0.20,
    method = "loclinear",
    hcorr = FALSE,
    transf = base::rep("none", 2L),
    reduce = "none"
  )

  testthat::expect_equal(result$numstat, base::ncol(data$sumstat))
  testthat::expect_identical(result$reduction$method, "none")
})

testthat::test_that("PCA reduction returns requested dimension", {
  data <- abcpp_test_data()

  result <- abcpp::abc(
    target = data$target,
    param = data$param,
    sumstat = data$sumstat,
    tol = 0.20,
    method = "ridge",
    hcorr = FALSE,
    transf = base::rep("none", 2L),
    reduce = "pca",
    ncomp = 2L
  )

  testthat::expect_equal(result$numstat, 2L)
  testthat::expect_identical(result$reduction$method, "PCA")
  testthat::expect_equal(base::ncol(result$reduction$rotation), 2L)
})

testthat::test_that("PLS reduction returns requested dimension", {
  data <- abcpp_test_data()

  result <- abcpp::abc(
    target = data$target,
    param = data$param,
    sumstat = data$sumstat,
    tol = 0.20,
    method = "ridge",
    hcorr = FALSE,
    transf = base::rep("none", 2L),
    reduction = "pls",
    ncomp = 2L
  )

  testthat::expect_equal(result$numstat, 2L)
  testthat::expect_identical(result$reduction$method, "PLS")
  testthat::expect_equal(base::ncol(result$reduction$rotation), 2L)
})
