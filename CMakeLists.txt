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
# CC_X509_COMMSDSL2COMMS_EXTRA_ARGS - Extra command line parameters to be passed to commsdsl2comms
# CC_X509_COMMSDSL2TEST_EXTRA_ARGS - Extra command line parameters to be passed to commsdsl2test

# Other built-in CMake variables that can be used
# ---------------------------
# CMAKE_CXX_STANDARD - C++ standard to be used for built applications
# CMAKE_PREFIX_PATH - Path(s) to find externals like COMMS library
# CMAKE_PROGRAM_PATH - Path(s) to find programs like commsdsl2comms to parse the schema files(s)

################################################

if (NOT CC_X509_DEF_OUTPUT_DIR)
    set (CC_X509_DEF_OUTPUT_DIR "${PROJECT_BINARY_DIR}/output")
endif ()

if ("${CMAKE_BUILD_TYPE}" STREQUAL "")
    set (CMAKE_BUILD_TYPE "None")
endif ()

set (VERSION "0.2")

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

find_file(CC_X509_ASN1_SCHEMA "schema.xml" PATH_SUFFIXES cc_asn1/dsl share/cc_asn1/dsl usr/share/cc_asn1/dsl)
find_file(CC_X509_ASN1_EMB_SCHEMA "emb_schema.xml" PATH_SUFFIXES cc_asn1/dsl share/cc_asn1/dsl usr/share/cc_asn1/dsl)

if ((NOT CC_X509_ASN1_SCHEMA) OR (NOT CC_X509_ASN1_EMB_SCHEMA))
    message (FATAL_ERROR "The required ASN.1 definition schema is not found.")
endif ()

get_filename_component(asn1_dir ${CC_X509_ASN1_SCHEMA} DIRECTORY)
set (CC_X509_ASN1_DSL_SRC ${asn1_dir}/../dsl_src)

if (NOT EXISTS ${CC_X509_ASN1_DSL_SRC})
    message (FATAL_ERROR "The extra source files of the ASN.1 definition schema haven't been found in expected location \"${CC_X509_ASN1_DSL_SRC}\".")
endif ()

add_subdirectory (cc_x509)
add_subdirectory (app)