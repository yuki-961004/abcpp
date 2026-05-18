cmake_minimum_required(VERSION 3.15...3.27)
project(abcpp VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(MSVC)
    add_compile_options(/utf-8 /W3 /wd4267)
endif()

if(CMAKE_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR)
    set(ABCPP_IS_TOP_LEVEL ON)
else()
    set(ABCPP_IS_TOP_LEVEL OFF)
endif()

if(ABCPP_IS_TOP_LEVEL)
    option(ABCPP_BUILD_TESTS "Build abcpp C++ tests" ON)
    option(ABCPP_BUILD_PYTHON "Build the abcpp Python frontend" ON)
else()
    option(ABCPP_BUILD_TESTS "Build abcpp C++ tests" OFF)
    option(ABCPP_BUILD_PYTHON "Build the abcpp Python frontend" OFF)
endif()

add_subdirectory(Cpp)

if(ABCPP_BUILD_TESTS)
    enable_testing()
    add_executable(abcpp_tests tests/Cpp/test_core.cpp)
    target_link_libraries(abcpp_tests PRIVATE abcpp::abc)
    add_test(NAME abcpp_tests COMMAND abcpp_tests)

    add_executable(
        abcpp_linkingto_header_tests
        tests/Cpp/test_linkingto_header.cpp
    )
    target_include_directories(
        abcpp_linkingto_header_tests
        PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/R/inst/include
    )
    add_test(
        NAME abcpp_linkingto_header_tests
        COMMAND abcpp_linkingto_header_tests
    )
endif()

if(ABCPP_BUILD_PYTHON)
    add_subdirectory(Python)
endif()
