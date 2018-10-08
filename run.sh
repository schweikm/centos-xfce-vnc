#!/bin/bash
set -o nounset

readonly PERSIST="/data/docker_persist/centos-xfce-vnc/data"
readonly TARGET="/data"

mkdir -p ${PERSIST}
if [[ ! -d ${PERSIST} ]]; then
    echo "Failed to create persistent data directory"
    exit 1
fi

docker run -it -p 5901:5901 -v ${PERSIST}:${TARGET} docker-xfce-vnc:latest
