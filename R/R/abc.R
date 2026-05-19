default_control <- list(
    method = "rejection",
    tol = 0.01,
    kernel = "epanechnikov",
    hcorr = TRUE,
    transf = "none",
    logit.bounds = NULL,
    subset = NULL,
    prior.weights = NULL,
    seed = 1004L,
    reduction = "none",
    n_comp = 0L,
    nnet = list(
        numnet = 10L,
        sizenet = 5L,
        lambda = c(0.0001, 0.001, 0.01),
        maxit = 500L,
        rang = 0.7,
        abstol = 1e-4,
        reltol = 1e-8,
        verbose = FALSE,
        skip = FALSE
    )
)

merge_control <- function(control) {
    if (base::is.null(control)) {
        control <- list()
    }
    if (!base::is.list(control)) {
        base::stop("control must be a list.", call. = FALSE)
    }
    utils::modifyList(default_control, control, keep.null = TRUE)
}

#' Parameter Estimation With Approximate Bayesian Computation
#'
#' Runs Approximate Bayesian Computation through the shared C++ backend. The R
#' interface is intentionally small: users provide `target`, `params`,
#' `sumstats`, and an optional nested `control` list.
#'
#' @param target A vector, one-row matrix, or two-dimensional matrix of
#'   observed summary statistics.
#' @param params A vector, one-row matrix, matrix, or data frame of simulated
#'   parameter values. Each row corresponds to one simulation.
#' @param sumstats A vector, matrix, data frame, or list of matrices of
#'   simulated summary statistics. Rows, or list elements for matrix-valued
#'   summaries, correspond to rows of `params`.
#' @param control Nested list of algorithm controls. See [control] for the
#'   full schema. Common fields include `method`, `tol`, `kernel`, `hcorr`,
#'   `transf`, `prior.weights`, `seed`, `reduction`, `n_comp`, and `nnet`.
#'
#' @return An object of class \code{"abcpp"} containing complete algorithm
#'   output. This object is a list containing the following components:
#'   \itemize{
#'     \item \code{unadj.values}: A matrix of unadjusted accepted posterior
#'       samples.
#'     \item \code{adj.values}: A matrix of adjusted posterior samples when
#'       a regression method (e.g., \code{"loclinear"}, \code{"ridge"},
#'       \code{"neuralnet"}) is used; otherwise \code{NULL}.
#'     \item \code{ss}: A matrix of accepted summary statistics.
#'     \item \code{weights}: A numeric vector of regression weights used for
#'       adjustments.
#'     \item \code{dist}: A numeric vector of Euclidean distances between
#'       accepted simulated and target summary statistics.
#'     \item \code{region}: A logical vector indicating which simulations
#'       were accepted (unadjusted).
#'     \item \code{method}: The ABC method used.
#'     \item \code{call}: The original matched function call.
#'     \item \code{names}: A list containing \code{parameter.names} and
#'       \code{statistics.names}.
#'   }
#'
#' @details
#' The algorithmic implementation lives in C++. The R layer only prepares
#' the input matrices, merges the \code{control} list with defaults, calls
#' the compiled backend, and attaches the \code{"abcpp"} class to the
#' output.
#'
#' The core ABC procedure calculates the Euclidean distance between the
#' simulated summary statistics and the target summary statistics.
#' Optionally, dimensionality reduction (PCA or PLS) can be applied to the
#' summary statistics before calculating distances. A predefined proportion
#' (\code{tol}) of the simulations closest to the target are retained. The
#' \code{method} parameter in the \code{control} list specifies whether the
#' accepted parameters are returned as-is (\code{"rejection"}) or adjusted
#' using a regression model (\code{"loclinear"}, \code{"ridge"}, or
#' \code{"neuralnet"}) to account for the discrepancy between the simulated
#' and observed summary statistics.
#'
#' \code{summary()} computes statistical summaries from the returned object.
#'
#' @examples
#' set.seed(1004)
#' n <- 200L
#' params <- cbind(theta = stats::runif(n))
#' sumstats <- cbind(s = params[, 1] + stats::rnorm(n, sd = 0.05))
#' fit <- abc(
#'   target = c(0.5),
#'   params = params,
#'   sumstats = sumstats,
#'   control = list(tol = 0.1)
#' )
#' summary(fit)
#'
#' @seealso [control], [summary.abcpp()]
#' @export
abc <- function(target, params, sumstats, control = list()) {
    control <- merge_control(control)
    param_matrix <- base::as.matrix(params)
    sumstat_is_list <- base::is.list(sumstats) &&
        !base::is.data.frame(sumstats) &&
        base::length(sumstats) > 0L &&
        base::all(base::vapply(
            X = sumstats,
            FUN = function(value) {
                base::is.matrix(value) || base::is.data.frame(value)
            },
            FUN.VALUE = base::logical(1L)
        ))
    if (sumstat_is_list) {
        sumstat_value <- base::lapply(sumstats, base::as.matrix)
    } else {
        sumstat_value <- base::as.matrix(sumstats)
    }
    target_matrix <- base::as.matrix(target)

    if (!sumstat_is_list &&
        base::nrow(param_matrix) == 1L &&
        base::ncol(param_matrix) == base::nrow(sumstat_value) &&
        base::nrow(sumstat_value) != 1L) {
        param_matrix <- base::t(param_matrix)
    }

    logit_bounds_matrix <- if (base::is.null(control$logit.bounds)) {
        base::matrix(data = base::c(0, 0), nrow = 1L)
    } else {
        base::as.matrix(control$logit.bounds)
    }

    subset_vector <- if (base::is.null(control$subset)) {
        base::logical(0L)
    } else {
        base::as.logical(control$subset)
    }
    prior_weights <- if (base::is.null(control$prior.weights)) {
        base::numeric(0L)
    } else {
        base::as.numeric(control$prior.weights)
    }

    if (sumstat_is_list) {
        result <- .Call(
            `_abcpp_abc_matrix_list`,
            target_matrix,
            param_matrix,
            sumstat_value,
            base::as.numeric(control$tol),
            base::as.character(control$method)[1L],
            base::as.logical(control$hcorr)[1L],
            base::as.character(control$transf),
            logit_bounds_matrix,
            subset_vector,
            prior_weights,
            base::as.character(control$kernel)[1L],
            base::as.integer(control$nnet$numnet)[1L],
            base::as.integer(control$nnet$sizenet)[1L],
            base::as.numeric(control$nnet$lambda),
            base::as.integer(control$nnet$maxit)[1L],
            base::as.numeric(control$nnet$rang)[1L],
            base::as.numeric(control$nnet$abstol)[1L],
            base::as.numeric(control$nnet$reltol)[1L],
            base::as.logical(control$nnet$verbose)[1L],
            base::as.logical(control$nnet$skip)[1L],
            base::as.integer(control$seed)[1L],
            base::as.character(control$reduction)[1L],
            base::as.integer(control$n_comp)[1L]
        )
    } else {
        result <- .Call(
            `_abcpp_abc`,
            target_matrix,
            param_matrix,
            sumstat_value,
            base::as.numeric(control$tol),
            base::as.character(control$method)[1L],
            base::as.logical(control$hcorr)[1L],
            base::as.character(control$transf),
            logit_bounds_matrix,
            subset_vector,
            prior_weights,
            base::as.character(control$kernel)[1L],
            base::as.integer(control$nnet$numnet)[1L],
            base::as.integer(control$nnet$sizenet)[1L],
            base::as.numeric(control$nnet$lambda),
            base::as.integer(control$nnet$maxit)[1L],
            base::as.numeric(control$nnet$rang)[1L],
            base::as.numeric(control$nnet$abstol)[1L],
            base::as.numeric(control$nnet$reltol)[1L],
            base::as.logical(control$nnet$verbose)[1L],
            base::as.logical(control$nnet$skip)[1L],
            base::as.integer(control$seed)[1L],
            base::as.character(control$reduction)[1L],
            base::as.integer(control$n_comp)[1L]
        )
    }

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
        stat_names <- base::paste0("S", base::seq_len(result$numstat))
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
