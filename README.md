# abcpp <a href="https://yuki-961004.github.io/abcpp/"><img src="./fig/logo.png" alt="LOGO" align="right" width="120"/></a>


<!-- badges: start -->
[![CI](https://github.com/yuki-961004/abcpp/actions/workflows/ci.yaml/badge.svg)](https://github.com/yuki-961004/abcpp/actions/workflows/ci.yaml)
[![Code Coverage](https://codecov.io/gh/yuki-961004/abcpp/graph/badge.svg?component=interfaces)](https://app.codecov.io/gh/yuki-961004/abcpp/components)
[![License: GPL-3](https://img.shields.io/badge/license-GPL--3-blue.svg)](LICENSE)
[![R](https://img.shields.io/badge/R-%3E%3D4.1.0-276DC3.svg)](R/DESCRIPTION)
[![Python](https://img.shields.io/badge/python-%3E%3D3.10-3776AB.svg)](Python/pyproject.toml)
<!-- badges: end -->

`abcpp` is a lightweight embeddable C++ library for Approximate Bayesian
Computation, with R and Python wrappers. The C++ library is the only algorithm
implementation; R and Python are thin frontends.

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

target_link_libraries(my_target PRIVATE abcpp::abcpp)
```

The primary C++ API is NLopt-like:

```cpp
#include <abcpp/abcpp.hpp>

abcpp::opt opt;
abcpp::result fit = opt
    .set_target(target)
    .set_params(params)
    .set_sumstats(sumstats)
    .set_method(abcpp::method::neuralnet)
    .set_tol(0.01)
    .set_nnet_sizenet(8)
    .run();
```

## R Usage

Install from CRAN:

```r
install.packages("abcpp")
```

The R interface uses four inputs: `target`, `params`, `sumstats`, and
`control`.

```r
library(abcpp)

result <- abcpp::abc(
  target = <target_summary_vector_or_matrix>,
  params = <parameter_vector_or_matrix>,
  sumstats = <simulated_summary_vector_or_matrix>,
  control = list(
    method = "rejection",
    tol = <tolerance_between_0_and_1>
  )
)

summary(result)
```

## Python Usage

Install from PyPI:

```bash
pip install abcpp
```

The Python interface mirrors the R interface:

```python
import abcpp

result = abcpp.abc(
    target=<target_summary_vector_or_matrix>,
    params=<parameter_vector_or_matrix>,
    sumstats=<simulated_summary_vector_or_matrix>,
    control={
        "method": "rejection",
        "tol": <tolerance_between_0_and_1>,
    },
)

abcpp.summary(result)
```
