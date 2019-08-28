################################################################################
# Project:  oci
# Purpose:  CMake build scripts
# Author:   Dmitry Baryshnikov, dmitry.baryshnikov@nextgis.com
################################################################################
# Copyright (C) 2018-2019, NextGIS <info@nextgis.com>
# Copyright (C) 2018-2019 Dmitry Baryshnikov
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
cmake_minimum_required (VERSION 2.8.12 FATAL_ERROR)

project(oci)

if(NOT DEFINED PACKAGE_VENDOR)
    set(PACKAGE_VENDOR NextGIS)
endif()

if(NOT DEFINED PACKAGE_BUGREPORT)
    set(PACKAGE_BUGREPORT info@nextgis.com)
endif()


# some init settings
set(CMAKE_COLOR_MAKEFILE ON)
# set path to additional CMake modules
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})

if(OSX_FRAMEWORK AND (BUILD_SHARED_LIBS OR BUILD_STATIC_LIBS))
  message(FATAL_ERROR "Only OSX_FRAMEWORK key or any or both BUILD_SHARED_LIBS
                       and BUILD_STATIC_LIBS keys are permitted")
endif()

include(GNUInstallDirs)

set(INSTALL_BIN_DIR ${CMAKE_INSTALL_BINDIR} CACHE INTERNAL "Installation directory for executables" FORCE)
set(INSTALL_LIB_DIR ${CMAKE_INSTALL_LIBDIR} CACHE INTERNAL "Installation directory for libraries" FORCE)
set(INSTALL_INC_DIR ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME} CACHE INTERNAL "Installation directory for headers" FORCE)
set(INSTALL_CMAKECONF_DIR ${CMAKE_INSTALL_DATADIR}/${PROJECT_NAME}/CMake CACHE INTERNAL "Installation directory for cmake config files" FORCE)

# setup package meta-data
include(util)

check_version(MAJOR_VERSION MINOR_VERSION REV_VERSION PATCH_VERSION DOWNLOAD_URL)
set(VERSION ${MAJOR_VERSION}.${MINOR_VERSION}.${REV_VERSION}.${PATCH_VERSION})
set(SO_VERSION 1)

report_version(${PROJECT_NAME} ${VERSION})

if(OSX_FRAMEWORK)
    set(CMAKE_MACOSX_RPATH ON)
    set(FRAMEWORK_VERSION "${MAJOR_VERSION}")
    set(INSTALL_LIB_DIR "Library/Frameworks" CACHE INTERNAL "Installation directory for libraries" FORCE)
    set(INSTALL_CMAKECONF_DIR CMake CACHE INTERNAL "Installation directory for cmake config files" FORCE)
endif()

set(LOCAL_PATH ${CMAKE_BINARY_DIR}/lib.tar.gz)
if(EXISTS ${LOCAL_PATH})
    message(STATUS "Local sources found: ${CMAKE_BINARY_DIR}/lib.tar.gz, version: ${VERSION}")
else()
    file(DOWNLOAD ${DOWNLOAD_URL} "${CMAKE_CURRENT_BINARY_DIR}/lib.tar.gz")
endif()

execute_process(
    COMMAND ${CMAKE_COMMAND} -E tar xzf "${CMAKE_CURRENT_BINARY_DIR}/lib.tar.gz"
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
)

include(CheckCXXCompilerFlag)
CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)
if(COMPILER_SUPPORTS_CXX11)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
endif()

if(WIN32)
    set(LIB_NAME ${PROJECT_NAME})
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(SUB_DIR x86_64)
    else()
        set(SUB_DIR x86)
    endif()
else()
    set(LIB_NAME clntsh)
    set(SUB_DIR x86_64)
endif()

add_library(${LIB_NAME} SHARED IMPORTED)
set_property(TARGET ${LIB_NAME} PROPERTY
    INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_BINARY_DIR}/include
)

set(LIB_FILENAME)
if(WIN32)
    set(LIB_FILENAME oci.lib)
    set_target_properties(${LIB_NAME} PROPERTIES
        IMPORTED_IMPLIB_RELEASE "${CMAKE_BINARY_DIR}/${SUB_DIR}/${LIB_FILENAME}"
        IMPORTED_LOCATION_RELEASE "${CMAKE_BINARY_DIR}/${SUB_DIR}/oci.dll"
    )
elseif(APPLE)
    set(LIB_FILENAME libclntsh.dylib) # .${MAJOR_VERSION}.${SO_VERSION}
    set_target_properties(${LIB_NAME} PROPERTIES
        IMPORTED_LOCATION_RELEASE "${CMAKE_BINARY_DIR}/${SUB_DIR}/${LIB_FILENAME}"
        IMPORTED_SONAME_RELEASE "@rpath/${LIB_FILENAME}"
    )
else()
    set(LIB_FILENAME libclntsh.so) # .${MAJOR_VERSION}.${SO_VERSION}
    set_target_properties(${LIB_NAME} PROPERTIES IMPORTED_LOCATION_RELEASE ${CMAKE_BINARY_DIR}/${SUB_DIR}/${LIB_FILENAME})
endif()

file(GLOB HHEADERS ${CMAKE_BINARY_DIR}/include/*.h)

set(BIN_FILES)
set(LIB_FILES)
if(WIN32)
    set(LIB_FILES ${CMAKE_BINARY_DIR}/${SUB_DIR}/oci.lib)
    set(BIN_FILES
        ${CMAKE_BINARY_DIR}/${SUB_DIR}/oci.dll
    )
elseif(APPLE)
    file(GLOB LIB_FILES ${CMAKE_BINARY_DIR}/${SUB_DIR}/*.dylib*)
else()
    file(GLOB LIB_FILES ${CMAKE_BINARY_DIR}/${SUB_DIR}/*.so*)
endif()

if(BUILD_QT4)
    add_subdirectory(qt4)
endif()

set(PACKAGE_NAME ${PROJECT_NAME})
set(PACKAGE_STRING "${PACKAGE_NAME} ${VERSION}")
set(PACKAGE_TARNAME ${PROJECT_NANE})

string(TOUPPER ${PACKAGE_NAME} PACKAGE_UPPER_NAME)

if(NOT SKIP_INSTALL_LIBRARIES AND NOT SKIP_INSTALL_ALL)
    install(FILES ${BIN_FILES} DESTINATION ${INSTALL_BIN_DIR})
    install(FILES ${LIB_FILES} DESTINATION ${INSTALL_LIB_DIR})
endif()

# install headers
if(NOT SKIP_INSTALL_HEADERS AND NOT SKIP_INSTALL_ALL )
    install(FILES ${HHEADERS} DESTINATION ${INSTALL_INC_DIR} COMPONENT headers)
endif()

# Export package ===============================================================

# Add all targets to the build-tree export set
configure_file(cmake/PackageTargets.cmake.in
    ${PROJECT_BINARY_DIR}/${PACKAGE_UPPER_NAME}Targets.cmake ESCAPE_QUOTES @ONLY)

if(REGISTER_PACKAGE)
    # Export the package for use from the build-tree
    # (this registers the build-tree with a global CMake-registry)
    export(PACKAGE ${PACKAGE_UPPER_NAME})
endif()

# Create the <Package>Config.cmake file
configure_file(cmake/PackageConfig.cmake.in
    ${PROJECT_BINARY_DIR}/${PACKAGE_UPPER_NAME}Config.cmake ESCAPE_QUOTES @ONLY)

if(NOT SKIP_INSTALL_LIBRARIES AND NOT SKIP_INSTALL_ALL)
    # Install the <Package>Config.cmake
    install(FILES
      ${PROJECT_BINARY_DIR}/${PACKAGE_UPPER_NAME}Config.cmake
      ${PROJECT_BINARY_DIR}/${PACKAGE_UPPER_NAME}Targets.cmake
      DESTINATION ${INSTALL_CMAKECONF_DIR} COMPONENT dev)
endif()

# Archiving ====================================================================

set(CPACK_PACKAGE_NAME "${PACKAGE_NAME}")
set(CPACK_PACKAGE_VENDOR "${PACKAGE_VENDOR}")
set(CPACK_PACKAGE_VERSION "${VERSION}")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${PACKAGE_NAME} Installation")
set(CPACK_PACKAGE_RELOCATABLE TRUE)
set(CPACK_ARCHIVE_COMPONENT_INSTALL ON)
set(CPACK_GENERATOR "ZIP")
set(CPACK_MONOLITHIC_INSTALL ON)
set(CPACK_STRIP_FILES TRUE)

# Get cpack zip archive name
get_cpack_filename(${VERSION} PROJECT_CPACK_FILENAME)
set(CPACK_PACKAGE_FILE_NAME ${PROJECT_CPACK_FILENAME})

include(CPack)
