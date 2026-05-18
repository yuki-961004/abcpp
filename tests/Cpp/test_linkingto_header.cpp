#define ABCPP_IMPLEMENTATION
#include "abcpp/abcpp.hpp"

#include <exception>
#include <iostream>
#include <vector>

int main() {
    try {
        abcpp::Matrix param(4, 1, 0.0);
        abcpp::Matrix sumstat(4, 1, 0.0);
        for (std::size_t row = 0; row < 4; ++row) {
            param(row, 0) = static_cast<double>(row);
            sumstat(row, 0) = static_cast<double>(row);
        }

        abcpp::AbcOptions options;
        options.method = abcpp::Method::Rejection;
        options.tol = 0.5;

        const abcpp::AbcResult fit = abcpp::abc(
            std::vector<double>{1.1},
            param,
            sumstat,
            options
        );
        const abcpp::SummaryResult summary = abcpp::summary(fit);

        if (fit.unadj_values.rows() != 2 || summary.columns.size() != 1) {
            return 1;
        }
    } catch (const std::exception& error) {
        std::cerr << error.what() << "\n";
        return 1;
    }

    return 0;
}
