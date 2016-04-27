#!/bin/bash
set -e

VERSION=$(cat version)
RELEASES=( $(cat releases) )
PACKAGE_VERSION=$(cat package_version)

#have to have a branch of the code up there or the packages wont work from the ppa
pushd ${RELEASES[0]}_build/libprime-server
bzr init
bzr add
bzr commit -m "Packaging for ${VERSION}-${PACKAGE_VERSION}."
bzr push --overwrite lp:~kevinkreiser/+junk/prime-server_${VERSION}-${PACKAGE_VERSION}
popd

#sign and push each package to launchpad
for release in ${RELEASES[@]}; do
	debsign ${release}_build/*source.changes
	dput ppa:kevinkreiser/prime-server ${release}_build/*source.changes
done
