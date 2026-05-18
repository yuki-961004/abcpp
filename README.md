# abcpp

<!-- badges: start -->
[![CI](https://github.com/yuki-961004/abcpp/actions/workflows/ci.yaml/badge.svg)](https://github.com/yuki-961004/abcpp/actions/workflows/ci.yaml)
[![Code Coverage](https://codecov.io/gh/yuki-961004/abcpp/graph/badge.svg?component=interfaces)](https://app.codecov.io/gh/yuki-961004/abcpp/components)
[![License: GPL-3](https://img.shields.io/badge/license-GPL--3-blue.svg)](LICENSE)
[![R](https://img.shields.io/badge/R-%3E%3D4.1.0-276DC3.svg)](R/DESCRIPTION)
[![Python](https://img.shields.io/badge/python-%3E%3D3.10-3776AB.svg)](Python/pyproject.toml)
<!-- badges: end -->

`abcpp` is a lightweight embeddable C++ library for Approximate Bayesian
Computation, with R and Python wrappers.

The public user interface is intentionally small:

- C++: `abcpp::abc()` and `abcpp::summary()`
- R: `abcpp::abc()` and `summary(fit)`
- Python: `abcpp.abc()` and `abcpp.summary()`

The C++ code is the only algorithm implementation. R and Python only normalize
inputs and call the C++ backend; they do not reimplement ABC algorithms.

## Features

Supported ABC methods:

- `rejection`
- `loclinear`
- `ridge`
- `neuralnet`

Supported summary-statistic reductions:

- `none`
- `pca`
- `pls`

Accepted core inputs:

- `param`: parameter vector or matrix
- `sumstat`: simulated summary-statistic vector, matrix, or list of matrices
- `target`: observed summary-statistic vector or matrix
- `tol`: accepted simulation proportion
- `method`: ABC algorithm
- `reduction`: optional summary-statistic reduction

The C++ backend does not call R `abc`, R `nnet`, Python sklearn, PyTorch, or
other high-level ABC or machine-learning libraries.

## Using abcpp as a C++ dependency

`abcpp` can be embedded in another CMake project in the same style as small
algorithm libraries such as NLopt:

```cmake
include(FetchContent)

FetchContent_Declare(
  abcpp
  GIT_REPOSITORY https://github.com/yuki-961004/abcpp.git
  GIT_TAG master
  GIT_SHALLOW TRUE
)

FetchContent_MakeAvailable(abcpp)

target_link_libraries(my_target PRIVATE abcpp::abc)
```

`abcpp::abc` is the lightweight C++ backend target. It builds only the C++
algorithm library and does not require R, Python, NumPy, pybind11, or other
heavy runtime dependencies.

When `abcpp` is used through `FetchContent` or `add_subdirectory`, tests and
the Python frontend are OFF by default. A parent project can be explicit:

```cmake
set(ABCPP_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(ABCPP_BUILD_PYTHON OFF CACHE BOOL "" FORCE)

FetchContent_MakeAvailable(abcpp)
```

If you configure `abcpp` as the top-level project, `ABCPP_BUILD_TESTS` and
`ABCPP_BUILD_PYTHON` default to ON. For a C++ backend-only local build, use:

```powershell
cmake -S . -B build -DABCPP_BUILD_PYTHON=OFF
```

Installed packages are available with:

```cmake
find_package(abcpp CONFIG REQUIRED)
target_link_libraries(my_target PRIVATE abcpp::abc)
```

The installed library name is `abcpp`. The `_core` name is used only for the
private Python extension module `abcpp._core`.

```cpp
#include <abcpp/abcpp.hpp>

abcpp::AbcOptions options;
options.method = abcpp::Method::Rejection;
options.tol = 0.01;

auto fit = abcpp::abc(target, param, sumstat, options);
auto s = abcpp::summary(fit);
```

`abc()` returns the full algorithm result, including unadjusted posterior
samples, adjusted posterior samples when available, weights, distances,
accepted indices, accepted summary statistics, method/options, status/message,
and diagnostics. `summary()` computes summaries from that result object.

Reduction component naming follows the host language. C++ uses
`options.reduction.ncomp`, while R and Python accept both `ncomp` and `n_comp`
as aliases for the requested number of summary-statistic components.

Matrix-valued summary statistics are supported by passing a matrix `target`
and a list of per-simulation summary matrices. Python also accepts a `dict`
whose values are per-simulation matrices; values are consumed in insertion
order, so they should be ordered to match the rows of `param`. With
`reduction = "none"`, `target` is flattened losslessly and each simulated
summary matrix is flattened into one row, so the canonical backend input is
still `n_sim x n_stat`. PCA and PLS reductions operate on the same flattened
feature matrix.

## R And Python Usage

R example:

```r
result <- abcpp::abc(
  target = <target_summary_vector_or_matrix>,
  param = <parameter_vector_or_matrix>,
  sumstat = <simulated_summary_vector_or_matrix>,
  tol = <tolerance_between_0_and_1>,
  method = "rejection",
  reduction = "none",
  n_comp = <number_of_components_if_needed>
)

summary_result <- base::summary(result)
```

Python example:

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

summary_result = abcpp.summary(result)
```

## Using abcpp from another R package

An installed `abcpp` R package exposes the C++ backend headers under
`inst/include`, so another R package can use:

```text
Imports: abcpp
LinkingTo: abcpp, Rcpp
```

Then include the public API from C++:

```cpp
#include <abcpp/abc.hpp>
#include <abcpp/options.hpp>
#include <abcpp/summary.hpp>
```

R `LinkingTo` only adds the installed include directory to the downstream
package's compiler flags. It does not link downstream packages against the
compiled `abcpp` R shared library. To provide the C++ symbols for
`abcpp::abc()` and `abcpp::summary()` without vendoring the source tree, include
the implementation bundle in exactly one downstream `.cpp` file:

```cpp
#include <abcpp/abc.hpp>
#include <abcpp/options.hpp>
#include <abcpp/summary.hpp>
#include <abcpp/abcpp_impl.hpp>
```

Alternatively, use the umbrella header form in one translation unit:

```cpp
#define ABCPP_IMPLEMENTATION
#include <abcpp/abcpp.hpp>
```

Other downstream `.cpp` files should include only the normal headers, not
`abcpp_impl.hpp`, to avoid duplicate definitions. After installing `abcpp`, the
headers are visible from R with:

```r
system.file("include", package = "abcpp")
list.files(system.file("include", "abcpp", package = "abcpp"))
```

## Install

R users can install the latest GitHub release tag with:

```r
remotes::install_github(
  "yuki-961004/abcpp@*release",
  subdir = "R"
)
```

R users can also install a downloaded release source package:

```r
install.packages(
  "abcpp_<version>.tar.gz",
  repos = NULL,
  type = "source"
)
```

Python users can install from a downloaded release source package:

```powershell
python -m pip install py_abcpp_<version>.tar.gz
```

Direct release-asset URL installs are also supported:

```powershell
python -m pip install "https://github.com/yuki-961004/abcpp/releases/download/<tag>/py_abcpp_<version>.tar.gz"
```

Windows users with Python 3.13 can install the prebuilt wheel:

```powershell
python -m pip install abcpp-<version>-cp313-cp313-win_amd64.whl
```

Users on other platforms should install from the Python source package so the
C++ extension can be compiled locally.

## Source Layout

`Cpp/` is the authoritative shared backend source tree.

The binding files are language-specific wrappers around the C++ API:

- `R/src/wrapper.cpp`
- `Python/src/py_abcpp.cpp`

Python exposes `abc()` from `Python/abcpp/abc.py` and `summary()` from
`Python/abcpp/summary.py`; `Python/abcpp/__init__.py` only re-exports those two
functions.

## Local Development

Build and test the C++ backend:

```powershell
cmake -S . -B build -DABCPP_BUILD_TESTS=ON -DABCPP_BUILD_PYTHON=OFF
cmake --build build --config Release
ctest --test-dir build -C Release --output-on-failure
```

Install and check the R package:

```powershell
R CMD INSTALL R
R CMD check R
Rscript -e "testthat::test_dir('R/tests/testthat')"
```

Install and test the Python package:

```powershell
python -m pip install -e Python --no-build-isolation
python -m pytest
python -m pytest --cov=abcpp --cov-report=term-missing
```

On Windows, `R CMD INSTALL R` may need a writable user library or an elevated
shell if the default R library is installed under `Program Files`.

## Documentation

End-user documentation lives in:

- `R/man/`
- Python docstrings in `Python/abcpp/__init__.py`

C++ maintainer documentation lives in:

- `docs/cpp/`

The C++ documentation describes backend modules, numerical assumptions,
mutation behavior, randomness, error handling, and how the R/Python bindings
call into the backend.

## Coverage

Codecov receives separate flags for C++, R, and Python. The README badge uses
the R/Python interface component because Python line coverage does not include
compiled C++ extension lines, and C++ branch coverage often reports partial
coverage for defensive or compiler-expanded branches.
