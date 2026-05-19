#pragma once

#include "abcpp/matrix.hpp"
#include "abcpp/options.hpp"
#include "abcpp/result.hpp"

#include <string>
#include <vector>

namespace abcpp {

class opt {
public:
    opt() = default;

    opt& set_target(const Matrix& target);
    opt& set_params(const Matrix& params);
    opt& set_sumstats(const Matrix& sumstats);

    opt& set_method(method value);
    opt& set_tol(double value);
    opt& set_kernel(kernel value);
    opt& set_hcorr(bool value);
    opt& set_transform(transform value);
    opt& set_prior_weights(const std::vector<double>& value);
    opt& set_seed(unsigned int value);

    opt& set_nnet_numnet(int value);
    opt& set_nnet_sizenet(int value);
    opt& set_nnet_lambda(const std::vector<double>& value);
    opt& set_nnet_maxit(int value);
    opt& set_nnet_rang(double value);
    opt& set_nnet_abstol(double value);
    opt& set_nnet_reltol(double value);
    opt& set_nnet_verbose(bool value);
    opt& set_nnet_skip(bool value);

    result run() const;

private:
    Matrix target_;
    Matrix params_;
    Matrix sumstats_;
    bool has_target_ = false;
    bool has_params_ = false;
    bool has_sumstats_ = false;
    options options_;
};

result fit(
    const std::vector<double>& target,
    const Matrix& param,
    const Matrix& sumstat,
    const options& options
);

result fit(
    const Matrix& target,
    const Matrix& param,
    const Matrix& sumstat,
    const options& options
);

result fit(
    const Matrix& target,
    const Matrix& param,
    const std::vector<Matrix>& sumstats,
    const options& options
);

}  // namespace abcpp
