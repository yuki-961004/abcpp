abcpp_test_data <- function(n = 240L) {
  ############################
  # Toy Simulation Data
  ############################

  # 使用确定性网格, 让距离排序和接受样本数量可重复.
  theta_1 <- base::seq(from = 0.05, to = 0.95, length.out = n)
  theta_2 <- base::seq(from = 0.90, to = 0.10, length.out = n)

  param <- base::cbind(
    theta_1 = theta_1,
    theta_2 = theta_2
  )

  sumstat <- base::cbind(
    s1 = theta_1,
    s2 = theta_2,
    s3 = theta_1 * theta_2,
    s4 = base::sin(theta_1 * base::pi)
  )

  target <- base::c(
    s1 = 0.45,
    s2 = 0.55,
    s3 = 0.45 * 0.55,
    s4 = base::sin(0.45 * base::pi)
  )

  base::list(
    param = param,
    sumstat = sumstat,
    target = target
  )
}

abcpp_expected_fields <- function() {
  base::c(
    "adj.values",
    "unadj.values",
    "ss",
    "weights",
    "residuals",
    "dist",
    "accepted.indices",
    "region",
    "na.action",
    "transf",
    "logit.bounds",
    "method",
    "kernel",
    "hcorr",
    "lambda",
    "numparam",
    "numstat",
    "aic",
    "bic",
    "status",
    "message",
    "options",
    "diagnostics",
    "reduction",
    "names",
    "call"
  )
}

abcpp_compare_matrix <- function(left, right, tolerance) {
  testthat::expect_equal(
    base::as.matrix(left),
    base::as.matrix(right),
    tolerance = tolerance,
    ignore_attr = TRUE
  )
}
