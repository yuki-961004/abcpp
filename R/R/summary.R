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
