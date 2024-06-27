# This file contains contains a function that prefetches comms project. 

# ******************************************************
# Set predefined compilation flags
#     cc_x509_compile(
#         [WARN_AS_ERR]
#         [USE_CCACHE]
#         [CCACHE_EXECUTABLE /path/to/ccache]
#         [DEFAULT_SANITIZERS]
#     )
#
# - WARN_AS_ERR - Treat warnings as errors.
# - STATIC_RUNTIME - Static link with runtime.
# - USE_CCACHE - Force usage of ccache
# 
# ******************************************************
# Update default MSVC warning level option
#     cc_x509_msvc_force_warn_opt(opt)
# 
# Example:
#     cc_x509_msvc_force_warn_opt("/W4")
#

macro (cc_x509_compile)
    set (_prefix CC_X509_COMPILE)
    set (_options WARN_AS_ERR STATIC_RUNTIME USE_CCACHE DEFAULT_SANITIZERS)
    set (_oneValueArgs CCACHE_EXECUTABLE)
    set (_mutiValueArgs)
    cmake_parse_arguments(${_prefix} "${_options}" "${_oneValueArgs}" "${_mutiValueArgs}" ${ARGN})
   
    if ((CMAKE_COMPILER_IS_GNUCC) OR ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang"))
        set (extra_flags_list
            "-Wall" "-Wextra" "-Wcast-align" "-Wcast-qual" "-Wctor-dtor-privacy"
            "-Wmissing-include-dirs"
            "-Woverloaded-virtual" "-Wredundant-decls" "-Wshadow" "-Wundef" "-Wunused"
            "-Wno-unknown-pragmas" "-fdiagnostics-show-option"
            "-Wcast-align" "-Wunused" "-Wconversion" 
            "-Wold-style-cast" "-Wdouble-promotion"
            
            "-Wno-sign-conversion" # This one is impractical
        )

        if (CMAKE_COMPILER_IS_GNUCC)
            list (APPEND extra_flags_list
                "-Wnoexcept" "-Wlogical-op" "-Wstrict-null-sentinel"
            )

            if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "4.8")
                list (APPEND extra_flags_list
                    "-Wno-pragmas" "-Wno-type-limits"
                )
            endif()

            if(NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS "6.0")
                list (APPEND extra_flags_list
                    "-Wmisleading-indentation" "-Wduplicated-cond" 
                )
            endif()      

            if(NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS "7.0")
                list (APPEND extra_flags_list
                    "-Wduplicated-branches" 
                )
            endif()                        

        endif ()

        if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
            list (APPEND extra_flags_list "-Wno-dangling-field -Wno-unused-command-line-argument")
        endif ()
        
        if (CC_X509_COMPILE_WARN_AS_ERR)
            list (APPEND extra_flags_list "-Werror")
        endif ()

        set (CC_X509_SANITIZER_OPTS)
        if (CC_X509_COMPILE_DEFAULT_SANITIZERS AND
            ((CMAKE_COMPILER_IS_GNUCC) OR ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")))
            set (CC_X509_SANITIZER_OPTS 
                -fno-omit-frame-pointer 
                -fno-sanitize-recover=address 
                -fsanitize=address
                -fno-sanitize-recover=undefined
                -fsanitize=undefined)
        endif ()

        if ((NOT "${CC_X509_SANITIZER_OPTS}" STREQUAL "") AND (${CMAKE_VERSION} VERSION_LESS "3.13"))
            message (WARNING "The CMake version is too old, expected at least 3.13, sanitizers are disabled")
            set (CC_X509_SANITIZER_OPTS)
        endif ()        

        list (APPEND extra_flags_list ${CC_X509_SANITIZER_OPTS})
        
        string(REPLACE ";" " " extra_flags "${extra_flags_list}")
        set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${extra_flags}")
        
        if (CC_X509_COMPILE_STATIC_RUNTIME)
            SET(CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} -static-libstdc++ -static-libgcc")
        endif ()


    elseif (MSVC)
        add_definitions("/wd4503" "-D_SCL_SECURE_NO_WARNINGS")

        if (CC_X509_COMPILE_WARN_AS_ERR)
            add_definitions("/WX")
        endif ()

        if (CC_X509_COMPILE_STATIC_RUNTIME)
            foreach(flag_var 
                    CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE
                    CMAKE_CXX_FLAGS_MINSIZEREL CMAKE_CXX_FLAGS_RELWITHDEBINFO)
                if(${flag_var} MATCHES "/MD")
                    string(REGEX REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
                endif()
            endforeach()
        endif ()
    endif ()   

    if (CC_X509_COMPILE_USE_CCACHE)
        if (NOT CC_X509_COMPILE_CCACHE_EXECUTABLE)
            find_program(CC_X509_COMPILE_CCACHE_EXECUTABLE ccache)
        endif ()

        if (CC_X509_COMPILE_CCACHE_EXECUTABLE)
            set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ${CC_X509_COMPILE_CCACHE_EXECUTABLE})
            set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ${CC_X509_COMPILE_CCACHE_EXECUTABLE})
        endif ()
    endif ()      
endmacro()

macro (cc_x509_msvc_force_warn_opt opt)
    if (MSVC)
        foreach(flag_var 
                CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE
                CMAKE_CXX_FLAGS_MINSIZEREL CMAKE_CXX_FLAGS_RELWITHDEBINFO)

            string(REGEX REPLACE "/W1" "${opt}" ${flag_var} "${${flag_var}}")
            string(REGEX REPLACE "/W2" "${opt}" ${flag_var} "${${flag_var}}")
            string(REGEX REPLACE "/W3" "${opt}" ${flag_var} "${${flag_var}}")
            string(REGEX REPLACE "/W4" "${opt}" ${flag_var} "${${flag_var}}")
            string(REGEX REPLACE "/Wall" "${opt}" ${flag_var} "${${flag_var}}")
        endforeach()    
    endif ()
endmacro()