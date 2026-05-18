"""Synchronize the C++ backend headers used by the R package.

The authoritative backend lives in ``Cpp/``.  The R package needs installed
headers for ``LinkingTo: abcpp`` and a header-implementation bundle so downstream
R packages can get C++ symbols without vendoring the abcpp source tree.
"""

import argparse
import filecmp
import shutil
import sys
from pathlib import Path


HEADER_NAMES = [
    "abc.hpp",
    "abcpp.hpp",
    "linear_algebra.hpp",
    "matrix.hpp",
    "options.hpp",
    "reduction.hpp",
    "result.hpp",
    "statistics.hpp",
    "summary.hpp",
]

SOURCE_NAMES = [
    "matrix.cpp",
    "statistics.cpp",
    "linear_algebra.cpp",
    "options.cpp",
    "result.cpp",
    "reduction.cpp",
    "summary.cpp",
    "abc.cpp",
]

IMPL_HEADER = """#pragma once

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
"""


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def copy_if_changed(source: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    if destination.exists() and filecmp.cmp(source, destination, shallow=False):
        return
    shutil.copy2(source, destination)


def sync() -> None:
    root = repo_root()
    include_source = root / "Cpp" / "include" / "abcpp"
    source_source = root / "Cpp" / "src"
    include_target = root / "R" / "inst" / "include" / "abcpp"
    source_target = include_target / "detail" / "src"

    for name in HEADER_NAMES:
        copy_if_changed(include_source / name, include_target / name)
    for name in SOURCE_NAMES:
        copy_if_changed(source_source / name, source_target / name)

    impl_target = include_target / "abcpp_impl.hpp"
    impl_target.parent.mkdir(parents=True, exist_ok=True)
    if not impl_target.exists() or impl_target.read_text() != IMPL_HEADER:
        impl_target.write_text(IMPL_HEADER)


def check() -> int:
    root = repo_root()
    include_source = root / "Cpp" / "include" / "abcpp"
    source_source = root / "Cpp" / "src"
    include_target = root / "R" / "inst" / "include" / "abcpp"
    source_target = include_target / "detail" / "src"
    mismatches = []

    for name in HEADER_NAMES:
        source = include_source / name
        target = include_target / name
        if not target.exists() or not filecmp.cmp(source, target, shallow=False):
            mismatches.append(str(target))

    for name in SOURCE_NAMES:
        source = source_source / name
        target = source_target / name
        if not target.exists() or not filecmp.cmp(source, target, shallow=False):
            mismatches.append(str(target))

    impl_target = include_target / "abcpp_impl.hpp"
    if not impl_target.exists() or impl_target.read_text() != IMPL_HEADER:
        mismatches.append(str(impl_target))

    if mismatches:
        print("R installed C++ headers are out of sync:")
        for path in mismatches:
            print(f"  {path}")
        return 1

    print("R installed C++ headers are in sync.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Sync Cpp/ backend headers into R/inst/include/abcpp."
    )
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    if args.check:
        return check()

    sync()
    print("Synchronized Cpp/ backend headers into R/inst/include/abcpp.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
