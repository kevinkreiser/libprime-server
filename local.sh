#!/bin/bash
set -e

#the main place for info on how to do this is here: http://packaging.ubuntu.com/html/index.html
#section 2. launchpad here: http://packaging.ubuntu.com/html/getting-set-up.html
#section 6. packaging here: http://packaging.ubuntu.com/html/packaging-new-software.html

#massive thanks to @sneetsher for finding and fixing all of my mistakes!


VERSION=$(cat version)
RELEASES=$(cat releases)
PACKAGE_VERSION=$(cat package_version)

#get a bunch of stuff we'll need to  make the packages
sudo apt-get install -y dh-make dh-autoreconf bzr-builddeb pbuilder ubuntu-dev-tools debootstrap devscripts
#get the stuff we need to build the software
sudo apt-get install -y autoconf automake pkg-config libtool make gcc g++ lcov libcurl4-openssl-dev libzmq3-dev

#tell bzr who we are
export DEBFULLNAME='Kevin Kreiser'
export DEBEMAIL='kevinkreiser@gmail.com'
bzr whoami "${DEBFULLNAME} <${DEBEMAIL}>"
source /etc/lsb-release

######################################################
#SEE IF WE CAN BUILD THE PACKAGE FOR OUR LOCAL RELEASE
rm -rf local_build
mkdir local_build
pushd local_build
#get prime_server code into the form bzr likes
git clone --branch ${VERSION} --recursive  https://github.com/kevinkreiser/prime_server.git
tar pczf prime_server.tar.gz prime_server

#start building the package, choose l(ibrary) for the type
bzr dh-make libprime-server ${VERSION} prime_server.tar.gz << EOF
l

EOF

#bzr will make you a template to fill out but who wants to do that manually?
rm -rf libprime-server/debian
cp -rp ../debian libprime-server
sed -i -e "s/(.*) [a-z]\+;/(${VERSION}-${PACKAGE_VERSION}~${DISTRIB_CODENAME}1) ${DISTRIB_CODENAME};/g" libprime-server/debian/changelog

#add the stuff to the bzr repository
pushd libprime-server
bzr add debian
bzr commit -m "Packaging for ${VERSION}-${PACKAGE_VERSION}."

#build the packages
bzr builddeb -- -us -uc -j$(grep -c ^processor /proc/cpuinfo)
popd
popd
######################################################
