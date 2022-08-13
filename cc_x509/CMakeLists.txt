find_program(COMMSDSL2COMMS_EXE "commsdsl2comms" PATH_SUFFIXES bin REQUIRED)

set (name ${PROJECT_NAME})
set (output_dir ${CMAKE_CURRENT_BINARY_DIR}/output)
set (tmp_output_dir ${output_dir}.tmp)
set (schema_files 
    ${CC_X509_ASN1_SCHEMA} 
    ${CMAKE_CURRENT_SOURCE_DIR}/dsl/main_schema.xml
    ${CC_X509_ASN1_EMB_SCHEMA} 
    ${CMAKE_CURRENT_SOURCE_DIR}/dsl/fields_schema.xml)


if (NOT "${CC_X509_DEF_OUTPUT_DIR}" STREQUAL "")
    set (output_dir ${CC_X509_DEF_OUTPUT_DIR})
endif ()
set (x509_code_input_dir ${CMAKE_CURRENT_SOURCE_DIR}/dsl_src)
set (code_input_param)
if (EXISTS "${x509_code_input_dir}/")
    set (combined_code_input_dir ${CMAKE_CURRENT_BINARY_DIR}/${name}_dsl_src)
    execute_process (
        COMMAND ${CMAKE_COMMAND} -E make_directory ${combined_code_input_dir})

    execute_process (
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${CC_X509_ASN1_DSL_SRC}/ ${x509_code_input_dir}/ ${combined_code_input_dir}/)
                
    set (code_input_param -c ${combined_code_input_dir})
else ()
    set (code_input_param -c ${CC_X509_ASN1_DSL_SRC})
endif()

set (rm_tmp_tgt ${name}_rm_tmp_tgt)
add_custom_target(${rm_tmp_tgt}
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${tmp_output_dir}
)

add_custom_command(
    OUTPUT ${tmp_output_dir}
    DEPENDS ${schema_files} ${rm_tmp_tgt}
    COMMAND ${COMMSDSL2COMMS_EXE} -d -s -V ${VERSION} --warn-as-err -o ${tmp_output_dir} ${code_input_param} ${CC_X509_COMMSDSL2COMMS_EXTRA_ARGS} ${schema_files}
)

set (output_tgt ${name}_output_tgt)
add_custom_target(${output_tgt} ALL
    COMMAND ${CMAKE_COMMAND}
        -DGENERATED="${tmp_output_dir}" -DOUTPUT="${output_dir}" -DCLEANUP_DIRS="doc\;include" 
        -P "${PROJECT_SOURCE_DIR}/cmake/CopyGenerated.cmake"
    DEPENDS ${tmp_output_dir} "${PROJECT_SOURCE_DIR}/cmake/CopyGenerated.cmake" ${schema_files})

set (build_tgt ${X509_BUILD_TGT})
set (build_dir ${CMAKE_CURRENT_BINARY_DIR}/build)
set (install_dir ${CMAKE_INSTALL_PREFIX})

execute_process (
    COMMAND ${CMAKE_COMMAND} -E make_directory "${build_dir}")

set (readme_src_file "${CMAKE_CURRENT_SOURCE_DIR}/readme.generated")
set (readme_tgt_file "${output_dir}/README.md")

add_custom_target("copy_readme_file"
    COMMAND 
        ${CMAKE_COMMAND} -E copy ${readme_src_file} ${readme_tgt_file}
    DEPENDS ${output_tgt} ${readme_src_file})

execute_process (
    COMMAND ${CMAKE_COMMAND} -E make_directory "${build_dir}")

execute_process (
    COMMAND ${CMAKE_COMMAND} -E make_directory "${output_dir}/include")        

execute_process (
    COMMAND ${CMAKE_COMMAND} -E touch "${output_dir}/include/dummy.txt")    

include(ExternalProject)
ExternalProject_Add(
    ${build_tgt}
    BUILD_ALWAYS TRUE
    DEPENDS ${output_tgt} ${copy_readme_file}
    SOURCE_DIR ${output_dir}
    BINARY_DIR ${build_dir}
    INSTALL_DIR ${install_dir}
    CMAKE_GENERATOR ${CMAKE_GENERATOR}
    CMAKE_ARGS 
        -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER} -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} -DCMAKE_GENERATOR=${CMAKE_GENERATOR}
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} 
        -DCMAKE_INSTALL_PREFIX=${install_dir}
        -DOPT_REQUIRE_COMMS_LIB=OFF
)   

if (CC_X509_BUILD_DOC)
    find_package (Doxygen REQUIRED)

    ExternalProject_Add_Step(
        ${build_tgt}
        "doc"
        COMMAND ${CMAKE_COMMAND} --build ${build_dir} --target doc_${name}
        DEPENDEES "build"
        DEPENDERS "install"
    )    

endif ()    