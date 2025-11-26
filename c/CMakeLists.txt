if (NOT CC_X509_GEN_C)
    return()
endif ()

if ("${CC_X509_C_OUTPUT_DIR}" STREQUAL "")
    set (CC_X509_C_OUTPUT_DIR "${CMAKE_BINARY_DIR}/output_c")
endif ()

find_program(COMMSDSL2C commsdsl2c PATH_SUFFIXES bin REQUIRED)    

execute_process(COMMAND "${COMMSDSL2C}" --version OUTPUT_VARIABLE commsdsl2c_version)
if ("${commsdsl2c_version}" VERSION_LESS "${CC_X509_MIN_COMMSDSL_VERSION}")
    message (FATAL_ERROR "Version of commsdsl2c is too old, required minimum is v${CC_X509_MIN_COMMSDSL_VERSION}.")
endif ()

set (c_tmp_dir "${CMAKE_BINARY_DIR}/output_c.tmp")

add_custom_target("c_output_tgt" ALL
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${c_tmp_dir}
    COMMAND ${COMMSDSL2C} -s ${warn_as_error} -V ${CC_X509_VERSION} ${COMMSDSL2C_EXTRA_ARGS}
        -o ${c_tmp_dir} -c ${CMAKE_CURRENT_SOURCE_DIR}/src ${CC_X509_SCHEMA_FILES}
    COMMAND ${CMAKE_COMMAND}
        -DGENERATED="${c_tmp_dir}" -DOUTPUT="${CC_X509_C_OUTPUT_DIR}"
        -P "${PROJECT_SOURCE_DIR}/cmake/CopyGenerated.cmake"        
    DEPENDS "${PROJECT_SOURCE_DIR}/cmake/CopyGenerated.cmake" ${CC_X509_SCHEMA_FILES})

if (CC_X509_BUILD_C)
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CC_X509_C_OUTPUT_DIR}
    )    

    execute_process(
        COMMAND ${CMAKE_COMMAND} -E touch ${CC_X509_C_OUTPUT_DIR}/dummy.txt
    )

    set (combined_prefix_path ${CMAKE_INSTALL_PREFIX} ${CMAKE_PREFIX_PATH})
    string (REPLACE ";" "|" combined_prefix_path_str "${combined_prefix_path}")    

    set (c_build_dir ${CMAKE_CURRENT_BINARY_DIR}/c_tgt_build)
    ExternalProject_Add(
        "c_tgt"
        BUILD_ALWAYS TRUE
        DEPENDS ${X509_BUILD_TGT} "c_output_tgt"
        SOURCE_DIR ${CC_X509_C_OUTPUT_DIR}
        BINARY_DIR ${c_build_dir}
        LIST_SEPARATOR |
        CMAKE_ARGS
            -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER} -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
            -DCMAKE_GENERATOR=${CMAKE_GENERATOR} -DCMAKE_GENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM}
            -DCMAKE_GENERATOR_TOOLSET=${CMAKE_GENERATOR_TOOLSET} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_EXE_LINKER_FLAGS=${CMAKE_EXE_LINKER_FLAGS}           
            -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -DCMAKE_PREFIX_PATH=${combined_prefix_path_str}
            -DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}
            -DOPT_USE_CCACHE=${CC_X509_USE_CCACHE}
            -DOPT_CCACHE_EXECUTABLE=${CC_X509_CCACHE_EXECUTABLE}
    ) 

    find_package(Doxygen)
    if (CC_X509_BUILD_DOC AND DOXYGEN_FOUND)
        ExternalProject_Add_Step(
            "c_tgt" 
            "doc"
            COMMAND ${CMAKE_COMMAND} --build ${c_build_dir} --target doc_cc_x509_c
            DEPENDEES "build"
            DEPENDERS "install"
        )
    endif ()      
endif ()