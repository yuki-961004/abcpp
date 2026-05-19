#pragma once

#include "abcpp/matrix.hpp"

#include <cstddef>
#include <string>
#include <vector>

namespace abcpp {

enum class method {
    rejection,
    loclinear,
    ridge,
    neuralnet
};

using Method = method;
using AbcMethod = method;

enum class kernel {
    gaussian,
    epanechnikov,
    rectangular,
    triangular,
    biweight,
    cosine
};

using Kernel = kernel;

enum class transform {
    none,
    log,
    logit
};

using Transform = transform;

enum class reduction_method {
    none,
    pca,
    pls
};

using ReductionMethod = reduction_method;

struct ReductionOptions {
    reduction_method method = reduction_method::none;
    std::size_t n_comp = 0;
};

struct nnet_options {
    int numnet = 10;
    int sizenet = 5;
    std::vector<double> lambda = {0.0001, 0.001, 0.01};
    int maxit = 500;
    double rang = 0.7;
    double abstol = 1e-4;
    double reltol = 1e-8;
    bool verbose = false;
    bool skip = false;
};

struct options {
    abcpp::method method = abcpp::method::rejection;
    double tol = 0.01;
    abcpp::kernel kernel = abcpp::kernel::epanechnikov;
    bool hcorr = true;
    abcpp::transform transf = abcpp::transform::none;
    std::vector<abcpp::transform> transformations;
    Matrix logit_bounds;
    std::vector<bool> subset;
    std::vector<double> prior_weights;
    unsigned int seed = 1004;
    nnet_options nnet;
    ReductionOptions reduction;
};

using AbcOptions = options;

method parse_method(const std::string& value);

kernel parse_kernel(const std::string& value);

transform parse_transform(const std::string& value);

reduction_method parse_reduction(const std::string& value);

std::string method_name(abcpp::method method);

std::string kernel_name(abcpp::kernel kernel);

std::string transform_name(abcpp::transform transform);

std::string reduction_name(reduction_method reduction);

}  // namespace abcpp
