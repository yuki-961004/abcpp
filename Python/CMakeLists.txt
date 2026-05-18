cmake_minimum_required(VERSION 3.15...3.27)
project(abcpp_python CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(MSVC)
    add_compile_options(/utf-8 /W3 /wd4267)
endif()

find_package(pybind11 CONFIG REQUIRED)

if(NOT TARGET abcpp)
    add_library(abcpp STATIC
        ${CMAKE_CURRENT_LIST_DIR}/../Cpp/src/abc.cpp
        ${CMAKE_CURRENT_LIST_DIR}/../Cpp/src/linear_algebra.cpp
        ${CMAKE_CURRENT_LIST_DIR}/../Cpp/src/matrix.cpp
        ${CMAKE_CURRENT_LIST_DIR}/../Cpp/src/options.cpp
        ${CMAKE_CURRENT_LIST_DIR}/../Cpp/src/reduction.cpp
        ${CMAKE_CURRENT_LIST_DIR}/../Cpp/src/result.cpp
        ${CMAKE_CURRENT_LIST_DIR}/../Cpp/src/statistics.cpp
        ${CMAKE_CURRENT_LIST_DIR}/../Cpp/src/summary.cpp
    )
    set_property(TARGET abcpp PROPERTY POSITION_INDEPENDENT_CODE ON)
    target_include_directories(abcpp PUBLIC
        ${CMAKE_CURRENT_LIST_DIR}/../Cpp/include
    )
endif()

pybind11_add_module(_core MODULE src/py_abcpp.cpp)
target_link_libraries(_core PRIVATE abcpp)

install(TARGETS _core DESTINATION abcpp)
