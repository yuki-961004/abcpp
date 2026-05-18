#pragma once

/*
 * Include this file in exactly one downstream translation unit when using
 * abcpp from another R package via LinkingTo: abcpp.
 *
 * Example:
 *   #include <abcpp/abc.hpp>
 *   #include <abcpp/summary.hpp>
 *   #include <abcpp/abcpp_impl.hpp>
 */

#ifndef ABCPP_IMPL_INCLUDED
#define ABCPP_IMPL_INCLUDED

#include "abcpp/abc.hpp"
#include "abcpp/linear_algebra.hpp"
#include "abcpp/matrix.hpp"
#include "abcpp/options.hpp"
#include "abcpp/reduction.hpp"
#include "abcpp/result.hpp"
#include "abcpp/statistics.hpp"
#include "abcpp/summary.hpp"

#include "abcpp/detail/src/matrix.cpp"
#include "abcpp/detail/src/statistics.cpp"
#include "abcpp/detail/src/linear_algebra.cpp"
#include "abcpp/detail/src/options.cpp"
#include "abcpp/detail/src/result.cpp"
#include "abcpp/detail/src/reduction.cpp"
#include "abcpp/detail/src/summary.cpp"
#include "abcpp/detail/src/abc.cpp"

#endif  // ABCPP_IMPL_INCLUDED
