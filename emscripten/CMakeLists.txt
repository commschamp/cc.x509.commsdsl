if (NOT CC_X509_GEN_EMSCRIPTEN)
    return()
endif ()

if ("${CC_X509_EMSCRIPTEN_OUTPUT_DIR}" STREQUAL "")
    set (CC_X509_EMSCRIPTEN_OUTPUT_DIR "${CMAKE_BINARY_DIR}/output_emscripten")
endif ()

find_program(COMMSDSL2EMSCRIPTEN commsdsl2emscripten PATH_SUFFIXES bin REQUIRED)    
find_program(EMCMAKE_EXECUTABLE emcmake REQUIRED)    

execute_process(COMMAND "${COMMSDSL2EMSCRIPTEN}" --version OUTPUT_VARIABLE commsdsl2emscirpten_version)
if ("${commsdsl2emscirpten_version}" VERSION_LESS "${CC_X509_MIN_COMMSDSL_VERSION}")
    message (FATAL_ERROR "Version of commsdsl2emscirpten is too old, required minimum is v${CC_X509_MIN_COMMSDSL_VERSION}.")
endif ()

set (emscripten_tmp_dir "${CMAKE_BINARY_DIR}/output_emscripten.tmp")

add_custom_target(rm_emscripten_tmp_tgt
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${emscripten_tmp_dir}
)

add_custom_command(
    OUTPUT ${emscripten_tmp_dir}
    DEPENDS ${CC_X509_SCHEMA_FILES} ${src_files} rm_emscripten_tmp_tgt
    COMMAND ${COMMSDSL2EMSCRIPTEN} -s ${warn_as_error} ${COMMSDSL2EMSCRIPTEN_EXTRA_ARGS}
        -o ${emscripten_tmp_dir} -c ${CMAKE_CURRENT_SOURCE_DIR}/src ${CC_X509_SCHEMA_FILES}
)

add_custom_target("emscripten_output_tgt" ALL
    COMMAND ${CMAKE_COMMAND}
        -DGENERATED="${emscripten_tmp_dir}" -DOUTPUT="${CC_X509_EMSCRIPTEN_OUTPUT_DIR}"
        -P "${PROJECT_SOURCE_DIR}/cmake/CopyGenerated.cmake"        
    DEPENDS ${emscripten_tmp_dir} "${PROJECT_SOURCE_DIR}/cmake/CopyGenerated.cmake" ${CC_X509_SCHEMA_FILES})

if (CC_X509_BUILD_EMSCRIPTEN)
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CC_X509_EMSCRIPTEN_OUTPUT_DIR}
    )    

    execute_process(
        COMMAND ${CMAKE_COMMAND} -E touch ${CC_X509_EMSCRIPTEN_OUTPUT_DIR}/dummy.txt
    )

    find_package(LibComms REQUIRED)
    get_target_property(comms_include_dirs cc::comms INTERFACE_INCLUDE_DIRECTORIES)
    set (prot_include_dir "${CMAKE_INSTALL_PREFIX}/include")
    set (extra_includes_path ${prot_include_dir} ${comms_include_dirs})
    string (REPLACE ";" "|" extra_includes_path_str "${extra_includes_path}")    

    set (emscripten_build_dir ${CMAKE_CURRENT_BINARY_DIR}/emscripten_tgt_build)
    ExternalProject_Add(
        "emscripten_tgt"
        BUILD_ALWAYS TRUE
        DEPENDS ${X509_BUILD_TGT} "emscripten_output_tgt"
        SOURCE_DIR ${CC_X509_EMSCRIPTEN_OUTPUT_DIR}
        BINARY_DIR ${emscripten_build_dir}
        CMAKE_COMMAND ${EMCMAKE_EXECUTABLE} ${CMAKE_COMMAND}
        LIST_SEPARATOR |
        CMAKE_ARGS
            -DCMAKE_GENERATOR=${CMAKE_GENERATOR} -DCMAKE_GENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM}
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} 
            -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
            -DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}
            -DOPT_MODULARIZE=ON
            -DOPT_EXTRA_INCLUDE_DIRS=${extra_includes_path_str}
    )  
endif ()