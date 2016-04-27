#!/bin/bash
set -e

VERSION=$(cat version)
RELEASES=$(cat releases)
PACKAGE_VERSION=$(cat package_version)

#get a bunch of stuff we'll need to  make the packages
sudo apt-get install -y git dh-make dh-autoreconf bzr-builddeb pbuilder ubuntu-dev-tools debootstrap devscripts

#get prime_server code into the form bzr likes
git clone --branch ${VERSION} --recursive  https://github.com/kevinkreiser/prime_server.git libprime-server
tar pczf libprime-server_${VERSION}.orig.tar.gz libprime-server
rm -rf libprime-server

######################################################
#LETS BUILD THE PACKAGE FOR SEVERAL RELEASES
for release in ${RELEASES}; do
	rm -rf ${release}_build
	mkdir ${release}_build
	pushd ${release}_build

	#copy source targz
	cp -rp ../libprime-server_${VERSION}.orig.tar.gz .
	tar pxf libprime-server_${VERSION}.orig.tar.gz

	#build the dsc and source.change files
	pushd libprime-server
	cp -rp ../../debian .
	sed -i -e "s/(.*) [a-z]\+;/(${VERSION}-${PACKAGE_VERSION}~${release}1) ${release};/g" debian/changelog
	debuild -S -uc -sa
	popd

	#make sure we support this release
	if [ ! -e ~/pbuilder/${release}-base.tgz ]; then
		pbuilder-dist ${release} create	
	fi

	#try to build a package for it
	DEB_BUILD_OPTIONS="parallel=$(nproc)" pbuilder-dist ${release} build libprime-server_${VERSION}-${PACKAGE_VERSION}~${release}1.dsc
	popd
done
######################################################
