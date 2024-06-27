#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR=$( dirname ${SCRIPT_DIR} )
BUILD_DIR="${ROOT_DIR}/build.test"
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

cmake .. -DCMAKE_INSTALL_PREFIX=install \
    -DCMAKE_BUILD_TYPE=Debug -DCC_X509_BUILD_APPS=ON  \
    -DCC_X509_USE_CCACHE=ON "$@"
