cmake_minimum_required (VERSION 3.27)

#  options witch have affect
#  SF_OPENSSL_STATIC_BUILD - provide static or shared build of OPENSSL
#  SF_OPENSSL_USE_SYSTEM_BUILD - use system version of openssl
#  OpenSSL_GIT_TAG - version for building ( git TAG)
#
option(SF_OPENSSL_STATIC_BUILD "Build openssl as static library" ON)
option(SF_OPENSSL_USE_SYSTEM_BUILD "Using system variant of openssl" OFF)
set(OpenSSL_GIT_TAG "openssl-3.2.1" CACHE STRING "OpenSLL git tag for custom build")

include(support_function)
include(ExternalProject)
include(ProcessorCount)


find_package(Perl REQUIRED)
find_package(Threads REQUIRED)

set(EXTR_PROJECT_NAME "OpenSSL")
sf_generate_names(${EXTR_PROJECT_NAME})

function(sf_openssl_verson_build_from_tag OPENSSL_MAJOR_L OPENSSL_MINOR_L OPENSSL_PATCH_L)
    string(REGEX MATCHALL "([0-9]+)?([0-9]+)?([0-9]+)" OPENSSL_OUT_VERS ${OpenSSL_GIT_TAG})
    list(GET OPENSSL_OUT_VERS 0 ${OPENSSL_MAJOR_L})
    list(GET OPENSSL_OUT_VERS 1 ${OPENSSL_MINOR_L})
    list(GET OPENSSL_OUT_VERS 2 ${OPENSSL_PATCH_L})
    set(${OPENSSL_MAJOR_L} ${${OPENSSL_MAJOR_L}} PARENT_SCOPE)
    set(${OPENSSL_MINOR_L} ${${OPENSSL_MINOR_L}} PARENT_SCOPE)
    set(${OPENSSL_PATCH_L} ${${OPENSSL_PATCH_L}} PARENT_SCOPE)
endfunction()

function(sf_openssl_make_tool MAKE_TOOL_L)
    if(MINGW)
        set(MAKE_TOOL "mingw32_make")
    elseif(MSVC)
        set(MAKE_TOOL "nmake")
    else()
        set(MAKE_TOOL "make")
    endif()

    set(${MAKE_TOOL_L} ${MAKE_TOOL} PARENT_SCOPE)
    find_program(MAKETOOL NAMES ${MAKE_TOOL} REQUIRED)
endfunction()

function(sf_output_name SSL_NAME_L CRYPTO_NAME_L)
    if(NOT SF_OPENSSL_STATIC_BUILD)
        set(EXT ".so")
    else()
        set(EXT ".a")
    endif()
    set(${SSL_NAME_L} "libssl${EXT}" PARENT_SCOPE)
    set(${CRYPTO_NAME_L} "libcrypto${EXT}" PARENT_SCOPE)

endfunction()

function(sf_update_imported_target_property TGT_NAME TGT_LOCATION TGT_INCLUDE TGT_LANGUAGE)
    set_target_properties(${TGT_NAME} PROPERTIES
        IMPORTED_LOCATION ${TGT_LOCATION}
        LOCATION ${TGT_LOCATION}
        LOCATION_${CMAKE_BUILD_TYPE} ${TGT_LOCATION}
        VS_DEPLOYMENT_LOCATION ${TGT_LOCATION}
        INTERFACE_INCLUDE_DIRECTORIES ${TGT_INCLUDE}
        IMPORTED_LINK_INTERFACE_LANGUAGES ${TGT_LANGUAGE}
        SYSTEM ON
    )
    #set_property(TARGET ${TGT_NAME} PROPERTY IMPORTED_LOCATION ${TGT_LOCATION})
    #set_property(TARGET ${TGT_NAME} PROPERTY LOCATION ${TGT_LOCATION})
    #set_property(TARGET ${TGT_NAME} PROPERTY LOCATION_${CMAKE_BUILD_TYPE} ${TGT_LOCATION})
    #set_property(TARGET ${TGT_NAME} PROPERTY MACOSX_PACKAGE_LOCATION ${TGT_LOCATION})
    #set_property(TARGET ${TGT_NAME} PROPERTY VS_DEPLOYMENT_LOCATION ${TGT_LOCATION})
    #set_property(TARGET ${TGT_NAME} PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${TGT_INCLUDE})
    #set_property(TARGET ${TGT_NAME} PROPERTY IMPORTED_LINK_INTERFACE_LANGUAGES ${TGT_LANGUAGE} )
    #set_property(TARGET ${TGT_NAME} PROPERTY SYSTEM ON )
endfunction()

function(sf_make_imported_targets)
    if(SF_OPENSSL_STATIC_BUILD)
        set(OPENSSL_IMPORT_TYPE STATIC)
    else()
        set(OPENSSL_IMPORT_TYPE SHARED)
    endif()
    sf_output_name(SSL_NAME CRYPTO_NAME)

    add_library(OpenSSL::Crypto ${OPENSSL_IMPORT_TYPE} IMPORTED GLOBAL)
    add_dependencies(OpenSSL::Crypto OpenSSL)
    sf_update_imported_target_property(OpenSSL::Crypto
        "${${EXTR_PROJECT_NAME}_INSTALL_DIR}/lib/${CRYPTO_NAME}"
        "${${EXTR_PROJECT_NAME}_INSTALL_DIR}/inlude"
        "C"
    )

    add_library(OpenSSL::SSL ${OPENSSL_IMPORT_TYPE} IMPORTED GLOBAL)
    add_dependencies(OpenSSL::SSL OpenSSL)
    sf_update_imported_target_property(OpenSSL::SSL
        "${${EXTR_PROJECT_NAME}_INSTALL_DIR}/lib/${SSL_NAME}"
        "${${EXTR_PROJECT_NAME}_INSTALL_DIR}/inlude"
        "C"
    )

    if(SF_OPENSSL_STATIC_BUILD)
        set_property(TARGET OpenSSL::Crypto PROPERTY INTERFACE_LINK_LIBRARIES  Threads::Threads)
        set_property(TARGET OpenSSL::SSL PROPERTY INTERFACE_LINK_LIBRARIES OpenSSL::Crypto Threads::Threads)
    endif()

endfunction()

function(openSSL_as_external )
    if(SF_OPENSSL_STATIC_BUILD)
        set(OPENSSL_BUILD_TYPE no-shared no-pinshared no-legacy)
    else()
        set(OPENSSL_BUILD_TYPE shared)
    endif()
    sf_openssl_verson_build_from_tag(V_MAJOR V_MINOR V_PATCH)
    message(STATUS "OpenSSL version: ${V_MAJOR}.${V_MINOR}.${V_PATCH}")

    set(OPENSSL_API "3.0.0")
    if(${V_MAJOR} EQUAL 1)
        set(OPENSSL_API "1.1.1")
    endif()

    set(OPENSSL_OPT no-tests no-unit-test no-idea no-mdc2 no-rc5 ${OPENSSL_BUILD_TYPE} --api=${OPENSSL_API})
    sf_openssl_make_tool(MAKE_TOOL)
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(OPENSSL_OPT ${OPENSSL_OPT} --debug)
    else()
        set(OPENSSL_OPT ${OPENSSL_OPT} --release)
    endif()

    if(MINGW)
        if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL x86_64)
            set(OPENSSL_OPT ${OPENSSL_OPT} mingw64)
        else()
            set(OPENSSL_OPT ${OPENSSL_OPT} mingw)
        endif()
    elseif(LINUX)
        if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL "x86_64")
            set(OPENSSL_OPT ${OPENSSL_OPT} linux-generic64)
        else()
            set(OPENSSL_OPT ${OPENSSL_OPT} linux-generic32)
        endif()
    elseif(APPLE)
        set(OPENSSL_OPT ${OPENSSL_OPT}
            darwin64-x86_64-cc
            no-asm
            -arch%20x86_64
        )
        if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL "arm64")
            set(OPENSSL_OPT ${OPENSSL_CONFIGURE_OPTIONS}
                no-asm
                -arch%20arm64
                -arch%20x86_64
            )
        endif()
    endif()

    ProcessorCount(NUM_BUILD_JOBS)
    if( NUM_BUILD_JOBS EQUAL 0 )
        set( NUM_BUILD_JOBS 1 )
    endif()

    set(OPENSSL_SOURCE_CONFIGURE "${${EXTR_PROJECT_NAME}_SOURCE_DIR}/Configure")
    set(OPENSSL_OUTPUT_DIR ${${EXTR_PROJECT_NAME}_INSTALL_DIR})
    set(OPENSSL_DIR ${${EXTR_PROJECT_NAME}_INSTALL_DIR}/SSL)

    ExternalProject_Add(
        ${EXTR_PROJECT_NAME}
        PREFIX ${${EXTR_PROJECT_NAME}_PREFIX}
        STAMP_DIR ${${EXTR_PROJECT_NAME}_STAMP_DIR}
        SOURCE_DIR ${${EXTR_PROJECT_NAME}_SOURCE_DIR}
        BINARY_DIR ${${EXTR_PROJECT_NAME}_BINARY_DIR}

        GIT_REPOSITORY https://github.com/openssl/openssl.git
        GIT_TAG ${${EXTR_PROJECT_NAME}_GIT_TAG}
        GIT_SHALLOW ${${EXTR_PROJECT_NAME}_GIT_TAG}
        USES_TERMINAL_DOWNLOAD TRUE

        CONFIGURE_COMMAND
        perl  ${OPENSSL_SOURCE_CONFIGURE}
        ${OPENSSL_OPT}
        --prefix=${OPENSSL_OUTPUT_DIR}
        --openssldir=${OPENSSL_DIR}
        BUILD_COMMAND  ${MAKE_TOOL} depend --jobs=${NUM_BUILD_JOBS} && ${MAKE_TOOL} --jobs=${NUM_BUILD_JOBS}
        TEST_COMMAND ""
        INSTALL_COMMAND ${MAKE_TOOL} install_sw
        INSTALL_DIR ${${SUBPROJECT_ID}_INS}
        BUILD_ALWAYS OFF
    )

    sf_make_imported_targets()
    set(OPENSSL_FOUND ON PARENT_SCOPE)

    get_target_property(OPENSSL_INCLUDE_DIR OpenSSL::Crypto INTERFACE_INCLUDE_DIRECTORIES)
    set(OPENSSL_INCLUDE_DIR ${OPENSSL_INCLUDE_DIR} PARENT_SCOPE)

    get_target_property(OPENSSL_CRYPTO_LIBRARY OpenSSL::Crypto LOCATION)
    set(OPENSSL_CRYPTO_LIBRARY ${OPENSSL_CRYPTO_LIBRARY} PARENT_SCOPE)

    set(OPENSSL_CRYPTO_LIBRARIES "")

    get_target_property(OPENSSL_SSL_LIBRARY OpenSSL::Crypto LOCATION)
    set(OPENSSL_SSL_LIBRARY ${OPENSSL_SSL_LIBRARY} PARENT_SCOPE)


    set(OPENSSL_SSL_LIBRARIES "" )
    set(OPENSSL_LIBRARIES "")
    set(OPENSSL_VERSION ${V_MAJOR}.${V_MINOR}.${V_PATCH})
    set(OPENSSL_APPLINK_SOURCE "")
endfunction()


sf_find_local_package(OpenSSL ${${EXTR_PROJECT_NAME}_INSTALL_DIR} localOpenSSL)
if(NOT localOpenSSL)
    message(STATUS "Make OpenSSL as External Project")
    openSSL_as_external()
else()
    message(STATUS "Use prebuild OpenSSL")
endif()
# [cmake] -- OPENSSL_FOUND =
# [cmake] -- OPENSSL_INCLUDE_DIR = /home/atsesarskyi/build/CMakeHelpers/Debug/external/OpenSSL/include
# [cmake] -- OPENSSL_CRYPTO_LIBRARY = /home/atsesarskyi/build/CMakeHelpers/Debug/external/OpenSSL/lib/libcrypto.a
# [cmake] -- OPENSSL_CRYPTO_LIBRARIES =
# [cmake] -- OPENSSL_SSL_LIBRARY = /home/atsesarskyi/build/CMakeHelpers/Debug/external/OpenSSL/lib/libssl.a
# [cmake] -- OPENSSL_SSL_LIBRARIES =
# [cmake] -- OPENSSL_LIBRARIES =
# [cmake] -- OPENSSL_VERSION =
# [cmake] -- OPENSSL_APPLINK_SOURCE =
#if(sf_DEBUG)
    sf_print_target_properties(OpenSSL::SSL)
    sf_print_target_properties(OpenSSL::Crypto)
    message(STATUS "OPENSSL_FOUND = ${OPENSSL_FOUND}")
    message(STATUS "OPENSSL_INCLUDE_DIR = ${OPENSSL_INCLUDE_DIR}")
    message(STATUS "OPENSSL_CRYPTO_LIBRARY = ${OPENSSL_CRYPTO_LIBRARY}")
    message(STATUS "OPENSSL_CRYPTO_LIBRARIES = ${OPENSSL_CRYPTO_LIBRARIES}")
    message(STATUS "OPENSSL_SSL_LIBRARY = ${OPENSSL_SSL_LIBRARY}")
    message(STATUS "OPENSSL_SSL_LIBRARIES = ${OPENSSL_SSL_LIBRARIES}")
    message(STATUS "OPENSSL_LIBRARIES = ${OPENSSL_LIBRARIES}")
    message(STATUS "OPENSSL_VERSION = ${OPENSSL_VERSION}")
    message(STATUS "OPENSSL_APPLINK_SOURCE = ${OPENSSL_APPLINK_SOURCE}")

#endif()
