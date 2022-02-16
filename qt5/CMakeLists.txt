################################################################################
# Project:  oci
# Purpose:  CMake build scripts
# Author:   Dmitry Baryshnikov, dmitry.baryshnikov@nextgis.com
################################################################################
# Copyright (C) 2022, NextGIS <info@nextgis.com>
# Copyright (C) 2022 Dmitry Baryshnikov
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
find_anyproject(Qt5 REQUIRED COMPONENTS Core Sql)

add_definitions(-DQT_PLUGIN -DQT_NO_DEBUG -DQT_SHARED)
include_directories(${CMAKE_CURRENT_SOURCE_DIR} ${Qt5Sql_PRIVATE_INCLUDE_DIRS})

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CSOURCES
    oci/main.cpp
    oci/qsql_oci.cpp
)

set(HHEADERS
    oci/qsql_oci_p.h
)

add_library(qsqloci SHARED ${CSOURCES} ${HHEADERS})
set_target_properties(qsqloci PROPERTIES AUTOMOC TRUE)
target_link_libraries(qsqloci PRIVATE Qt5::Core Qt5::Sql ${LIB_NAME})

set(QSQLOCISPATIAL_SRC
    ocispatial/qsql_ocispatial.cpp
    ocispatial/main.cpp
)

set(QSQLOCISPATIAL_HEADERS
    ocispatial/qsql_ocispatial.h
    ocispatial/main.h
    ocispatial/wkbptr.h
)

add_library(qsqlocispatial SHARED ${QSQLOCISPATIAL_SRC} ${QSQLOCISPATIAL_HEADERS})

set(LINK_LIBS Qt5::Core Qt5::Sql ${LIB_NAME})

if(MSVC)
    set(LINK_LIBS ${LINK_LIBS} wsock32)
endif(MSVC)

set_target_properties(qsqlocispatial PROPERTIES AUTOMOC TRUE)
target_link_libraries(qsqlocispatial PRIVATE ${LINK_LIBS})

if(OSX_FRAMEWORK)
    set(INSTALL_MODULES_DIR Library/Plugins/Qt5/sqldrivers)
else()
    set(INSTALL_MODULES_DIR ${INSTALL_LIB_DIR}/qt5/plugins/sqldrivers)
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
