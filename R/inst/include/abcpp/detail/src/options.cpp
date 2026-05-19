#include "abcpp/options.hpp"

#include <algorithm>
#include <cctype>
#include <stdexcept>

namespace abcpp {

namespace {

std::string lower(std::string value) {
    std::transform(
        value.begin(),
        value.end(),
        value.begin(),
        [](unsigned char ch) {
            return static_cast<char>(std::tolower(ch));
        }
    );
    return value;
}

}  // namespace

method parse_method(const std::string& value) {
    const std::string key = lower(value);
    if (key == "rejection") {
        return method::rejection;
    }
    if (key == "loclinear") {
        return method::loclinear;
    }
    if (key == "ridge") {
        return method::ridge;
    }
    if (key == "neuralnet") {
        return method::neuralnet;
    }
    throw std::invalid_argument("Unknown ABC method.");
}

kernel parse_kernel(const std::string& value) {
    const std::string key = lower(value);
    if (key == "gaussian") {
        return kernel::gaussian;
    }
    if (key == "epanechnikov") {
        return kernel::epanechnikov;
    }
    if (key == "rectangular") {
        return kernel::rectangular;
    }
    if (key == "triangular") {
        return kernel::triangular;
    }
    if (key == "biweight") {
        return kernel::biweight;
    }
    if (key == "cosine") {
        return kernel::cosine;
    }
    throw std::invalid_argument("Unknown ABC kernel.");
}

transform parse_transform(const std::string& value) {
    const std::string key = lower(value);
    if (key == "none") {
        return transform::none;
    }
    if (key == "log") {
        return transform::log;
    }
    if (key == "logit") {
        return transform::logit;
    }
    throw std::invalid_argument("Unknown parameter transformation.");
}

reduction_method parse_reduction(const std::string& value) {
    const std::string key = lower(value);
    if (key.empty() || key == "none" || key == "null") {
        return reduction_method::none;
    }
    if (key == "pca") {
        return reduction_method::pca;
    }
    if (key == "pls") {
        return reduction_method::pls;
    }
    throw std::invalid_argument("Unknown summary reduction method.");
}

std::string method_name(abcpp::method value) {
    switch (value) {
    case method::rejection:
        return "rejection";
    case method::loclinear:
        return "loclinear";
    case method::ridge:
        return "ridge";
    case method::neuralnet:
        return "neuralnet";
    }
    return "unknown";
}

std::string kernel_name(abcpp::kernel value) {
    switch (value) {
    case kernel::gaussian:
        return "gaussian";
    case kernel::epanechnikov:
        return "epanechnikov";
    case kernel::rectangular:
        return "rectangular";
    case kernel::triangular:
        return "triangular";
    case kernel::biweight:
        return "biweight";
    case kernel::cosine:
        return "cosine";
    }
    return "unknown";
}

std::string transform_name(abcpp::transform value) {
    switch (value) {
    case transform::none:
        return "none";
    case transform::log:
        return "log";
    case transform::logit:
        return "logit";
    }
    return "unknown";
}

std::string reduction_name(reduction_method reduction) {
    switch (reduction) {
    case reduction_method::none:
        return "none";
    case reduction_method::pca:
        return "PCA";
    case reduction_method::pls:
        return "PLS";
    }
    return "unknown";
}

}  // namespace abcpp
