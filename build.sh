#!/bin/bash
set -e

#the main place for info on how to do this is here: http://packaging.ubuntu.com/html/index.html
#section 2. launchpad here: http://packaging.ubuntu.com/html/getting-set-up.html
#section 6. packaging here: http://packaging.ubuntu.com/html/packaging-new-software.html

#massive thanks to @sneetsher for finding and fixing all of my mistakes!


VERSION=$(cat version)
RELEASES=$(cat releases)
PACKAGE_VERSION=0ubuntu1

#get a bunch of stuff we'll need to  make the packages
sudo apt-get install -y dh-make dh-autoreconf bzr-builddeb pbuilder debootstrap devscripts
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
sed -i -e "s/(.*) [a-z]\+;/(${VERSION}-${PACKAGE_VERSION}) ${DISTRIB_CODENAME};/g" libprime-server/debian/changelog

#add the stuff to the bzr repository
pushd libprime-server
bzr add debian
bzr commit -m "Initial commit of Debian packaging."

#build the packages
bzr builddeb -- -us -uc -j$(grep -c ^processor /proc/cpuinfo)

#have to have a branch of the code up there or you cant use the ppa
#bzr push lp:~kevinkreiser/+junk/prime-server-package

#sign the packages using your fingerprint
#bzr builddeb -S
popd

#push the package to the ppa
#dput ppa:kevinkreiser/prime-server libprime-server_${VERSION}-${PACKAGE_VERSION}_source.changes
popd
######################################################


######################################################
#LETS BUILD THE PACKAGE FOR SEVERAL RELEASES
for release in ${RELEASES}; do
	rm -rf ${release}_build
	mkdir ${release}_build
	pushd ${release}_build

	#copy source targz
	cp -rp ../local_build/libprime-server_${VERSION}.orig.tar.gz .

	#copy debian, update changelog and turn into a targz
	cp -rp ../debian .
	sed -i -e "s/(.*) [a-z]\+;/(${VERSION}-${PACKAGE_VERSION}) ${release};/g" debian/changelog
	tar pczf libprime-server_${VERSION}-${PACKAGE_VERSION}.debian.tar.gz debian

	#generate dsc file
	echo "Format: $(cat debian/source/format)" > libprime-server_${VERSION}-${PACKAGE_VERSION}.dsc
	grep -F Source: debian/control >> libprime-server_${VERSION}-${PACKAGE_VERSION}.dsc
	echo "Binary: $(grep -F Package: debian/control | sed -e "s/Package: //g" | tr '\n' ' ' | sed -e "s/ $//g" -e "s/ /, /g")" >> libprime-server_${VERSION}-${PACKAGE_VERSION}.dsc
	grep -m1 -F Architecture: debian/control >> libprime-server_${VERSION}-${PACKAGE_VERSION}.dsc
	echo "Version: ${VERSION}-${PACKAGE_VERSION}" >> libprime-server_${VERSION}-${PACKAGE_VERSION}.dsc
	grep -F Maintainer: debian/control >> libprime-server_${VERSION}-${PACKAGE_VERSION}.dsc
	grep -F Homepage: debian/control >> libprime-server_${VERSION}-${PACKAGE_VERSION}.dsc
	grep -F Standards-Version: debian/control >> libprime-server_${VERSION}-${PACKAGE_VERSION}.dsc
	grep -F Vcs-Git: debian/control >> libprime-server_${VERSION}-${PACKAGE_VERSION}.dsc
	grep -F Build-Depends: debian/control >> libprime-server_${VERSION}-${PACKAGE_VERSION}.dsc
	echo "Package-List: " >> libprime-server_${VERSION}-${PACKAGE_VERSION}.dsc
	for package in $(grep -F Package: debian/control | sed -e "s/Package: //g" | tr '\n' ' '); do
		section=$(tail -n +$(grep -m1 -n -F ${package} debian/control | cut -f1 -d:) debian/control | grep -m1 -F Section: | sed -e "s/Section: //g")
		echo " ${package} deb ${section} $(grep -F Priority: debian/control | sed -e "s/Priority: //g")" >> libprime-server_${VERSION}-${PACKAGE_VERSION}.dsc
	done
	echo "Checksums-Sha1: " >> libprime-server_${VERSION}-${PACKAGE_VERSION}.dsc
	echo " $(sha1sum libprime-server_${VERSION}.orig.tar.gz | sed -e "s/ \+/ $(wc -c < libprime-server_${VERSION}.orig.tar.gz) /g")" >> libprime-server_${VERSION}-${PACKAGE_VERSION}.dsc
	echo " $(sha1sum libprime-server_${VERSION}-${PACKAGE_VERSION}.debian.tar.gz | sed -e "s/ \+/ $(wc -c < libprime-server_${VERSION}-${PACKAGE_VERSION}.debian.tar.gz) /g")" >> libprime-server_${VERSION}-${PACKAGE_VERSION}.dsc
        echo "Checksums-Sha256: " >> libprime-server_${VERSION}-${PACKAGE_VERSION}.dsc
	echo " $(sha256sum libprime-server_${VERSION}.orig.tar.gz | sed -e "s/ \+/ $(wc -c < libprime-server_${VERSION}.orig.tar.gz) /g")" >> libprime-server_${VERSION}-${PACKAGE_VERSION}.dsc
	echo " $(sha256sum libprime-server_${VERSION}-${PACKAGE_VERSION}.debian.tar.gz | sed -e "s/ \+/ $(wc -c < libprime-server_${VERSION}-${PACKAGE_VERSION}.debian.tar.gz) /g")" >> libprime-server_${VERSION}-${PACKAGE_VERSION}.dsc
        echo "Files: " >> libprime-server_${VERSION}-${PACKAGE_VERSION}.dsc
	echo " $(md5sum libprime-server_${VERSION}.orig.tar.gz | sed -e "s/ \+/ $(wc -c < libprime-server_${VERSION}.orig.tar.gz) /g")" >> libprime-server_${VERSION}-${PACKAGE_VERSION}.dsc
	echo " $(md5sum libprime-server_${VERSION}-${PACKAGE_VERSION}.debian.tar.gz | sed -e "s/ \+/ $(wc -c < libprime-server_${VERSION}-${PACKAGE_VERSION}.debian.tar.gz) /g")" >> libprime-server_${VERSION}-${PACKAGE_VERSION}.dsc

	#make sure we support this release
	if [ ! -e ~/pbuilder/${release}-base.tgz ]; then
		pbuilder-dist ${release} create	
	fi

	#try to build a package for it
	pbuilder-dist ${release} build libprime-server_${VERSION}-${PACKAGE_VERSION}.dsc
	popd
done
######################################################
