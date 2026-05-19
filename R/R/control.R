#' ABC control options
#'
#' Documents the nested `control` list accepted by [abc()]. The control
#' list is merged with defaults, so users may provide only the fields they
#' want to override.
#'
#' The default control is:
#'
#' ```r
#' list(
#'   method = "rejection",
#'   tol = 0.01,
#'   kernel = "epanechnikov",
#'   hcorr = TRUE,
#'   transf = "none",
#'   logit.bounds = NULL,
#'   subset = NULL,
#'   prior.weights = NULL,
#'   seed = 1004,
#'   reduction = "none",
#'   n_comp = 0L,
#'   nnet = list(
#'     numnet = 10L,
#'     sizenet = 5L,
#'     lambda = c(0.0001, 0.001, 0.01),
#'     maxit = 500L,
#'     rang = 0.7,
#'     abstol = 1e-4,
#'     reltol = 1e-8,
#'     verbose = FALSE,
#'     skip = FALSE
#'   )
#' )
#' ```
#'
#' @section Control List Fields:
#' \describe{
#'   \item{\code{method}}{Character. Selects the ABC method. Supported
#'     values are \code{"rejection"}, \code{"loclinear"}, \code{"ridge"},
#'     and \code{"neuralnet"}.}
#'   \item{\code{tol}}{Numeric. The tolerance proportion in \code{(0, 1]}.
#'     It determines the proportion of simulations accepted based on
#'     distance to the target summary statistics.}
#'   \item{\code{kernel}}{Character. Selects the regression weight kernel.
#'     Supported values are \code{"epanechnikov"} (default),
#'     \code{"rectangular"}, \code{"gaussian"}, \code{"triangular"},
#'     \code{"biweight"}, and \code{"cosine"}.}
#'   \item{\code{hcorr}}{Logical. Enables conditional heteroscedastic
#'     correction in regression adjustment methods (default is \code{TRUE}).}
#'   \item{\code{transf}}{Character vector. Controls parameter transformation
#'     before adjustment. Use \code{"none"}, \code{"log"}, or \code{"logit"}.
#'     A single value is recycled across all parameters.}
#'   \item{\code{logit.bounds}}{Matrix. Used when \code{transf = "logit"} to
#'     specify the bounds for each parameter. Each row corresponds to a
#'     parameter, with the first column being the lower bound and the second
#'     being the upper bound.}
#'   \item{\code{subset}}{Logical vector. An optional mask to apply to
#'     simulations, selecting a subset to be considered.}
#'   \item{\code{prior.weights}}{Numeric vector. Optional prior weights for
#'     simulated samples. When supplied, its length must match the number of
#'     rows in \code{params}. For regression adjustment methods, final
#'     regression weights are the distance-kernel weights multiplied by these
#'     prior weights.}
#'   \item{\code{seed}}{Integer. The seed used by stochastic C++ components
#'     (default is \code{1004L}).}
#'   \item{\code{reduction}}{Character. Optionally reduces summary statistics
#'     prior to ABC. Supported values are \code{"none"}, \code{"pca"}
#'     (Principal Component Analysis), and \code{"pls"} (Partial Least
#'     Squares).}
#'   \item{\code{n_comp}}{Integer. The number of PCA or PLS components to
#'     retain when \code{reduction} is active. Use \code{0L} to let the
#'     backend decide the default.}
#'   \item{\code{nnet}}{A nested list of settings for the neural network
#'     method (\code{method = "neuralnet"}):
#'     \itemize{
#'       \item \code{numnet}: Integer. The number of neural networks to
#'         train (default \code{10L}).
#'       \item \code{sizenet}: Integer. The number of units in the hidden
#'         layer (default \code{5L}).
#'       \item \code{lambda}: Numeric vector. Weight decay parameters sampled
#'         uniformly across neural network fits.
#'       \item \code{maxit}: Integer. The maximum number of BFGS iterations
#'         per fit (default \code{500L}).
#'       \item \code{rang}: Numeric. Initial weights are randomized in
#'         \code{[-rang, rang]} (default \code{0.7}).
#'       \item \code{abstol}: Numeric. Absolute convergence tolerance
#'         (default \code{1e-4}).
#'       \item \code{reltol}: Numeric. Relative convergence tolerance
#'         (default \code{1e-8}).
#'       \item \code{verbose}: Logical. If \code{TRUE}, requests training
#'         progress from the backend.
#'       \item \code{skip}: Logical. If \code{TRUE}, adds direct
#'         input-to-output skip-layer connections.
#'     }
#'   }
#' }
#'
#' @examples
#' fit <- abc(
#'   target = c(0.5),
#'   params = matrix(runif(100), ncol = 1),
#'   sumstats = matrix(runif(100), ncol = 1),
#'   control = list(tol = 0.1)
#' )
#'
#' \dontrun{
#' fit <- abc(
#'   target = target,
#'   params = params,
#'   sumstats = sumstats,
#'   control = list(
#'     method = "neuralnet",
#'     tol = 0.1,
#'     nnet = list(sizenet = 8, maxit = 1000)
#'   )
#' )
#' }
#'
#' @seealso [abc()]
#' @name control
NULL
