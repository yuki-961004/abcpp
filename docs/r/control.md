# R control

`abcpp::abc()` has four user-facing inputs:

```r
fit <- abcpp::abc(target, params, sumstats, control = list())
```

`control` is a nested list. Missing fields are filled from defaults with
`utils::modifyList()`.

```r
list(
  method = "rejection",
  tol = 0.01,
  kernel = "epanechnikov",
  hcorr = TRUE,
  transf = "none",
  logit.bounds = NULL,
  subset = NULL,
  prior.weights = NULL,
  seed = 1004,
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
```

`prior.weights` is an optional numeric vector with one value per row of
`params`. For `loclinear`, `ridge`, and `neuralnet`, the backend multiplies
the distance-kernel regression weight by the corresponding prior weight.

Partial overrides preserve the rest of the defaults:

```r
fit <- abcpp::abc(
  target = target,
  params = params,
  sumstats = sumstats,
  control = list(
    method = "neuralnet",
    nnet = list(sizenet = 8, maxit = 1000)
  )
)
```

The R layer does not implement ABC. It converts inputs, merges control, calls
the C++ backend, and returns the complete result object.
