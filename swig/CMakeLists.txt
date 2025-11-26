if (NOT CC_X509_GEN_SWIG)
    return()
endif ()

if ("${CC_X509_SWIG_OUTPUT_DIR}" STREQUAL "")
    set (CC_X509_SWIG_OUTPUT_DIR "${CMAKE_BINARY_DIR}/output_swig")
endif ()

if ("${CC_X509_SWIG_SRC_DIR}" STREQUAL "")
    set (CC_X509_SWIG_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src)
endif ()

if ("${CC_X509_SWIG_LANGUAGES}" STREQUAL "")
    set (CC_X509_SWIG_LANGUAGES python java csharp)
endif ()

find_program(COMMSDSL2SWIG commsdsl2swig PATH_SUFFIXES bin REQUIRED)    

execute_process(COMMAND "${COMMSDSL2SWIG}" --version OUTPUT_VARIABLE commsdsl2swig_version)
if ("${commsdsl2swig_version}" VERSION_LESS "${CC_X509_MIN_COMMSDSL_VERSION}")
    message (FATAL_ERROR "Version of commsdsl2swig is too old, required minimum is v${CC_X509_MIN_COMMSDSL_VERSION}.")
endif ()

set (swig_tmp_dir "${CMAKE_BINARY_DIR}/output_swig.tmp")

add_custom_target("swig_output_tgt" ALL
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${swig_tmp_dir}
    COMMAND ${COMMSDSL2SWIG} -s -V ${CC_X509_VERSION} ${warn_as_error} ${COMMSDSL2SWIG_EXTRA_ARGS}
        -c ${CC_X509_SWIG_SRC_DIR} -o ${swig_tmp_dir} ${CC_X509_SCHEMA_FILES}
    COMMAND ${CMAKE_COMMAND}
        -DGENERATED="${swig_tmp_dir}" -DOUTPUT="${CC_X509_SWIG_OUTPUT_DIR}"
        -P "${PROJECT_SOURCE_DIR}/cmake/CopyGenerated.cmake"        
    DEPENDS "${PROJECT_SOURCE_DIR}/cmake/CopyGenerated.cmake" ${CC_X509_SCHEMA_FILES})

if (CC_X509_BUILD_SWIG)
        
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CC_X509_SWIG_OUTPUT_DIR}
    )    

    execute_process(
        COMMAND ${CMAKE_COMMAND} -E touch ${CC_X509_SWIG_OUTPUT_DIR}/dummy.txt
    )

    string (REPLACE ";" "|" combined_languages_str "${CC_X509_SWIG_LANGUAGES}")

    set (swig_build_dir ${CMAKE_CURRENT_BINARY_DIR}/swig_tgt_build)
    ExternalProject_Add(
        "swig_tgt"
        BUILD_ALWAYS TRUE
        DEPENDS ${X509_BUILD_TGT} "swig_output_tgt"
        SOURCE_DIR ${CC_X509_SWIG_OUTPUT_DIR}
        BINARY_DIR ${swig_build_dir}
        LIST_SEPARATOR |
        CMAKE_ARGS
            -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER} -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
            -DCMAKE_GENERATOR=${CMAKE_GENERATOR} -DCMAKE_GENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM}
            -DCMAKE_GENERATOR_TOOLSET=${CMAKE_GENERATOR_TOOLSET} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_EXE_LINKER_FLAGS=${CMAKE_EXE_LINKER_FLAGS}        
            -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
            -DCMAKE_PREFIX_PATH=${combined_prefix_path_str}
            -DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}
            -DOPT_SWIG_LANGUAGES=${combined_languages_str}
            -DOPT_USE_CCACHE=${CC_X509_USE_CCACHE}
            -DOPT_CCACHE_EXECUTABLE=${CC_X509_CCACHE_EXECUTABLE}
        INSTALL_COMMAND
            ${CMAKE_COMMAND} -E echo "Skipping install"            
    )   
endif ()