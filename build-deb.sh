#!/bin/bash

#Retrieve version from Makefile
VER=`grep "^VERSION =" Makefile`
set $VER
VERSION=$3

PACKAGE="RPi-DHT-perl_$VERSION-1_armhf"

rm -r /tmp/$PACKAGE
mkdir -p /tmp/$PACKAGE/usr/local/lib/arm-linux-gnueabihf/perl/5.28.1/RPi/
mkdir -p /tmp/$PACKAGE/usr/local/lib/arm-linux-gnueabihf/perl/5.28.1/auto/RPi/DHT/
mkdir /tmp/$PACKAGE/DEBIAN
cp lib/RPi/DHT.pm /tmp/$PACKAGE/usr/local/lib/arm-linux-gnueabihf/perl/5.28.1/RPi/
cp blib/arch/auto/RPi/DHT/DHT.so /tmp/$PACKAGE/usr/local/lib/arm-linux-gnueabihf/perl/5.28.1/auto/RPi/DHT/
cp DEBIAN/control /tmp/$PACKAGE/DEBIAN

pushd /tmp
dpkg-deb --build --root-owner-group $PACKAGE
rm -r /tmp/$PACKAGE
popd
mv /tmp/$PACKAGE.deb .

