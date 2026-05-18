testthat::test_that("rejection matches R package abc without reduction", {
  testthat::skip_if_not_installed("abc")
  data <- abcpp_test_data()
  tol <- 0.10

  r_result <- base::suppressWarnings(abc::abc(
    target = data$target,
    param = data$param,
    sumstat = data$sumstat,
    tol = tol,
    method = "rejection"
  ))

  cpp_result <- abcpp::abc(
    target = data$target,
    param = data$param,
    sumstat = data$sumstat,
    tol = tol,
    method = "rejection",
    transf = base::rep("none", 2L),
    reduction = "none"
  )

  nacc <- base::ceiling(base::nrow(data$param) * tol)
  testthat::expect_equal(base::sum(cpp_result$region), nacc)
  testthat::expect_identical(cpp_result$region, r_result$region)

  testthat::expect_identical(
    base::order(cpp_result$dist)[base::seq_len(nacc)],
    base::order(r_result$dist)[base::seq_len(nacc)]
  )
  abcpp_compare_matrix(r_result$unadj.values, cpp_result$unadj.values, 1e-10)
})

testthat::test_that("loclinear matches R package abc without reduction", {
  testthat::skip_if_not_installed("abc")
  data <- abcpp_test_data()
  tol <- 0.15

  r_result <- base::suppressWarnings(abc::abc(
    target = data$target,
    param = data$param,
    sumstat = data$sumstat,
    tol = tol,
    method = "loclinear",
    hcorr = FALSE,
    transf = base::rep("none", 2L)
  ))

  cpp_result <- abcpp::abc(
    target = data$target,
    param = data$param,
    sumstat = data$sumstat,
    tol = tol,
    method = "loclinear",
    hcorr = FALSE,
    transf = base::rep("none", 2L),
    reduction = "none"
  )

  abcpp_compare_matrix(r_result$unadj.values, cpp_result$unadj.values, 1e-10)

  # lsfit and the C++ linear solver can differ at tiny numeric edges.
  abcpp_compare_matrix(r_result$adj.values, cpp_result$adj.values, 5e-2)

  r_mean <- base::colMeans(r_result$adj.values)
  cpp_mean <- base::colMeans(cpp_result$adj.values)
  testthat::expect_equal(cpp_mean, r_mean, tolerance = 5e-2)
})

testthat::test_that("ridge matches R package abc without reduction", {
  testthat::skip_if_not_installed("abc")
  data <- abcpp_test_data()
  tol <- 0.15

  r_result <- base::suppressWarnings(abc::abc(
    target = data$target,
    param = data$param,
    sumstat = data$sumstat,
    tol = tol,
    method = "ridge",
    hcorr = FALSE,
    transf = base::rep("none", 2L),
    lambda = c(0)
  ))

  cpp_result <- abcpp::abc(
    target = data$target,
    param = data$param,
    sumstat = data$sumstat,
    tol = tol,
    method = "ridge",
    hcorr = FALSE,
    transf = base::rep("none", 2L),
    lambda = c(0),
    reduction = "none"
  )

  abcpp_compare_matrix(r_result$unadj.values, cpp_result$unadj.values, 1e-10)

  # MASS::lm.ridge and the C++ implementation are compared by posterior center.
  testthat::expect_equal(
    base::colMeans(cpp_result$adj.values),
    base::colMeans(r_result$adj.values),
    tolerance = 5e-2
  )
})
