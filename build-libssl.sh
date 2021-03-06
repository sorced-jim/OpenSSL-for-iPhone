#!/bin/sh

#  Automatic build script for libssl and libcrypto 
#  for iPhoneOS and iPhoneSimulator
#
#  Created by Felix Schulze on 16.12.10.
#  Copyright 2010 Felix Schulze. All rights reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
###########################################################################
#  Change values here
#
VERSION="1.0.1"
MIN_IOS_VERSION=4.3
#
###########################################################################
#
# Don't change anything under this line!
#
###########################################################################



CURRENTPATH=`pwd`
INSTALL_DIR=${INSTALL_DIR:=${CURRENTPATH}/results}
INSTALL_INC_DIR=${INSTALL_DIR}/include
INSTALL_LIB_DIR=${INSTALL_DIR}/lib
mkdir -p ${INSTALL_INC_DIR}
mkdir -p ${INSTALL_LIB_DIR}/pkgconfig
DEVELOPER=`xcode-select -print-path`
SDKVERSION=`xcodebuild -showsdks | grep iphoneos | sed -e 's/.*iphoneos//g' | tail -n 1`

CONFIG_VAR="no-dso no-dsa no-engine no-gost no-ec no-dh no-krb5 no-asm no-hw no-des no-ssl2 no-idea no-rc2 -DOPENSSL_NO_BUF_FREELISTS"

set -e
if [ ! -e openssl-${VERSION}.tar.gz ]; then
	echo "Downloading openssl-${VERSION}.tar.gz"
    curl -O http://www.openssl.org/source/openssl-${VERSION}.tar.gz
else
	echo "Using openssl-${VERSION}.tar.gz"
fi

mkdir -p "${CURRENTPATH}/src"
tar zxf openssl-${VERSION}.tar.gz -C "${CURRENTPATH}/src"
cd "${CURRENTPATH}/src/openssl-${VERSION}"

############
# MacOS X
echo "Building openssl for MacOS X x86-64"
echo "Please stand by..."

mkdir -p "${CURRENTPATH}/bin/MacOSX"
LOG="${CURRENTPATH}/bin/MacOSX/build-openssl-${VERSION}.log"

./Configure darwin64-x86_64-cc ${CONFIG_VAR} --openssldir="${CURRENTPATH}/bin/MacOSX" > "${LOG}" 2>&1

make >> "${LOG}" 2>&1
make install >> "${LOG}" 2>&1
make clean >> "${LOG}" 2>&1
#############

############
# iPhone Simulator
echo "Building openssl for iPhoneSimulator ${SDKVERSION} i386"
echo "Please stand by..."

export CC="${DEVELOPER}/Platforms/iPhoneSimulator.platform/Developer/usr/bin/gcc -arch i386"
mkdir -p "${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}.sdk"

LOG="${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}.sdk/build-openssl-${VERSION}.log"

./Configure BSD-generic32 ${CONFIG_VAR} --openssldir="${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}.sdk" > "${LOG}" 2>&1
# add -isysroot to CC=
sed -ie "s!^CFLAG=!CFLAG=-miphoneos-version-min=${MIN_IOS_VERSION} -isysroot ${DEVELOPER}/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator${SDKVERSION}.sdk !" "Makefile"

make >> "${LOG}" 2>&1
make install >> "${LOG}" 2>&1
make clean >> "${LOG}" 2>&1
#############

#############
# iPhoneOS armv6
echo "Building openssl for iPhoneOS ${SDKVERSION} armv6"
echo "Please stand by..."

export CC="${DEVELOPER}/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc -arch armv6"
mkdir -p "${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv6.sdk"

LOG="${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv6.sdk/build-openssl-${VERSION}.log"

./Configure BSD-generic32 ${CONFIG_VAR} --openssldir="${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv6.sdk" > "${LOG}" 2>&1

sed -ie "s!^CFLAG=!CFLAG=-miphoneos-version-min=${MIN_IOS_VERSION} -isysroot ${DEVELOPER}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${SDKVERSION}.sdk !" "Makefile"
# remove sig_atomic for iPhoneOS
sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"

make >> "${LOG}" 2>&1
make install >> "${LOG}" 2>&1
make clean >> "${LOG}" 2>&1
#############

#############
# iPhoneOS armv7
echo "Building openssl for iPhoneOS ${SDKVERSION} armv7"
echo "Please stand by..."

export CC="${DEVELOPER}/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc -arch armv7"
mkdir -p "${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk"

LOG="${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk/build-openssl-${VERSION}.log"


./Configure BSD-generic32 ${CONFIG_VAR} --openssldir="${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk" >> "${LOG}" 2>&1

sed -ie "s!^CFLAG=!CFLAG=-miphoneos-version-min=${MIN_IOS_VERSION} -isysroot ${DEVELOPER}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${SDKVERSION}.sdk !" "Makefile"
# remove sig_atomic for iPhoneOS
sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"

make >> "${LOG}" 2>&1
make install >> "${LOG}" 2>&1
make clean >> "${LOG}" 2>&1
#############

echo "Build library..."
lipo -create ${CURRENTPATH}/bin/MacOSX/lib/libssl.a ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}.sdk/lib/libssl.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv6.sdk/lib/libssl.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk/lib/libssl.a -output ${INSTALL_LIB_DIR}/libssl.a


lipo -create ${CURRENTPATH}/bin/MacOSX/lib/libcrypto.a ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}.sdk/lib/libcrypto.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv6.sdk/lib/libcrypto.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk/lib/libcrypto.a -output ${INSTALL_LIB_DIR}/libcrypto.a

cp -R ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}.sdk/include/openssl ${INSTALL_INC_DIR}
for pc in ${CURRENTPATH}/bin/MacOSX/lib/pkgconfig/*.pc; do
  sed -e "s,^prefix=.*$,prefix=${INSTALL_DIR},g" $pc >  ${INSTALL_LIB_DIR}/pkgconfig/$(basename $pc)
done
echo "Building done."
echo "Cleaning up..."
rm -rf ${CURRENTPATH}/src
rm -rf ${CURRENTPATH}/bin
echo "Done."
