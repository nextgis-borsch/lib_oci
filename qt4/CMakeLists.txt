################################################################################
# Project:  oci
# Purpose:  CMake build scripts
# Author:   Dmitry Baryshnikov, dmitry.baryshnikov@nextgis.com
################################################################################
# Copyright (C) 2018, NextGIS <info@nextgis.com>
# Copyright (C) 2018 Dmitry Baryshnikov
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

include(FindAnyProject)
find_anyproject(Qt4 REQUIRED COMPONENTS QtCore QtSql)

add_definitions(-DQT_BUILD_SQL_LIB)
include_directories(${CMAKE_CURRENT_SOURCE_DIR})

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CSOURCES
    oci/main.cpp
    oci/qsql_oci.cpp
)

set(HHEADERS
    oci/qsql_oci.h
    # qsqlcachedresult_p.h
)

qt4_wrap_cpp(MOC_SRCS4 ${HHEADERS})

add_library(qsqloci SHARED ${CSOURCES} ${HHEADERS} ${MOC_SRCS4})

target_link_libraries(qsqloci PRIVATE Qt4::QtCore Qt4::QtSql ${LIB_NAME})

set(QSQLOCISPATIAL_SRC
    ocispatial/qsql_ocispatial.cpp
    ocispatial/main.cpp
)

set(QSQLOCISPATIAL_HEADERS
    ocispatial/qsql_ocispatial.h
    ocispatial/main.h
)
qt4_wrap_cpp(MOC_SPATIAL_SRCS4 ${QSQLOCISPATIAL_HEADERS})

add_library(qsqlocispatial SHARED ${QSQLOCISPATIAL_SRC} ${QSQLOCISPATIAL_HEADERS} ${MOC_SPATIAL_SRCS4})

target_link_libraries(qsqlocispatial PRIVATE Qt4::QtCore Qt4::QtSql ${LIB_NAME})

if(MSVC)
    target_link_libraries(qsqlocispatial wsock32)
endif(MSVC)

if(OSX_FRAMEWORK)
    set(INSTALL_MODULES_DIR Library/Plugins/Qt4/sqldrivers)
else()
    set(INSTALL_MODULES_DIR ${INSTALL_LIB_DIR}/qt4/plugins/sqldrivers)
endif()

if(NOT SKIP_INSTALL_LIBRARIES AND NOT SKIP_INSTALL_ALL)
    install(TARGETS qsqloci qsqlocispatial
        RUNTIME DESTINATION ${INSTALL_MODULES_DIR}
        LIBRARY DESTINATION ${INSTALL_MODULES_DIR}
        ARCHIVE DESTINATION ${INSTALL_MODULES_DIR}
        INCLUDES DESTINATION ${INSTALL_INC_DIR}
        FRAMEWORK DESTINATION ${INSTALL_MODULES_DIR}
    )
endif()
