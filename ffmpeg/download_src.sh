#!/bin/bash -ex
#
# This scripts creates build directory with:
# - ffmpeg source tree (git://source.ffmpeg.org/ffmpeg.git)
# - openh264 source tree (https://github.com/cisco/openh264.git)
# - libvpx source tree (https://chromium.googlesource.com/webm/libvpx.git)

update() {
  DIR=$1
  URL=$2
  TAG=$3
  [[ -d $DIR ]] || git clone $URL $DIR
  (
    cd $DIR
    git fetch -t $URL $TAG
    git checkout $TAG
  ) || exit 1
}

mkdir -p ../build
(
cd ../build
# https://github.com/FFmpeg/FFmpeg/releases
update ffmpeg git://source.ffmpeg.org/ffmpeg.git n4.4.4

# Need to fix ffmpeg config to require_pkg_config to work for srt
sed -i 's|libsrt "srt >= 1.3.0" srt/srt.h srt_socket|libsrt "srt >= 1.3.0" srt/srt.h ""|g' \
    ffmpeg/configure

# https://github.com/cisco/openh264/releases
update openh264 https://github.com/cisco/openh264.git v1.8.0
# https://chromium.googlesource.com/webm/libvpx.git
update libvpx https://chromium.googlesource.com/webm/libvpx.git v1.13.0
# https://aomedia.googlesource.com/aom
update aom https://aomedia.googlesource.com/aom v3.6.1

# https://github.com/Haivision/srt
update srt https://github.com/Haivision/srt.git v1.5.3
# Needed by srt OpenSSL_1_1_1g https://github.com/openssl/openssl.git
update openssl https://github.com/openssl/openssl.git OpenSSL_1_1_1g

)

# Pack all source code / build scripts
./archive_src.sh

echo "Downloading sources: DONE"
exit 0
