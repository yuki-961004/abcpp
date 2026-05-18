add_library(abcpp
    src/abc.cpp
    src/linear_algebra.cpp
    src/matrix.cpp
    src/options.cpp
    src/reduction.cpp
    src/result.cpp
    src/statistics.cpp
    src/summary.cpp
)

add_library(abcpp::abc ALIAS abcpp)

set_property(TARGET abcpp PROPERTY POSITION_INDEPENDENT_CODE ON)
set_target_properties(abcpp PROPERTIES
    EXPORT_NAME abc
    OUTPUT_NAME abcpp
)

target_include_directories(abcpp PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

install(
    TARGETS abcpp
    EXPORT abcppTargets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

install(
    DIRECTORY include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

install(
    EXPORT abcppTargets
    FILE abcppTargets.cmake
    NAMESPACE abcpp::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/abcpp
)

configure_package_config_file(
    ${CMAKE_CURRENT_LIST_DIR}/cmake/abcppConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/abcppConfig.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/abcpp
)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/abcppConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

install(
    FILES
        ${CMAKE_CURRENT_BINARY_DIR}/abcppConfig.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/abcppConfigVersion.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/abcpp
)
