#!/bin/bash

set -e

rm -rf build
mkdir build
pushd build

#get prime_server software
#sudo apt-get install autoconf automake libtool make gcc-4.9 g++-4.9 lcov
sudo apt-get install libcurl4-openssl-dev libzmq3-dev
git clone --branch 0.3.2 --recursive  https://github.com/kevinkreiser/prime_server.git
pushd prime_server
./autogen.sh
popd
tar pczf prime_server.tar.gz prime_server
pushd prime_server
./configure
make -j
sudo make install
popd
rm -rf prime_server

#start building the package
sudo apt-get install dh-make bzr-builddeb
bzr dh-make libprime-server 0.3.2 prime_server.tar.gz
rm -rf libprime-server/debian
cp -rp ../debian libprime-server
pushd libprime-server
bzr add debian/source/format
bzr commit -m "Initial commit of Debian packaging."
bzr builddeb -- -us -uc
#TODO: sign the package
popd

#TODO: push the package to the ppa

#TODO: make an ITP for inclusion in mainline

popd
