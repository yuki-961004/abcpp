testthat::test_that("installed headers support LinkingTo use", {
  include_dir <- base::system.file("include", "abcpp", package = "abcpp")
  testthat::expect_true(base::dir.exists(include_dir))
  testthat::expect_true(base::file.exists(
    base::file.path(include_dir, "abc.hpp")
  ))
  testthat::expect_true(base::file.exists(
    base::file.path(include_dir, "abcpp_impl.hpp")
  ))

  source_file <- base::tempfile(fileext = ".cpp")
  base::writeLines(
    text = base::c(
      "// [[Rcpp::plugins(cpp17)]]",
      "// [[Rcpp::depends(abcpp)]]",
      "#include <Rcpp.h>",
      "#define ABCPP_IMPLEMENTATION",
      "#include <abcpp/abcpp.hpp>",
      "",
      "// [[Rcpp::export]]",
      "int abcpp_linkingto_smoke() {",
      "    abcpp::Matrix param(4, 1, 0.0);",
      "    abcpp::Matrix sumstat(4, 1, 0.0);",
      "    for (std::size_t row = 0; row < 4; ++row) {",
      "        param(row, 0) = static_cast<double>(row);",
      "        sumstat(row, 0) = static_cast<double>(row);",
      "    }",
      "    abcpp::AbcOptions options;",
      "    options.method = abcpp::Method::Rejection;",
      "    options.tol = 0.5;",
      "    const abcpp::AbcResult fit = abcpp::abc(",
      "        std::vector<double>{1.1},",
      "        param,",
      "        sumstat,",
      "        options",
      "    );",
      "    const abcpp::SummaryResult summary = abcpp::summary(fit);",
      "    return static_cast<int>(",
      "        fit.unadj_values.rows() + summary.columns.size()",
      "    );",
      "}"
    ),
    con = source_file
  )

  env <- base::new.env(parent = base::globalenv())
  Rcpp::sourceCpp(source_file, env = env, rebuild = TRUE, verbose = FALSE)
  testthat::expect_equal(env$abcpp_linkingto_smoke(), 3L)
})
