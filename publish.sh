#!/bin/bash
set -e

#get all of the packages ready
NO_BUILD=true ./package.sh "${1}"
IFS=',' read -r -a DISTRIBUTIONS <<< "${1}"
VERSION=$(head debian/changelog -n1 | sed -e "s/.*(//g" -e "s/-.*//g")

#have to have a branch of the code up there or the packages wont work from the ppa
cd ${DISTRIBUTIONS[0]}/unpinned
bzr init
bzr add
bzr commit -m "Packaging for ${VERSION}-0ubuntu1."
bzr push --overwrite bzr+ssh://kevinkreiser@bazaar.launchpad.net/~kevinkreiser/+junk/prime-server_${VERSION}-0ubuntu1
cd -

#sign and push each package to launchpad
for dist in ${DISTRIBUTIONS[@]}; do
	for pin in pinned unpinned; do
		debsign ${dist}/${pin}/*source.changes
		dput ppa:kevinkreiser/prime-server ${dist}/${pin}/*source.changes
	done
done
