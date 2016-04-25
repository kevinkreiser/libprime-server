#!/bin/bash

#the main place for info on how to do this is here: http://packaging.ubuntu.com/html/index.html
#section 2. launchpad here: http://packaging.ubuntu.com/html/getting-set-up.html
#section 6. packaging here: http://packaging.ubuntu.com/html/packaging-new-software.html

#massive thanks to @sneetsher for finding and fixing all of my mistakes!

set -e

#get a bunch of stuff we'll need to build the code as well as make the packages
sudo apt-get install -y autoconf automake libtool make gcc g++ lcov dh-make dh-autoreconf bzr-builddeb libcurl4-openssl-dev libzmq3-dev

rm -rf build
mkdir build
pushd build

#get prime_server code into the form bzr likes
git clone --branch 0.3.2 --recursive  https://github.com/kevinkreiser/prime_server.git
tar pczf prime_server.tar.gz prime_server
rm -rf prime_server

#tell bzr who we are
export DEBFULLNAME='Kevin Kreiser'
export DEBEMAIL='kevinkreiser@gmail.com'
bzr whoami "${DEBFULLNAME} <${DEBEMAIL}>"

#start building the package, choose l(ibrary) for the type
bzr dh-make libprime-server 0.3.2 prime_server.tar.gz << EOF
l

EOF

#bzr will make you a template to fill out but who wants to do that manually?
rm -rf libprime-server/debian
cp -rp ../debian libprime-server

#add the stuff to the bzr repository
pushd libprime-server
bzr add debian
bzr commit -m "Initial commit of Debian packaging."

#build the packages
bzr builddeb -- -us -uc

#sign the packages using your fingerprint
#bzr builddeb -S
popd

#make sure it will work in a clean environment
#setup with: pbuilder-dist trusty create
#pbuilder-dist trusty build libprime-server_0.3.2-0ubuntu1.dsc

#have to have a branch of the code up there or you cant use the ppa
#bzr push lp:~kevinkreiser/+junk/prime-server-package

#push the package to the ppa
#dput ppa:kevinkreiser/prime-server

#TOOD: push a branch to launchpad for review

popd
