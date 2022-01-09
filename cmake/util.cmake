################################################################################
# Project:  CMake4GDAL
# Purpose:  CMake build scripts
# Author:   Dmitry Baryshnikov, polimax@mail.ru
################################################################################
# Copyright (C) 2015-2019, NextGIS <info@nextgis.com>
# Copyright (C) 2012-2019 Dmitry Baryshnikov
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
################################################################################


function(check_version major minor rev patch download_url)
    set(url https://rm.nextgis.com)
    set(repo_id 2)
    set(repo lib_oci)

    # https://rm.nextgis.com/api/repo/2/borsch?packet_name=lib_oci&release_tag=latest

    file(DOWNLOAD 
        ${url}/api/repo/${repo_id}/borsch?packet_name=${repo}&release_tag=latest
        ${CMAKE_BINARY_DIR}/${repo}_latest.json
        TLS_VERIFY OFF
    )

    file(READ ${CMAKE_BINARY_DIR}/${repo}_latest.json _JSON_CONTENTS)
    include(JSONParser)

    sbeParseJson(api_request _JSON_CONTENTS)
    foreach(tag_id ${api_request.tags})
        if("${api_request.tags_${tag_id}}" STREQUAL "latest")
            continue()
        endif()

        string(REPLACE "." ";" VERSION_VAR ${api_request.tags_${tag_id}})
        list(GET VERSION_VAR 0 _MAJOR_VERSION)
        list(GET VERSION_VAR 1 _MINOR_VERSION)
        list(GET VERSION_VAR 2 _MICRO_VERSION)
        list(GET VERSION_VAR 3 _PATCH_VERSION)
        break()
    endforeach()

    if(NOT _MAJOR_VERSION)
        message(FATAL_ERROR "Failed parse version")
    endif()

    if(APPLE)
        set(FILE_NAME apple_lib.tar.gz)
    elseif(WIN32)
        set(FILE_NAME win_lib.tar.gz)
    elseif(UNIX)
        set(FILE_NAME unix_lib.tar.gz)
    endif()

    foreach(asset_id ${api_request.files})
        if(${api_request.files_${asset_id}.name} STREQUAL ${FILE_NAME})
            color_message("Found binary package ${api_request.files_${asset_id}.name}")
            set(${download_url} ${url}/api/asset/${api_request.files_${asset_id}.id}/download PARENT_SCOPE)
            break()
        endif()
    endforeach()

    set(${major} ${_MAJOR_VERSION} PARENT_SCOPE)
    set(${minor} ${_MINOR_VERSION} PARENT_SCOPE)
    set(${rev} ${_MICRO_VERSION} PARENT_SCOPE)
    set(${patch} ${_PATCH_VERSION} PARENT_SCOPE)

    # Store version string in file for installer needs
    file(TIMESTAMP ${CMAKE_CURRENT_SOURCE_DIR}/README.md VERSION_DATETIME "%Y-%m-%d %H:%M:%S" UTC)
    set(VERSION ${_MAJOR_VERSION}.${_MINOR_VERSION}.${_MICRO_VERSION}.${_PATCH_VERSION})
    get_cpack_filename(${VERSION} PROJECT_CPACK_FILENAME)
    file(WRITE ${CMAKE_BINARY_DIR}/version.str "${VERSION}\n${VERSION_DATETIME}\n${PROJECT_CPACK_FILENAME}")

endfunction()

function(color_message text)

    string(ASCII 27 Esc)
    set(BoldGreen   "${Esc}[1;32m")
    set(ColourReset "${Esc}[m")

    message(STATUS "${BoldGreen}${text}${ColourReset}")

endfunction()

function(report_version name ver)

    string(ASCII 27 Esc)
    set(BoldYellow  "${Esc}[1;33m")
    set(ColourReset "${Esc}[m")

    message("${BoldYellow}${name} version ${ver}${ColourReset}")

endfunction()

# macro to find packages on the host OS
macro( find_exthost_package )
    if(CMAKE_CROSSCOMPILING)
        set( CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER )
        set( CMAKE_FIND_ROOT_PATH_MODE_LIBRARY NEVER )
        set( CMAKE_FIND_ROOT_PATH_MODE_INCLUDE NEVER )

        find_package( ${ARGN} )

        set( CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY )
        set( CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY )
        set( CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY )
    else()
        find_package( ${ARGN} )
    endif()
endmacro()


# macro to find programs on the host OS
macro( find_exthost_program )
    if(CMAKE_CROSSCOMPILING)
        set( CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER )
        set( CMAKE_FIND_ROOT_PATH_MODE_LIBRARY NEVER )
        set( CMAKE_FIND_ROOT_PATH_MODE_INCLUDE NEVER )

        find_program( ${ARGN} )

        set( CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY )
        set( CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY )
        set( CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY )
    else()
        find_program( ${ARGN} )
    endif()
endmacro()


function(get_prefix prefix IS_STATIC)
  if(IS_STATIC)
    set(STATIC_PREFIX "static-")
      if(ANDROID)
        set(STATIC_PREFIX "${STATIC_PREFIX}android-${ANDROID_ABI}-")
      elseif(IOS)
        set(STATIC_PREFIX "${STATIC_PREFIX}ios-${IOS_ARCH}-")
      endif()
    endif()
  set(${prefix} ${STATIC_PREFIX} PARENT_SCOPE)
endfunction()


function(get_cpack_filename ver name)
    get_compiler_version(COMPILER)
    
    if(NOT DEFINED BUILD_STATIC_LIBS)
      set(BUILD_STATIC_LIBS OFF)
    endif()

    get_prefix(STATIC_PREFIX ${BUILD_STATIC_LIBS})

    set(${name} ${PROJECT_NAME}-${ver}-${STATIC_PREFIX}${COMPILER} PARENT_SCOPE)
endfunction()

function(get_compiler_version ver)
    ## Limit compiler version to 2 or 1 digits
    string(REPLACE "." ";" VERSION_LIST ${CMAKE_C_COMPILER_VERSION})
    list(LENGTH VERSION_LIST VERSION_LIST_LEN)
    if(VERSION_LIST_LEN GREATER 2 OR VERSION_LIST_LEN EQUAL 2)
        list(GET VERSION_LIST 0 COMPILER_VERSION_MAJOR)
        list(GET VERSION_LIST 1 COMPILER_VERSION_MINOR)
        set(COMPILER ${CMAKE_C_COMPILER_ID}-${COMPILER_VERSION_MAJOR}.${COMPILER_VERSION_MINOR})
    else()
        set(COMPILER ${CMAKE_C_COMPILER_ID}-${CMAKE_C_COMPILER_VERSION})
    endif()

    if(WIN32)
        if(CMAKE_CL_64)
            set(COMPILER "${COMPILER}-64bit")
        endif()
    endif()

    # Debug
    # set(COMPILER Clang-10.0)

    set(${ver} ${COMPILER} PARENT_SCOPE)
endfunction()
