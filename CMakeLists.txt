cmake_minimum_required (VERSION 3.1)
project ("cc_x509")

option (CC_X509_WARN_AS_ERR "Treat warning as error" ON)
option (CC_X509_USE_CCACHE "Use ccache on UNIX systems if it's available" ON)
option (CC_X509_BUILD_APPS "Build applications." OFF)
option (CC_X509_USE_SANITIZERS "Build apps with sanitizers" OFF)
option (CC_X509_BUILD_DOC "Build documentation target in generated X.509 definition project" OFF)

# Additional variables to be used if needed
# ---------------------------
# CC_X509_DEF_OUTPUT_DIR - Output directory for X.509 definition project. Defaults to implementation defined path inside ${PROJECT_BINARY_DIR}
# CC_X509_EXTERNALS_DIR - Directory to contain sources for external projects, defaults to ${PROJECT_SOURCE_DIR}/externals.

# Other built-in CMake variables that can be used
# ---------------------------
# CMAKE_CXX_STANDARD - C++ standard to be used for built applications
# CMAKE_PREFIX_PATH - Path(s) to find externals like COMMS library
# CMAKE_PROGRAM_PATH - Path(s) to find programs like commsdsl2comms to parse the schema files(s)

################################################

if (NOT CC_X509_EXTERNALS_DIR)
    set (CC_X509_EXTERNALS_DIR "${PROJECT_SOURCE_DIR}/externals")
endif ()

if (NOT CC_X509_DEF_OUTPUT_DIR)
    set (CC_X509_DEF_OUTPUT_DIR "${PROJECT_BINARY_DIR}/output")
endif ()

################################################

set (CMAKE_SCIPTS_DIR "${PROJECT_SOURCE_DIR}/cmake")
include (${CMAKE_SCIPTS_DIR}/X509Compile.cmake)

# Compiler options
set (warn_opt)
if (CC_X509_WARN_AS_ERR)
    set (warn_opt WARN_AS_ERR)
endif ()

set (ccache_opt)
if ((UNIX) AND (CC_X509_USE_CCACHE))
    set (ccache_opt USE_CCACHE)
endif ()

CC_X509_compile(${warn_opt} ${ccache_opt})
CC_X509_msvc_force_warn_opt("/W4")

set (X509_BUILD_TGT "${PROJECT_NAME}_build_tgt")

add_subdirectory (cc_x509)
