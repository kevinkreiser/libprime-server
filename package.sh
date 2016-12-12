#!/bin/bash
set -e

#get a bunch of stuff we'll need to  make the packages
sudo apt-get install -y git dh-make dh-autoreconf bzr bzr-builddeb pbuilder debootstrap devscripts distro-info ubuntu-dev-tools

#tell bzr who we are
DEBFULLNAME='Kevin Kreiser'
DEBEMAIL='kevinkreiser@gmail.com'
bzr whoami "${DEBFULLNAME} <${DEBEMAIL}>"
source /etc/lsb-release

VERSION=$(head debian/changelog -n1 | sed -e "s/.*(//g" -e "s/-.*//g")

# OPTIONS
if [[ -z ${1} ]]; then
	IFS=',' read -r -a DISTRIBUTIONS <<< "${DISTRIB_CODENAME}"
else
	IFS=',' read -r -a DISTRIBUTIONS <<< "${1}"
fi
if [[ -z ${2} ]]; then
	IFS=',' read -r -a ARCHITECTURES <<< "amd64"
else
	IFS=',' read -r -a ARCHITECTURES <<< "${2}"
fi

#--hookdir although referenced on the internet doesnt work in pbuilder
#neither do exporting environment variables or any other options so
#we have to make a .pbuilderrc and HOOKDIR= to it blech
echo "HOOKDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/hooks" > ${HOME}/.pbuilderrc

#can only make the source tarballs once, or launchpad will barf on differing timestamps
git clone --branch ${VERSION} --recursive  https://github.com/kevinkreiser/prime_server.git libprime-server
cp -rp libprime-server libprime-server${VERSION}
tar -pczf libprime-server_${VERSION}.orig.tar.gz libprime-server
tar -pczf libprime-server${VERSION}_${VERSION}.orig.tar.gz libprime-server${VERSION}

#for every combination of distribution and architecture with and without a pinned version
for DISTRIBUTION in ${DISTRIBUTIONS[@]}; do
for ARCHITECTURE in ${ARCHITECTURES[@]}; do
for with_version in false true; do
	#get prime-server code into the form bzr likes
	target_dir="${DISTRIBUTION}/$(if [[ ${with_version} == true ]]; then echo pinned; else echo unpinned; fi)"
	rm -rf ${target_dir}
	mkdir -p ${target_dir}
	PACKAGE="$(if [[ ${with_version} == true ]]; then echo libprime-server${VERSION}; else echo libprime-server; fi)"
	cp -rp ${PACKAGE} ${target_dir}
        cp -rp ${PACKAGE}_${VERSION}.orig.tar.gz ${target_dir}
	
	#build the dsc and source.change files
	cd ${target_dir}/${PACKAGE}
	cp -rp ../../../debian .
        sed -i -e "s/unstable/${DISTRIBUTION}/g" debian/changelog
	#add the version to the package names
	if [[ ${with_version} == true ]]; then
		for p in $(grep -F Package debian/control | sed -e "s/.*: //g"); do
			for ext in .dirs .install; do
				mv debian/${p}${ext} debian/$(echo ${p} | sed -e "s/prime-server/prime-server${VERSION}/g" -e "s/prime-server${VERSION}\([0-9]\+\)/prime-server${VERSION}-\1/g")${ext}
			done
		done
		sed -i -e "s/\([b| ]\)prime-server/\1prime-server${VERSION}/g" -e "s/prime-server${VERSION}\([0-9]\+\)/prime-server${VERSION}-\1/g" debian/control debian/changelog
	fi

	#create and sign the stuff we need to ship the package to launchpad or try building it with pbuilder
	debuild -S -uc -sa
	cd -

	#only build the one without the version in the name to save time
	if [[ ${with_version} == false && ${NO_BUILD} != true ]]; then
		#make sure we support this release
		if [ ! -e ~/pbuilder/${DISTRIBUTION}-${ARCHITECTURE}_result ]; then
			pbuilder-dist ${DISTRIBUTION} ${ARCHITECTURE} create
		fi

		#try to build a package for it
		cd ${target_dir}
		DEB_BUILD_OPTIONS="parallel=$(nproc)" pbuilder-dist ${DISTRIBUTION} ${ARCHITECTURE} build ${PACKAGE}_${VERSION}-0ubuntu1~${DISTRIBUTION}*.dsc
		cd -
	fi
done
done
done

#cleanup
rm -rf libprime-server*
