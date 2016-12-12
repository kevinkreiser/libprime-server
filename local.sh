#!/bin/bash
set -e

#the main place for info on how to do this is here: http://packaging.ubuntu.com/html/index.html
#section 2. launchpad here: http://packaging.ubuntu.com/html/getting-set-up.html
#section 6. packaging here: http://packaging.ubuntu.com/html/packaging-new-software.html

#massive thanks to @sneetsher for finding and fixing all of my mistakes!

VERSION=$(head debian/changelog -n1 | sed -e "s/.*(//g" -e "s/-.*//g")

#get a bunch of stuff we'll need to  make the packages
sudo apt-get install -y dh-make dh-autoreconf bzr-builddeb pbuilder ubuntu-dev-tools debootstrap devscripts
#get the stuff we need to build the software
sudo apt-get install -y autoconf automake pkg-config libtool make gcc g++ lcov libcurl4-openssl-dev libzmq3-dev

#tell bzr who we are
export DEBFULLNAME='Kevin Kreiser'
export DEBEMAIL='kevinkreiser@gmail.com'
bzr whoami "${DEBFULLNAME} <${DEBEMAIL}>"
source /etc/lsb-release

#versioned package name
PACKAGE="$(if [[ "${1}" == "--versioned-name" ]]; then echo libprime-server${VERSION}; else echo libprime-server; fi)"

######################################################
#SEE IF WE CAN BUILD THE PACKAGE FOR OUR LOCAL RELEASE
rm -rf local_build
mkdir local_build
pushd local_build
#get prime_server code into the form bzr likes
git clone --branch ${VERSION} --recursive  https://github.com/kevinkreiser/prime_server.git ${PACKAGE}
pushd ${PACKAGE}
if [[ "${1}" == "--versioned-name" ]]; then
	echo -e "libprime-server${VERSION} (${VERSION}-0ubuntu1~${DISTRIB_CODENAME}1) ${DISTRIB_CODENAME}; urgency=low\n" > ../../debian/changelog
else
	echo -e "libprime-server (${VERSION}-0ubuntu1~${DISTRIB_CODENAME}1) ${DISTRIB_CODENAME}; urgency=low\n" > ../../debian/changelog
fi
git log --pretty="  * %s" --no-merges $(git tag | grep -FB1 ${VERSION} | head -n 1)..${VERSION} >> ../../debian/changelog
echo -e "\n -- ${DEBFULLNAME} <${DEBEMAIL}>  $(date -u +"%a, %d %b %Y %T %z")" >> ../../debian/changelog
find -name .git | xargs rm -rf
popd
tar pczf ${PACKAGE}.tar.gz ${PACKAGE}
rm -rf ${PACKAGE}

#start building the package, choose l(ibrary) for the type
bzr dh-make ${PACKAGE} ${VERSION} ${PACKAGE}.tar.gz << EOF
l

EOF

#bzr will make you a template to fill out but who wants to do that manually?
rm -rf ${PACKAGE}/debian
cp -rp ../debian ${PACKAGE}
if [[ "${1}" == "--versioned-name" ]]; then
	for p in $(grep -F Package ${PACKAGE}/debian/control | sed -e "s/.*: //g"); do
		for ext in .dirs .install; do
			mv ${PACKAGE}/debian/${p}${ext} ${PACKAGE}/debian/$(echo ${p} | sed -e "s/prime-server/prime-server${VERSION}/g" -e "s/prime-server${VERSION}\([0-9]\+\)/prime-server${VERSION}-\1/g")${ext}
		done
	done
	sed -i -e "s/prime-server/prime-server${VERSION}/g" -e "s/prime-server${VERSION}\([0-9]\+\)/prime-server${VERSION}-\1/g" ${PACKAGE}/debian/control ${PACKAGE}/debian/changelog
fi

#add the stuff to the bzr repository
pushd ${PACKAGE}
bzr add debian
bzr commit -m "Packaging for ${VERSION}-0ubuntu1."

#build the packages
bzr builddeb -- -us -uc -j$(nproc)
popd
popd
######################################################

