\name{summary.abcpp}
\alias{summary.abcpp}
\title{Summarize an abcpp Posterior}
\description{
Summarizes posterior samples returned by \code{\link{abc}}.
}
\usage{
\method{summary}{abcpp}(object, unadj = FALSE, intvl = 0.95, ...)
}
\arguments{
\item{object}{
An object of class \code{"abcpp"} returned by \code{\link{abc}}.
}
\item{unadj}{
Logical. If \code{TRUE}, summarize unadjusted rejection samples even when
regression-adjusted values are available.
}
\item{intvl}{
Credible interval width used for lower and upper posterior summaries.
}
\item{...}{
Additional arguments for S3 compatibility.
}
}
\value{
A list of class \code{"summary.abcpp"} with posterior summary statistics,
the interval width, the selected method, and whether unadjusted samples were
used.
}
\details{
The summary contains minimum, lower interval endpoint, median, mean, upper
interval endpoint, maximum, and standard deviation for each parameter. For
\code{method = "rejection"}, unadjusted samples are always summarized.
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
