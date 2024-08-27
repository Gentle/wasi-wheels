#!/bin/bash

set -eou pipefail

BASEDIR=$(realpath $(dirname $0))
UTIL="python3 ${BASEDIR}/util.py"
OUTDIR="${BASEDIR}/build"
BUILDDIR="${OUTDIR}/${NAME}"
URL="https://github.com/${ORG}/${NAME}/archive/refs/tags/v${VERSION}.tar.gz"

mkdir -p "${BUILDDIR}/src"
cd "${BUILDDIR}"

if [ ! -e venv ]; then
  python3.12 -m venv venv
fi

. venv/bin/activate
pip install build wheel setuptools

ARCH_TRIPLET=_wasi_wasm32-wasi

export CC="${WASI_SDK_PATH}/bin/clang"
export CXX="${WASI_SDK_PATH}/bin/clang++"

export PYTHONPATH=$CROSS_PREFIX/lib/python3.12

export CFLAGS="-I${CROSS_PREFIX}/include/python3.12 -D__EMSCRIPTEN__=1 -DNPY_NO_SIGNAL"
export CXXFLAGS="-I${CROSS_PREFIX}/include/python3.12 -D__EMSCRIPTEN__=1 -DNPY_NO_SIGNAL"
export LDSHARED=${CC}
export AR="${WASI_SDK_PATH}/bin/ar"
export RANLIB=true
export LDFLAGS="-shared"
export _PYTHON_SYSCONFIGDATA_NAME=_sysconfigdata_${ARCH_TRIPLET}
export NPY_DISABLE_SVML=1
export NPY_BLAS_ORDER=
export NPY_LAPACK_ORDER=
export NPY_NO_SIGNAL=1
export MACOSX_DEPLOYMENT_TARGET=3.11

prebuild () {
  echo "wrong"
  pip install -r requirements.txt
}

build () {
  python3 -m build -w
  wheel unpack --dest build dist/*.whl 
  ${UTIL} copy_libs build/${NAME}-${VERSION}/${NAME} package/${NAME}
  ${UTIL} generate_files package/ ${NAME} ${NAME} ${VERSION}
  cd package
  ls -l .
  python3 -m build -n -w -o ${OUTDIR}
}

if [ -f "${BASEDIR}/${NAME}/overlay.sh" ]
then
  source "${BASEDIR}/${NAME}/overlay.sh"
fi

cd src
curl -Ls ${URL} | tar xvz --strip-components=1
prebuild
build
