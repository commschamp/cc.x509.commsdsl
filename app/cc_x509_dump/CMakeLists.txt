find_program(COMMSDSL2TEST_EXE "commsdsl2test" PATH_SUFFIXES bin REQUIRED)

set (name "cc_x509_dump")
set (output_dir ${CMAKE_CURRENT_BINARY_DIR}/output)
set (tmp_output_dir ${output_dir}.tmp)
file (GLOB x509_schema_files ${PROJECT_SOURCE_DIR}/cc_x509/dsl/*.xml)
set (schema_files ${CC_X509_ASN1_SCHEMA} ${x509_schema_files})

set (code_input_dir "${CMAKE_CURRENT_SOURCE_DIR}/src")
set (code_input_param)
if (EXISTS "${code_input_dir}/")
    set (code_input_param -c ${code_input_dir})
endif()    

set (rm_tmp_tgt ${name}_rm_tmp_tgt)
add_custom_target(${rm_tmp_tgt}
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${tmp_output_dir}
)

add_custom_command(
    OUTPUT ${tmp_output_dir}
    DEPENDS ${schema_files} ${rm_tmp_tgt}
    COMMAND ${COMMSDSL2TEST_EXE} -d -s --warn-as-err -o ${tmp_output_dir} ${code_input_param} ${schema_files}
)

set (output_tgt ${name}_output_tgt)
add_custom_target(${output_tgt} ALL
    COMMAND ${CMAKE_COMMAND}
        -DGENERATED="${tmp_output_dir}" -DOUTPUT="${output_dir}" 
        -P "${PROJECT_SOURCE_DIR}/cmake/CopyGenerated.cmake"
    DEPENDS ${tmp_output_dir} "${PROJECT_SOURCE_DIR}/cmake/CopyGenerated.cmake" ${schema_files})

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
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} -DCMAKE_GENERATOR=${CMAKE_GENERATOR}
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} 
            -DCMAKE_CXX_STANDARD=${COMMSDSL_TESTS_CXX_STANDARD}
            -DCMAKE_INSTALL_PREFIX=${install_dir}
            -DCMAKE_PREFIX_PATH="\"${CMAKE_PREFIX_PATH}\""
            -DOPT_TEST_RENAME=${name}
            -DOPT_TEST_OPTIONS=X509DefaultOptions
    COMMAND
        ${CMAKE_COMMAND} --build ${build_dir} --config ${CMAKE_BUILD_TYPE} --target install
    WORKING_DIRECTORY ${build_dir}
    DEPENDS ${output_tgt} ${X509_BUILD_TGT})