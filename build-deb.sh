#!/bin/bash

#Retrieve version from Makefile
VER=`grep "^VERSION =" Makefile`
set $VER
VERSION=$3
VER=`grep "^SITEARCHEXP =" Makefile`
set $VER
SITEARCHEXP=$3

PACKAGE="RPi-DHT-perl_$VERSION-1_armhf"

rm -r /tmp/$PACKAGE
mkdir -p /tmp/$PACKAGE/$SITEARCHEXP/RPi/
mkdir -p /tmp/$PACKAGE/$SITEARCHEXP/auto/RPi/DHT/
mkdir /tmp/$PACKAGE/DEBIAN
cp lib/RPi/DHT.pm /tmp/$PACKAGE/$SITEARCHEXP/RPi/
cp blib/arch/auto/RPi/DHT/DHT.so /tmp/$PACKAGE/$SITEARCHEXP/auto/RPi/DHT/
cp DEBIAN/control /tmp/$PACKAGE/DEBIAN

pushd /tmp
dpkg-deb --build --root-owner-group $PACKAGE
rm -r /tmp/$PACKAGE
popd
mv /tmp/$PACKAGE.deb .

