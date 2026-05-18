abc <- function(
    target,
    param,
    sumstat,
    tol,
    method,
    hcorr = TRUE,
    transf = "none",
    logit.bounds = NULL,
    subset = NULL,
    kernel = "epanechnikov",
    numnet = 10L,
    sizenet = 5L,
    lambda = base::c(0.0001, 0.001, 0.01),
    trace = FALSE,
    maxit = 500L,
    reduction = NULL,
    n_comp = NULL,
    seed = 1004L,
    ...
) {
    param_matrix <- base::as.matrix(param)
    sumstat_is_list <- base::is.list(sumstat) &&
        !base::is.data.frame(sumstat) &&
        base::length(sumstat) > 0L &&
        base::all(base::vapply(
            X = sumstat,
            FUN = function(value) {
                base::is.matrix(value) || base::is.data.frame(value)
            },
            FUN.VALUE = base::logical(1L)
        ))
    if (sumstat_is_list) {
        sumstat_value <- base::lapply(sumstat, base::as.matrix)
    } else {
        sumstat_value <- base::as.matrix(sumstat)
    }
    target_matrix <- base::as.matrix(target)

    if (!sumstat_is_list &&
        base::nrow(param_matrix) == 1L &&
        base::ncol(param_matrix) == base::nrow(sumstat_value) &&
        base::nrow(sumstat_value) != 1L) {
        param_matrix <- base::t(param_matrix)
    }

    logit_bounds_matrix <- if (base::is.null(logit.bounds)) {
        base::matrix(data = base::c(0, 0), nrow = 1L)
    } else {
        base::as.matrix(logit.bounds)
    }

    subset_vector <- if (base::is.null(subset)) {
        base::logical(0L)
    } else {
        base::as.logical(subset)
    }

    reduction_value <- if (base::is.null(reduction)) {
        "none"
    } else {
        base::as.character(reduction)[1L]
    }
    n_comp_value <- if (base::is.null(n_comp)) {
        0L
    } else {
        base::as.integer(n_comp)[1L]
    }

    call_name <- if (sumstat_is_list) {
        "_abcpp_abc_matrix_list"
    } else {
        "_abcpp_abc"
    }

    result <- base::.Call(
        call_name,
        target_matrix,
        param_matrix,
        sumstat_value,
        base::as.numeric(tol),
        base::as.character(method)[1L],
        base::as.logical(hcorr)[1L],
        base::as.character(transf),
        logit_bounds_matrix,
        subset_vector,
        base::as.character(kernel)[1L],
        base::as.integer(numnet)[1L],
        base::as.integer(sizenet)[1L],
        base::as.numeric(lambda),
        base::as.integer(maxit)[1L],
        base::as.integer(seed)[1L],
        reduction_value,
        n_comp_value
    )

    param_names <- base::colnames(param_matrix)
    if (base::is.null(param_names)) {
        param_names <- base::paste0("P", base::seq_len(base::ncol(param_matrix)))
    }

    stat_names <- if (sumstat_is_list) {
        NULL
    } else {
        base::colnames(sumstat_value)
    }
    if (base::is.null(stat_names)) {
        stat_names <- base::paste0(
            "S",
            base::seq_len(result$numstat)
        )
    }

    if (!base::is.null(result$unadj.values) &&
        base::ncol(result$unadj.values) == base::length(param_names)) {
        base::colnames(result$unadj.values) <- param_names
    }
    if (!base::is.null(result$adj.values) &&
        base::ncol(result$adj.values) == base::length(param_names)) {
        base::colnames(result$adj.values) <- param_names
    }
    if (!base::is.null(result$ss) &&
        base::ncol(result$ss) <= base::length(stat_names)) {
        base::colnames(result$ss) <- stat_names[base::seq_len(
            base::ncol(result$ss)
        )]
    }

    result$names <- base::list(
        parameter.names = param_names,
        statistics.names = stat_names
    )
    result$call <- base::match.call()
    base::class(result) <- "abcpp"
    result
}
