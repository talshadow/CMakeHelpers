cmake_minimum_required (VERSION 3.27)

set(SF_GENERATED_PREFIXES "_SOURCE_DIR" "_BINARY_DIR" "_STAMP_DIR" "_INSTALL_DIR" "_PREFIX")

# Get all properties that cmake supports
execute_process(COMMAND cmake --help-property-list OUTPUT_VARIABLE SF_PROPERTY_LIST)

# Convert command output into a CMake list
STRING(REGEX REPLACE ";" "\\\\;" SF_PROPERTY_LIST "${SF_PROPERTY_LIST}")
STRING(REGEX REPLACE "\n" ";" SF_PROPERTY_LIST "${SF_PROPERTY_LIST}")
# Fix https://stackoverflow.com/questions/32197663/how-can-i-remove-the-the-location-property-may-not-be-read-from-target-error-i
#list(FILTER SF_PROPERTY_LIST EXCLUDE REGEX "^LOCATION$|^LOCATION_|_LOCATION$")
list(REMOVE_DUPLICATES SF_PROPERTY_LIST)

# build whitelist by filtering down from SF_PROPERTY_LIST in case cmake is
# a different version, and one of our hardcoded whitelisted properties
# doesn't exist!
unset(SF_WHITELISTED_PROPERTY_LIST)

foreach(prop ${SF_PROPERTY_LIST})
   # if(prop MATCHES "^(INTERFACE|[_a-z]|IMPORTED_LIBNAME_|MAP_IMPORTED_CONFIG_)|^(COMPATIBLE_INTERFACE_(BOOL|NUMBER_MAX|NUMBER_MIN|STRING)|EXPORT_NAME|IMPORTED(_GLOBAL|_CONFIGURATIONS|_LIBNAME)?|NAME|TYPE|NO_SYSTEM_FROM_IMPORTED)$")
        list(APPEND SF_WHITELISTED_PROPERTY_LIST ${prop})
   # endif()
endforeach(prop)

function(sf_print_target_properties tgt)
    if(NOT TARGET ${tgt})
        message("There is no target named '${tgt}'")
        return()
    endif()

    get_target_property(target_type ${tgt} TYPE)
    if(target_type STREQUAL "INTERFACE_LIBRARY")
        set(PROP_LIST ${SF_WHITELISTED_PROPERTY_LIST})
    else()
        set(PROP_LIST ${SF_PROPERTY_LIST})
    endif()

    foreach (prop ${PROP_LIST})
        string(REPLACE "<CONFIG>" "${CMAKE_BUILD_TYPE}" prop ${prop})
        # message ("Checking ${prop}")
        get_property(propval TARGET ${tgt} PROPERTY ${prop} SET)
        if (propval)
            get_target_property(propval ${tgt} ${prop})
            if(NOT "${propval}" STREQUAL "")
                message ("${tgt} ${prop} = ${propval}")
            endif()
        endif()
    endforeach(prop)
endfunction()

function(sf_set_if_undef var value)
    if(NOT DEFINED ${var})
        set(${var} ${value} PARENT_SCOPE)
    endif()
endfunction()

macro(sf_set_if_undef var value)
     if(NOT DEFINED ${var})
        set(${var} ${value} PARENT_SCOPE)
    endif()
endmacro()

function(sf_generate_names NAME)

    if(NOT SF_EXTERANL_INSTALL_DIR)
        set(SF_EXTERANL_INSTALL_DIR "${CMAKE_BINARY_DIR}/external")
    endif()

    set(BASE_DIR_NAME "_deps")
    set(BASE_PATH "${CMAKE_BINARY_DIR}/${BASE_DIR_NAME}")
    set(${NAME}_SOURCE_DIR  ${BASE_PATH}/${NAME}/src  PARENT_SCOPE)
    set(${NAME}_STAMP_DIR   ${BASE_PATH}/${NAME}/stmp PARENT_SCOPE)
    set(${NAME}_BINARY_DIR  ${BASE_PATH}/${NAME}/bin  PARENT_SCOPE)
    set(${NAME}_INSTALL_DIR ${SF_EXTERANL_INSTALL_DIR}/${NAME}  PARENT_SCOPE)
    set(${NAME}_PREFIX      ${BASE_DIR_NAME}/${NAME} PARENT_SCOPE)
endfunction()


function(sf_find_local_package pkgName customRoot pkgFound)
    set(sf_CMAKE_SYSTEM_FRAMEWORK_PATH ${CMAKE_SYSTEM_FRAMEWORK_PATH})
    set(sf_CMAKE_SYSTEM_APPBUNDLE_PATH ${CMAKE_SYSTEM_APPBUNDLE_PATH})
    set(sf_CMAKE_SYSTEM_APPBUNDLE_PATH ${CMAKE_FIND_USE_CMAKE_ENVIRONMENT_PATH})
    set(sf_CMAKE_SYSTEM_APPBUNDLE_PATH ${CMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH})
    set(sf_CMAKE_SYSTEM_APPBUNDLE_PATH ${CMAKE_FIND_USE_CMAKE_SYSTEM_PATH})
    set(sf_CMAKE_SYSTEM_APPBUNDLE_PATH ${CMAKE_FIND_USE_INSTALL_PREFIX})
    set(sf_CMAKE_SYSTEM_APPBUNDLE_PATH ${CMAKE_FIND_USE_CMAKE_PATH})

    set(sf_CMAKE_FIND_ROOT_PATH ${CMAKE_FIND_ROOT_PATH})
    set(sf_CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ${CMAKE_FIND_ROOT_PATH_MODE_INCLUDE})
    set(sf_CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ${CMAKE_FIND_ROOT_PATH_MODE_LIBRARY})

    set(CMAKE_SYSTEM_FRAMEWORK_PATH OFF)
    set(CMAKE_SYSTEM_APPBUNDLE_PATH OFF)
    set(CMAKE_FIND_USE_CMAKE_ENVIRONMENT_PATH OFF)
    set(CMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH OFF)
    set(CMAKE_FIND_USE_CMAKE_SYSTEM_PATH ON)
    set(CMAKE_FIND_USE_INSTALL_PREFIX OFF)
    set(CMAKE_FIND_USE_CMAKE_PATH OFF)

    set(CMAKE_FIND_ROOT_PATH ${${EXTR_PROJECT_NAME}_INSTALL_DIR})
    # 'find_path' will search only under CMAKE_FIND_ROOT_PATH.
    set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
    # 'find_library' will search only under CMAKE_FIND_ROOT_PATH.
    set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
    #CMAKE_FIND_ROOT_PATH

    find_package(${pkgName})
    set(${pkgFound} ${${pkgName}_FOUND} PARENT_SCOPE)

    set(CMAKE_FIND_ROOT_PATH ${sf_CMAKE_FIND_ROOT_PATH})
    set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ${sf_CMAKE_FIND_ROOT_PATH_MODE_INCLUDE})
    set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ${sf_CMAKE_FIND_ROOT_PATH_MODE_LIBRARY})

    set(CMAKE_SYSTEM_FRAMEWORK_PATH ${sf_CMAKE_SYSTEM_FRAMEWORK_PATH})
    set(CMAKE_SYSTEM_APPBUNDLE_PATH ${sf_CMAKE_SYSTEM_APPBUNDLE_PATH})
    set(CMAKE_SYSTEM_APPBUNDLE_PATH ${sf_CMAKE_FIND_USE_CMAKE_ENVIRONMENT_PATH})
    set(CMAKE_SYSTEM_APPBUNDLE_PATH ${sf_CMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH})
    set(CMAKE_SYSTEM_APPBUNDLE_PATH ${sf_CMAKE_FIND_USE_CMAKE_SYSTEM_PATH})
    set(CMAKE_SYSTEM_APPBUNDLE_PATH ${sf_CMAKE_FIND_USE_INSTALL_PREFIX})
    set(CMAKE_SYSTEM_APPBUNDLE_PATH ${sf_CMAKE_FIND_USE_CMAKE_PATH})


endfunction()

