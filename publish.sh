#!/bin/bash

set -e

VERSION=$(cat version)
RELEASES=$(cat releases)
PACKAGE_VERSION=$(cat package_version)

#sign each package
for release in ${RELEASES}; do
	pushd ~/pbuilder/${release}_result
	debsign libprime-server_${VERSION}-${PACKAGE_VERSION}_source.changes
	popd
done

#push each package to launchpad
for release in ${RELEASES}; do
	pushd ~/pbuilder/${release}_result
	dput ppa:kevinkreiser/prime-server libprime-server_${VERSION}-${PACKAGE_VERSION}_source.changes
	popd
done
