#!/bin/bash

#the main place for info on how to do this is here: http://packaging.ubuntu.com/html/index.html
#section 2. launchpad here: http://packaging.ubuntu.com/html/getting-set-up.html
#section 6. packaging here: http://packaging.ubuntu.com/html/packaging-new-software.html

#massive thanks to @sneetsher for finding and fixing all of my mistakes!

set -e

rm -rf build
mkdir build
pushd build

#get prime_server software
#sudo apt-get install autoconf automake libtool make gcc-4.9 g++-4.9 lcov
sudo apt-get install libcurl4-openssl-dev libzmq3-dev
git clone --branch 0.3.2 --recursive  https://github.com/kevinkreiser/prime_server.git
tar pczf prime_server.tar.gz prime_server
rm -rf prime_server

#start building the package
sudo apt-get install dh-make dh-autoreconf bzr-builddeb
bzr dh-make libprime-server 0.3.2 prime_server.tar.gz
rm -rf libprime-server/debian
cp -rp ../debian libprime-server
pushd libprime-server
bzr add debian
bzr commit -m "Initial commit of Debian packaging."
bzr builddeb -- -us -uc
#bzr builddeb -S
popd

#make sure it will work in a clean environment
#pbuilder-dist trusty build libprime-server_0.3.2-0ubuntu1.dsc

#push the package to the ppa
#dput ppa:kevinkreiser/prime-server

#TOOD: push a branch to launchpad for review

popd
