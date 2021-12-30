#!/bin/bash
IMG_GO="golang:1.17-stretch"
IMG_LAUNCHPAD="spaceone:launchpad"

if [ ! -f ./launchpad ]; then
    docker run -it -w /spaceone --rm -v `pwd`:/spaceone $IMG_GO /bin/bash -c "env GOOS=linux GOARCH=amd64 go build"
fi

if [ ! $(docker images -q $IMG_LAUNCHPAD) ]; then
    docker build . -t $IMG_LAUNCHPAD
fi

docker run -it --rm -v `pwd`:/spaceone $IMG_LAUNCHPAD $*
