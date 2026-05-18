# abcpp <a href="https://yuki-961004.github.io/abcpp/"><img src="./fig/logo.png" alt="LOGO" align="right" width="120"/></a>


<!-- badges: start -->
[![CI](https://github.com/yuki-961004/abcpp/actions/workflows/ci.yaml/badge.svg)](https://github.com/yuki-961004/abcpp/actions/workflows/ci.yaml)
[![Code Coverage](https://codecov.io/gh/yuki-961004/abcpp/graph/badge.svg?component=interfaces)](https://app.codecov.io/gh/yuki-961004/abcpp/components)
[![License: GPL-3](https://img.shields.io/badge/license-GPL--3-blue.svg)](LICENSE)
[![R](https://img.shields.io/badge/R-%3E%3D4.1.0-276DC3.svg)](R/DESCRIPTION)
[![Python](https://img.shields.io/badge/python-%3E%3D3.10-3776AB.svg)](Python/pyproject.toml)
<!-- badges: end -->

`abcpp` is a C++ implementation based on the `cran/abc` package. It builds upon the original version with two major improvements:

1. `target` and `sumstat` can accept matrix inputs (`sumstat` can also accept a `list` or `dict` where each element is a matrix).
2. Dimensionality reduction can be applied to the input matrices by setting the `reduction` parameter (defaults to `"none"`). Available reduction methods are `"pca"` and `"pls"`.

## C++ Usage

`abcpp` can be embedded in another CMake project in the same style as small algorithm libraries such as NLopt, using `FetchContent_Declare` to call `abcpp` as the algorithm backend:

```cmake
include(FetchContent)

FetchContent_Declare(
  abcpp
  GIT_REPOSITORY https://github.com/yuki-961004/abcpp.git
  GIT_TAG main
  GIT_SHALLOW TRUE
)

FetchContent_MakeAvailable(abcpp)

target_link_libraries(my_target PRIVATE abcpp::abc)
```

## R Usage

Install from CRAN:

```r
install.packages("abcpp")
```

Usage is the same as the standard `abc` package, with the addition of the `reduction` and `n_comp` arguments:

```r
library(abcpp)

result <- abcpp::abc(
  target = <target_summary_vector_or_matrix>,
  param = <parameter_vector_or_matrix>,
  sumstat = <simulated_summary_vector_or_matrix>,
  tol = <tolerance_between_0_and_1>,
  method = "rejection",
  reduction = "none",
  n_comp = <number_of_components_if_needed>
)

summary(result)
```

## Python Usage

Install from PyPI:

```bash
pip install abcpp
```

Usage is similar to the R interface:

```python
import abcpp

result = abcpp.abc(
    target=<target_summary_vector_or_matrix>,
    param=<parameter_vector_or_matrix>,
    sumstat=<simulated_summary_vector_or_matrix>,
    tol=<tolerance_between_0_and_1>,
    method="rejection",
    reduction="none",
    n_comp=<number_of_components_if_needed>,
)

abcpp.summary(result)
```
