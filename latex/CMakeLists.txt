if (NOT CC_X509_GEN_LATEX)
    return()
endif ()

if ("${CC_X509_LATEX_OUTPUT_DIR}" STREQUAL "")
    set (CC_X509_LATEX_OUTPUT_DIR "${CMAKE_BINARY_DIR}/output_latex")
endif ()

find_program(COMMSDSL2LATEX commsdsl2latex PATH_SUFFIXES bin REQUIRED)

execute_process(COMMAND "${COMMSDSL2LATEX}" --version OUTPUT_VARIABLE commsdsl2latex_version)
if ("${commsdsl2latex_version}" VERSION_LESS "${CC_X509_MIN_COMMSDSL_VERSION}")
    message (FATAL_ERROR "Version of commsdsl2latex is too old, required minimum is v${CC_X509_MIN_COMMSDSL_VERSION}.")
endif ()

set (latex_tmp_dir "${CMAKE_BINARY_DIR}/output_latex.tmp")

add_custom_target("latext_output_tgt" ALL
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${latex_tmp_dir}
    COMMAND ${COMMSDSL2LATEX} -s ${warn_as_error} ${COMMSDSL2LATEX_EXTRA_ARGS}
        -o ${latex_tmp_dir} -c ${CMAKE_CURRENT_SOURCE_DIR}/src ${CC_X509_SCHEMA_FILES}
    COMMAND ${CMAKE_COMMAND}
        -DGENERATED="${latex_tmp_dir}" -DOUTPUT="${CC_X509_LATEX_OUTPUT_DIR}"
        -P "${PROJECT_SOURCE_DIR}/cmake/CopyGenerated.cmake"
    DEPENDS "${PROJECT_SOURCE_DIR}/cmake/CopyGenerated.cmake" ${CC_X509_SCHEMA_FILES})

if (CC_X509_BUILD_LATEX)
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CC_X509_LATEX_OUTPUT_DIR}
    )

    execute_process(
        COMMAND ${CMAKE_COMMAND} -E touch ${CC_X509_LATEX_OUTPUT_DIR}/dummy.txt
    )

    set (combined_prefix_path ${CMAKE_INSTALL_PREFIX} ${CMAKE_PREFIX_PATH})
    string (REPLACE ";" "|" combined_prefix_path_str "${combined_prefix_path}")

    set (latex_build_dir ${CMAKE_CURRENT_BINARY_DIR}/latex_tgt_build)
    ExternalProject_Add(
        "latex_tgt"
        BUILD_ALWAYS TRUE
        DEPENDS "latext_output_tgt"
        SOURCE_DIR ${CC_X509_LATEX_OUTPUT_DIR}
        BINARY_DIR ${latex_build_dir}
        LIST_SEPARATOR |
        CMAKE_ARGS
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -DCMAKE_PREFIX_PATH=${combined_prefix_path_str}
        BUILD_COMMAND
            ${CMAKE_COMMAND} --build ${latex_build_dir} --config ${CMAKE_BUILD_TYPE} --target all_artifacts
        INSTALL_COMMAND
            ${CMAKE_COMMAND} -E echo "No install for documentation build"
    )
endif ()