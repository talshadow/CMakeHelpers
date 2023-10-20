find_package(Git REQUIRED)
##############################################################################################################
macro(is_required)
    if("REQUIRED" IN_LIST ARGN)
        set(MESSAGE_TYPE "FATAL_ERROR")
    else()
        set(MESSAGE_TYPE "STATUS")
    endif()
endmacro()
##############################################################################################################
function (git_get_year_of_last_commit YEAR )
    execute_process(
        COMMAND ${GIT_EXECUTABLE} log -1 --date=format:%Y --format=%ad
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_LAST_COMMIT_YEAR
        ERROR_VARIABLE  GIT_LAST_COMMIT_YEAR
        RESULT_VARIABLE GIT_ERROR
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(GIT_ERROR EQUAL 0)
        set(${YEAR} ${GIT_LAST_COMMIT_YEAR} PARENT_SCOPE)
    else()
        is_required()
        message(${MESSAGE_TYPE} "git_get_year_of_last_commit:${GIT_LAST_COMMIT_YEAR}" )
        unset(${YEAR} PARENT_SCOPE)
    endif()

endfunction()
##############################################################################################################
function (git_get_last_tag_with GIT_TAG SUFFIX )
    execute_process(
        COMMAND ${GIT_EXECUTABLE} describe --tags --abbrev=0  --match "${SUFFIX}*"
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_LAST_TAG
        ERROR_VARIABLE  GIT_LAST_TAG
        RESULT_VARIABLE GIT_ERROR
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if(GIT_ERROR EQUAL 0)
        set(${GIT_TAG} ${GIT_LAST_TAG} PARENT_SCOPE)
    else()
        is_required()
        message(${MESSAGE_TYPE} "git_get_last_tag_with:${GIT_LAST_TAG}" )
        unset(${GIT_TAG} PARENT_SCOPE)
    endif()

endfunction()
##############################################################################################################
function(git_commit_count_from_tag_to_head COMMIT_COUNT TAG )
    execute_process(
        COMMAND ${GIT_EXECUTABLE} rev-list ${TAG}..HEAD --count
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_COUNT
        ERROR_VARIABLE  GIT_COUNT
        RESULT_VARIABLE GIT_ERROR
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(GIT_ERROR EQUAL 0)
        set(${COMMIT_COUNT} "${GIT_COUNT}" PARENT_SCOPE)
    else()
        is_required()
        message(${MESSAGE_TYPE} "git_commit_count_from_tag_to_head:${GIT_COUNT}" )
        unset(${COMMIT_COUNT} PARENT_SCOPE)
    endif()
endfunction()
##############################################################################################################
function (get_vesion_x4_from_tag V_MAJOR V_MINOR V_PATCH V_TWEAK EXCLUDE_SUFFIX DELIMITER INPUT )
    set(MAJOR 0 )
    set(MINOR 0 )
    set(PATCH 0 )
    set(TWEAK 0 )

    string(FIND "${INPUT}" "${EXCLUDE_SUFFIX}" START_POS)
    if(START_POS EQUAL 0)
        string(REGEX REPLACE "${EXCLUDE_SUFFIX}" "" VERSION_STR ${INPUT})
        string(REPLACE "${DELIMITER}" ";" VERSION_LIST "${VERSION_STR}")


        list(LENGTH VERSION_LIST LENGTH_OF_LIST)
        if(LENGTH_OF_LIST GREATER 1)

            list(GET VERSION_LIST 0 MAJOR)
            list(GET VERSION_LIST 1 MINOR)
            list(GET VERSION_LIST 2 PATCH)

            git_commit_count_from_tag_to_head(COMMIT_COUNT ${INPUT})
            if(NOT COMMIT_COUNT)
               set(COMMIT_COUNT 0 )
            endif()
            if(LENGTH_OF_LIST EQUAL 4)
                list(GET VERSION_LIST 3 TWEAK_GIT)
                math(EXPR TWEAK "${COMMIT_COUNT} + ${TWEAK_GIT}")
            endif()
        endif()
    else()
        message(WARNING "The input string (\"${INPUT}\") not started from \"${EXCLUDE_SUFFIX}\"")
    endif()
    set(${V_MAJOR} ${MAJOR} PARENT_SCOPE)
    set(${V_MINOR} ${MINOR} PARENT_SCOPE)
    set(${V_PATCH} ${PATCH} PARENT_SCOPE)
    set(${V_TWEAK} ${TWEAK} PARENT_SCOPE)
endfunction()
