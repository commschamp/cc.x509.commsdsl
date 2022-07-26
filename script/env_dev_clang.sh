#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR=$( dirname ${SCRIPT_DIR} )
BUILD_DIR="${ROOT_DIR}/build.clang"
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

CC=clang CXX=clang++ cmake .. -DCMAKE_INSTALL_PREFIX=install \
    -DCMAKE_BUILD_TYPE=Debug -DCC_X509_USE_SANITIZERS=ON \
    -DCC_X509_BUILD_APPS=ON -DCC_X509_BUILD_DOC=ON "$@"
