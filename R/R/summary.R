#' Summarize an abcpp Posterior
#'
#' Summarizes posterior samples returned by [abc()].
#'
#' @param object An object of class `"abcpp"` returned by [abc()].
#' @param unadj Logical. If `TRUE`, summarize unadjusted rejection samples even
#'   when regression-adjusted values are available.
#' @param intvl Credible interval width used for lower and upper posterior
#'   summaries.
#' @param ... Additional arguments for S3 compatibility.
#'
#' @return A list of class \code{"summary.abcpp"} containing the following components:
#'   \itemize{
#'     \item \code{statistics}: A matrix of posterior summary statistics for each parameter. The rows include Minimum, Lower endpoint, Median, Mean, Upper endpoint, Maximum, and Standard Deviation.
#'     \item \code{unadjusted}: A logical value indicating whether the unadjusted samples were summarized.
#'     \item \code{interval}: The numeric credible interval width specified by the user.
#'     \item \code{method}: The ABC method inherited from the fitted \code{abcpp} object.
#'   }
#'
#' @details
#' The summary extracts the relevant posterior samples and calculates the minimum, lower interval
#' endpoint, median, mean, upper interval endpoint, maximum, and standard deviation for each parameter.
#'
#' For \code{method = "rejection"}, or when adjusted values are not available, unadjusted samples are
#' always summarized. When an adjusted method is used (e.g., \code{"loclinear"}), the adjusted samples
#' are summarized by default unless \code{unadj = TRUE} is specified.
#'
#' @examples
#' set.seed(1004)
#' n <- 200L
#' param <- cbind(theta = stats::runif(n))
#' sumstat <- cbind(s = param[, 1] + stats::rnorm(n, sd = 0.05))
#' fit <- abc(
#'   target = c(0.5),
#'   params = param,
#'   sumstats = sumstat,
#'   control = list(tol = 0.1)
#' )
#' summary(fit)
#'
#' @export
summary.abcpp <- function(
    object,
    unadj = FALSE,
    intvl = 0.95,
    ...
) {
    use_unadj <- unadj || object$method == "rejection" ||
        base::is.null(object$adj.values)
    values <- if (use_unadj) object$unadj.values else object$adj.values

    lower <- (1 - intvl) / 2
    upper <- 1 - lower

    summary_matrix <- base::rbind(
        Min = base::apply(values, 2L, stats::quantile, probs = 0),
        Lower = base::apply(values, 2L, stats::quantile, probs = lower),
        Median = base::apply(values, 2L, stats::median),
        Mean = base::apply(values, 2L, base::mean),
        Upper = base::apply(values, 2L, stats::quantile, probs = upper),
        Max = base::apply(values, 2L, stats::quantile, probs = 1),
        SD = base::apply(values, 2L, stats::sd)
    )

    out <- base::list(
        statistics = summary_matrix,
        unadjusted = use_unadj,
        interval = intvl,
        method = object$method
    )
    base::class(out) <- "summary.abcpp"
    out
}
