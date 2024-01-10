#!/bin/bash -ex
# This file is well tested on Ubuntu
# List of required packages for build see in docker/Dockerfile
# (preferred way is to use Docker to produce similar environment)
#
# This script may not work in MINGW installation on Windows
#
# Usage ${0} <build_dir>
# build directory should be created via download_src.sh script:
#

. ../build/env.sh

CURRENT_DIR=`pwd`
BUILD_DIR=${1:-.}
CPU_COUNT=$(nproc || echo 4)

## Libvpx

libvpx_DIR=${BUILD_DIR}/libvpx
libvpx_x86_DIR=${BUILD_DIR}/libvpx_x86
libvpx_x64_DIR=${BUILD_DIR}/libvpx_x64
libvpx_configure_OPTIONS="--disable-examples --disable-unit-tests --disable-install-bins --disable-docs --disable-shared --enable-static --enable-vp8 --enable-vp9 --disable-multithread"
if [ ! -d ${libvpx_DIR} ]; then
  echo "Libvpx source tree is not found"
  exit 1
fi
#[ -d ${libvpx_x86_DIR} ] ||
(
cd ${libvpx_DIR}
mkdir -p ${libvpx_x86_DIR}
rsync -a ./ ${libvpx_x86_DIR} --exclude .git
cd ${libvpx_x86_DIR}
CROSS=i686-w64-mingw32- ./configure --target=x86-win32-gcc ${libvpx_configure_OPTIONS} --prefix=${libvpx_x86_DIR}/install
make -j ${CPU_COUNT}
make install
)
#[ -d ${libvpx_x64_DIR} ] ||
(
cd ${libvpx_DIR}
mkdir -p ${libvpx_x64_DIR}
rsync -a ./ ${libvpx_x64_DIR} --exclude .git
cd ${libvpx_x64_DIR}
CROSS=x86_64-w64-mingw32- ./configure --target=x86_64-win64-gcc ${libvpx_configure_OPTIONS} --prefix=${libvpx_x64_DIR}/install
make -j ${CPU_COUNT}
make install
)

## Open264

openh264_DIR=${BUILD_DIR}/openh264
if [ ! -d ${openh264_DIR} ]; then
  echo "OpenH264 source tree is not found"
  exit 1
fi
openh264_x86_DIR=${openh264_DIR}/install_x86
openh264_x86_64_DIR=${openh264_DIR}/install_x86_64
(
 cd ${openh264_DIR}
 if [[ "${BUILD_SKIP_DOWNLOAD_SOURCES}" == "" ]]; then
  make PREFIX=${openh264_x86_DIR} install-headers
 else
  PREFIX=${openh264_x86_DIR}
  mkdir -p ${PREFIX}/include/wels
  install -m 644 ${openh264_DIR}/codec/api/svc/codec*.h ${PREFIX}/include/wels
 fi
 mkdir -p ${openh264_x86_DIR}/lib/pkgconfig
 i686-w64-mingw32-gcc -m32 -O2 -I${CURRENT_DIR}/openh264_wrapper -I${openh264_x86_DIR} \
  -c ${CURRENT_DIR}/openh264_wrapper/wels/openh264_wrapper.c -o ${openh264_x86_DIR}/lib/openh264_wrapper.o
 x86_64-w64-mingw32-ar rcs ${openh264_x86_DIR}/lib/libopenh264_wrapper.a ${openh264_x86_DIR}/lib/openh264_wrapper.o
 cat >${openh264_x86_DIR}/lib/pkgconfig/openh264.pc << EOF
prefix=${openh264_x86_DIR}
includedir=\${prefix}/include

Name: OpenH264
Description: OpenH264 wrapper with dynamic loading
Version: 1.8
Libs: -L\${prefix}/lib -lopenh264_wrapper
Libs.private:
Cflags: -I${CURRENT_DIR}/openh264_wrapper -I\${prefix} -I\${includedir}
EOF
)
(
 cd ${openh264_DIR}
 if [[ "${BUILD_SKIP_DOWNLOAD_SOURCES}" == "" ]]; then
  make PREFIX=${openh264_x86_64_DIR} install-headers
 else
  PREFIX=${openh264_x86_64_DIR}
  mkdir -p ${PREFIX}/include/wels
  install -m 644 ${openh264_DIR}/codec/api/svc/codec*.h ${PREFIX}/include/wels
 fi
 mkdir -p ${openh264_x86_64_DIR}/lib/pkgconfig
 x86_64-w64-mingw32-gcc -m64 -O2 -I${CURRENT_DIR}/openh264_wrapper -I${openh264_x86_64_DIR} \
  -c ${CURRENT_DIR}/openh264_wrapper/wels/openh264_wrapper.c -o ${openh264_x86_64_DIR}/lib/openh264_wrapper.o
 x86_64-w64-mingw32-ar rcs ${openh264_x86_64_DIR}/lib/libopenh264_wrapper.a ${openh264_x86_64_DIR}/lib/openh264_wrapper.o
 cat >${openh264_x86_64_DIR}/lib/pkgconfig/openh264.pc << EOF
prefix=${openh264_x86_64_DIR}
includedir=\${prefix}/include

Name: OpenH264
Description: OpenH264 wrapper with dynamic loading
Version: 1.8
Libs: -L\${prefix}/lib -lopenh264_wrapper
Libs.private:
Cflags: -I${CURRENT_DIR}/openh264_wrapper -I\${prefix} -I\${includedir}
EOF
)

## AOM: https://aomedia.googlesource.com/aom

AOM_DIR=${BUILD_DIR}/aom
if [ ! -d ${AOM_DIR} ]; then
  echo "AOM source tree is not found"
  exit 1
fi
AOM_X86_DIR=${BUILD_DIR}/aom_x86
AOM_X64_DIR=${BUILD_DIR}/aom_x64
AOM_CONFIGURE_OPTIONS="-DENABLE_TESTS=OFF -DENABLE_EXAMPLES=OFF -DENABLE_TOOLS=OFF -DENABLE_DOCS=OFF -DCONFIG_MULTITHREAD=1 -DCONFIG_AV1_ENCODER=1"
(
  mkdir -p "${AOM_X86_DIR}"
  cd "${AOM_X86_DIR}"
  cmake -GNinja -DAOM_TARGET_CPU=generic -DCMAKE_TOOLCHAIN_FILE=${AOM_DIR}/build/cmake/toolchains/x86-mingw-gcc.cmake -DCMAKE_INSTALL_PREFIX=${AOM_X86_DIR}/install ${AOM_CONFIGURE_OPTIONS} ${AOM_DIR}
  cmake --build . --target install
)
(
  mkdir -p "${AOM_X64_DIR}"
  cd "${AOM_X64_DIR}"
  cmake -GNinja -DAOM_TARGET_CPU=generic -DCMAKE_TOOLCHAIN_FILE=${AOM_DIR}/build/cmake/toolchains/x86_64-mingw-gcc.cmake -DCMAKE_INSTALL_PREFIX=${AOM_X64_DIR}/install ${AOM_CONFIGURE_OPTIONS} ${AOM_DIR}
  cmake --build . --target install
)

## OpenSSL: https://github.com/openssl/openssl, used by SRT

OPENSSL_DIR=${BUILD_DIR}/openssl
if [ ! -d ${OPENSSL_DIR} ]; then
  echo "OpenSSL source tree is not found"
  exit 1
fi
OPENSSL_X86_DIR=${BUILD_DIR}/openssl_x86
OPENSSL_X64_DIR=${BUILD_DIR}/openssl_x64
OPENSSL_CONFIGURE_OPTIONS=""
(
  cd ${OPENSSL_DIR}
  mkdir -p "${OPENSSL_X86_DIR}"
  rsync -a ./ ${OPENSSL_X86_DIR} --exclude .git
  cd "${OPENSSL_X86_DIR}"
  ./Configure --cross-compile-prefix=i686-w64-mingw32- mingw
  make
)
(
  cd ${OPENSSL_DIR}
  mkdir -p "${OPENSSL_X64_DIR}"
  rsync -a ./ ${OPENSSL_X64_DIR} --exclude .git
  cd "${OPENSSL_X64_DIR}"
  ./Configure --cross-compile-prefix=x86_64-w64-mingw32- mingw64
  make
)


## SRT: https://github.com/Haivision/srt

SRT_DIR=${BUILD_DIR}/srt
if [ ! -d ${SRT_DIR} ]; then
  echo "SRT source tree is not found"
  exit 1
fi
SRT_X86_DIR=${BUILD_DIR}/srt_x86
SRT_X64_DIR=${BUILD_DIR}/srt_x64
SRT_CONFIGURE_OPTIONS="-DENABLE_C_DEPS=ON -DENABLE_SHARED=OFF -DENABLE_STATIC=ON -DENABLE_ENCRYPTION=ON"
(
  mkdir -p "${SRT_X86_DIR}"
  cd "${SRT_X86_DIR}"
  cmake -DSRT_TARGET_CPU=generic -DCMAKE_TOOLCHAIN_FILE=${AOM_DIR}/build/cmake/toolchains/x86-mingw-gcc.cmake -DUSE_OPENSSL_PC=OFF -DOPENSSL_ROOT_DIR=${OPENSSL_X86_DIR} -DCMAKE_INSTALL_PREFIX=${SRT_X86_DIR}/install ${SRT_CONFIGURE_OPTIONS} ${SRT_DIR}
  cmake --build . --target install
)
(
  mkdir -p "${SRT_X64_DIR}"
  cd "${SRT_X64_DIR}"
  cmake -DSRT_TARGET_CPU=generic -DCMAKE_TOOLCHAIN_FILE=${AOM_DIR}/build/cmake/toolchains/x86_64-mingw-gcc.cmake -DUSE_OPENSSL_PC=OFF -DOPENSSL_ROOT_DIR=${OPENSSL_X64_DIR} -DCMAKE_INSTALL_PREFIX=${SRT_X64_DIR}/install ${SRT_CONFIGURE_OPTIONS} ${SRT_DIR}
  cmake --build . --target install
)

FFMPEG_DIR=${BUILD_DIR}/ffmpeg
if [ ! -d ${FFMPEG_DIR} ]; then
  echo "FFMPEG source tree is not found"
  exit 1
fi

## FFmpeg

FFMPEG_x86_DIR=${BUILD_DIR}/ffmpeg_x86
FFMPEG_x86_64_DIR=${BUILD_DIR}/ffmpeg_x86_64
FFMPEG_CONFIGURE_OPTIONS="--pkg-config=pkg-config --enable-static --enable-avresample --enable-w32threads --enable-libopenh264 --enable-libvpx --disable-filters --disable-bsfs --disable-programs --disable-debug --disable-cuda --disable-cuvid --disable-nvenc --enable-libaom --enable-libsrt"
#[ -d ${FFMPEG_x86_DIR} ] ||
(
 cd ${FFMPEG_DIR}
 mkdir -p ${FFMPEG_x86_DIR}
 rsync -a ./ ${FFMPEG_x86_DIR} --exclude .git
 cd ${FFMPEG_x86_DIR}
 PKG_CONFIG_PATH=${openh264_x86_DIR}/lib/pkgconfig:${libvpx_x86_DIR}/install/lib/pkgconfig:${AOM_X86_DIR}/install/lib/pkgconfig:${SRT_X86_DIR}/install/lib/pkgconfig ./configure --enable-cross-compile --arch=x86 --target-os=mingw32 --cross-prefix=i686-w64-mingw32- ${FFMPEG_CONFIGURE_OPTIONS} --prefix=`pwd`/install
 make -j${CPU_COUNT} install
)
#[ -d ${FFMPEG_x86_64_DIR} ] ||
(
 cd ${FFMPEG_DIR}
 mkdir -p ${FFMPEG_x86_64_DIR}
 rsync -a ./ ${FFMPEG_x86_64_DIR} --exclude .git
 cd ${FFMPEG_x86_64_DIR}
 PKG_CONFIG_PATH=${openh264_x86_64_DIR}/lib/pkgconfig:${libvpx_x64_DIR}/install/lib/pkgconfig:${AOM_X64_DIR}/install/lib/pkgconfig:${SRT_X64_DIR}/install/lib/pkgconfig ./configure --enable-cross-compile --arch=x86_64 --target-os=mingw32 --cross-prefix=x86_64-w64-mingw32- ${FFMPEG_CONFIGURE_OPTIONS} --prefix=`pwd`/install

 make -j${CPU_COUNT} install
)

## OpenCV plugins
./build_videoio_plugin.sh
