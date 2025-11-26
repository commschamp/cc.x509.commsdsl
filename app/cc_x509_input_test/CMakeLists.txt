find_program(COMMSDSL2TEST_EXE "commsdsl2test" PATH_SUFFIXES bin REQUIRED)

execute_process(COMMAND "${COMMSDSL2TEST_EXE}" --version OUTPUT_VARIABLE commsdsl2test_version)
if ("${commsdsl2test_version}" VERSION_LESS "${CC_X509_MIN_COMMSDSL_VERSION}")
    message (FATAL_ERROR "Version of commsdsl2test is too old, required minimum is v${CC_X509_MIN_COMMSDSL_VERSION}.")
endif ()

set (name "cc_x509_input_test")
set (output_dir ${CMAKE_CURRENT_BINARY_DIR}/output)
set (tmp_output_dir ${output_dir}.tmp)

set (code_input_dir "${CMAKE_CURRENT_SOURCE_DIR}/src")
set (code_input_param)
if (EXISTS "${code_input_dir}/")
    set (code_input_param -c ${code_input_dir})
endif()

set (output_tgt ${name}_output_tgt)
add_custom_target(${output_tgt} ALL
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${tmp_output_dir}
    COMMAND ${COMMSDSL2TEST_EXE} -s --warn-as-err -o ${tmp_output_dir} ${code_input_param} ${CC_X509_COMMSDSL2TEST_EXTRA_ARGS} ${CC_X509_SCHEMA_FILES}
    COMMAND ${CMAKE_COMMAND}
        -DGENERATED="${tmp_output_dir}" -DOUTPUT="${output_dir}"
        -P "${PROJECT_SOURCE_DIR}/cmake/CopyGenerated.cmake"
    DEPENDS "${PROJECT_SOURCE_DIR}/cmake/CopyGenerated.cmake" ${CC_X509_SCHEMA_FILES})

set (build_tgt ${name}_build_tgt)
set (build_dir ${output_dir}/build)
set (install_dir ${CMAKE_INSTALL_PREFIX})

execute_process (
    COMMAND ${CMAKE_COMMAND} -E make_directory "${build_dir}")

list(APPEND CMAKE_PREFIX_PATH ${CMAKE_INSTALL_PREFIX})

add_custom_target(${build_tgt} ALL
    COMMAND ${CMAKE_COMMAND} -E make_directory "${build_dir}"
    COMMAND
        ${CMAKE_COMMAND}
            ${output_dir}
            -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER} -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
            -DCMAKE_GENERATOR=${CMAKE_GENERATOR} -DCMAKE_GENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM}
            -DCMAKE_GENERATOR_TOOLSET=${CMAKE_GENERATOR_TOOLSET} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}
            -DCMAKE_INSTALL_PREFIX=${install_dir}
            -DCMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}"
    COMMAND
        ${CMAKE_COMMAND} --build ${build_dir} --config ${CMAKE_BUILD_TYPE} --target install
    WORKING_DIRECTORY ${build_dir}
    DEPENDS ${output_tgt} ${X509_BUILD_TGT})