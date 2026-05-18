\name{abc}
\alias{abc}
\title{Parameter Estimation With Approximate Bayesian Computation}
\description{
Performs multivariate parameter estimation based on summary statistics
using Approximate Bayesian Computation. The implemented algorithms are
rejection sampling, local linear regression adjustment, ridge regression
adjustment, and a lightweight neural-network-style regression adjustment.
}
\usage{
abc(target, param, sumstat, tol, method, hcorr = TRUE,
    transf = "none", logit.bounds = NULL, subset = NULL,
    kernel = "epanechnikov", numnet = 10L, sizenet = 5L,
    lambda = base::c(0.0001, 0.001, 0.01), trace = FALSE,
    maxit = 500L, reduction = NULL, n_comp = NULL, seed = 1004L, ...)
}
\arguments{
\item{target}{
A vector, one-row matrix, or two-dimensional matrix of observed summary
statistics. Matrix inputs are flattened when no reduction is requested, or
projected when PCA or PLS reduction is requested.
}
\item{param}{
A vector, one-row matrix, matrix, or data frame of simulated parameter values.
Vectors and one-row matrices are treated as one-parameter simulations. These
are the dependent variables for \code{"loclinear"}, \code{"ridge"}, and
\code{"neuralnet"}.
}
\item{sumstat}{
A vector, matrix, data frame, or list of matrices of simulated summary
statistics. These are the independent variables for regression adjustment. If
\code{sumstat} is a list, each element is one simulation's matrix-valued
summary statistic and must correspond to one row of \code{param}. Matrix
targets and matrix-valued simulated summaries are flattened in the C++ backend
before optional PCA or PLS reduction. If a non-list \code{sumstat} row count
does not match \code{param}, the C++ core reshapes the values by simulation
when the total number of values is compatible with the number of parameter
rows.
}
\item{tol}{
Tolerance rate. This is the required proportion of simulations accepted nearest
the target summary statistics.
}
\item{method}{
Character string indicating the ABC algorithm. Possible values are
\code{"rejection"}, \code{"loclinear"}, \code{"ridge"}, and
\code{"neuralnet"}.
}
\item{hcorr}{
Logical. If \code{TRUE}, conditional heteroscedastic correction is applied for
regression adjustment methods.
}
\item{transf}{
Character vector indicating parameter transformations. Possible values are
\code{"none"}, \code{"log"}, and \code{"logit"}.
}
\item{logit.bounds}{
Matrix with one row per parameter and two columns when \code{transf} contains
\code{"logit"}. The first column is the lower bound and the second column is
the upper bound.
}
\item{subset}{
Logical vector indicating simulation rows to keep. Missing values in
\code{param} or \code{sumstat} are excluded.
}
\item{kernel}{
Kernel used for regression weights. Possible values are \code{"gaussian"},
\code{"epanechnikov"}, \code{"rectangular"}, \code{"triangular"},
\code{"biweight"}, and \code{"cosine"}.
}
\item{numnet}{
Number of neural adjustment fits when \code{method = "neuralnet"}.
}
\item{sizenet}{
Number of hidden units for the lightweight neural adjustment.
}
\item{lambda}{
Numeric vector of ridge penalties or neural weight decay values.
}
\item{trace}{
Accepted for API compatibility with \pkg{abc}. The C++ backend currently does
not print neural optimizer traces.
}
\item{maxit}{
Maximum number of iterations for neural adjustment controls. This argument is
kept for API compatibility.
}
\item{reduction}{
Optional summary statistic reduction method. Possible values are
\code{NULL}, \code{"none"}, \code{"pca"}, and \code{"pls"}.
}
\item{n_comp}{
Number of PCA or PLS components. If omitted, a conservative default is used.
}
\item{seed}{
Integer seed used by stochastic C++ components.
}
\item{...}{
Additional arguments accepted for API compatibility.
}
}
\value{
An object of class \code{"abcpp"} containing:
\item{adj.values}{Regression-adjusted posterior samples for non-rejection
methods.}
\item{unadj.values}{Unadjusted posterior samples from the rejection step.}
\item{ss}{Accepted summary statistics.}
\item{weights}{Regression weights.}
\item{residuals}{Regression residuals.}
\item{dist}{Distances between simulated and target summary statistics.}
\item{region}{Logical vector indicating accepted simulations.}
\item{na.action}{Logical vector indicating rows kept after missing-value and
subset filtering.}
\item{transf}{Parameter transformations used.}
\item{logit.bounds}{Logit transformation bounds.}
\item{method}{ABC method.}
\item{kernel}{Regression kernel.}
\item{numparam}{Number of parameters.}
\item{numstat}{Number of summary statistics after optional reduction.}
\item{reduction}{Summary reduction metadata.}
\item{names}{Parameter and statistic names.}
}
\details{
The interface is inspired by common ABC workflows and the main
parameter-estimation interface in the R package \pkg{abc}. When
\code{method = "rejection"}, simulations are accepted according to Euclidean
distance between simulated and observed summary statistics. For regression
adjustment methods, accepted parameter values are corrected using a weighted
local regression around the target summary statistics.

Unlike \pkg{abc}, the algorithmic implementation lives in C++ and does not
call \code{abc::abc()}, \code{nnet::nnet()}, sklearn, PyTorch, or other
high-level ABC or machine-learning packages. PCA, PLS, linear regression,
ridge regression, and the neural adjustment are implemented in the C++
backend. Internal C++ helpers are not exported as R user functions.
}
\seealso{
\code{\link{summary.abcpp}}
}
\examples{
set.seed(1004)
n <- 200L
param <- cbind(theta = stats::runif(n))
sumstat <- cbind(s = param[, 1] + stats::rnorm(n, sd = 0.05))
fit <- abc(
  target = c(0.5),
  param = param,
  sumstat = sumstat,
  tol = 0.1,
  method = "rejection"
)
summary(fit)
}
