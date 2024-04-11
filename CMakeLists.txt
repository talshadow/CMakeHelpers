cmake_minimum_required (VERSION 3.27)

project(TEST_MODULES LANGUAGES CXX C)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_LIST_DIR}/cmake_extern_libs)
set(SF_EXTERANL_INSTALL_DIR "${CMAKE_BINARY_DIR}/external")
include(openssl)
