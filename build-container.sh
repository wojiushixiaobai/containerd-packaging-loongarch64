#!/bin/bash
#
CONTAINER_VERSION=v

################################################################
# REF: v1.6.24
# GO_VERSION: 1.20
# GO_IMAGE: golang:1.20-buster
#
REF=${CONTAINER_VERSION}
GO_VERSION=$(curl -sSL https://github.com/containerd/containerd/raw/${CONTAINER_VERSION}/contrib/Dockerfile.test | grep "ARG GOLANG_VERSION" | awk -F "=" '{print $2}' | cut -d. -f1,2)
GO_IMAGE=golang:${GO_VERSION}-buster

TMPDIR=$(mktemp -d)

git clone --depth=1 https://github.com/docker/containerd-packaging "${TMPDIR}"
cp container.patch "${TMPDIR}"

pushd "${TMPDIR}" || exit 1

################################################################
# not pull image, use local image
#
sed -i '/--pull/d' Makefile
sed -i "s/@docker pull/# @docker pull/g" Makefile

################################################################
# See. https://hub.docker.com/r/docker/dockerfile/tags
# docker.io/docker/dockerfile not support linux/loong64
#
sed -i '/syntax=docker/d' dockerfiles/deb.dockerfile

################################################################
# See. https://github.com/containerd/containerd
# libcontainer/system/syscall_linux_64.go not support linux/loong64
# vendor/github.com/cilium/ebpf not support linux/loong64
#
git apply container.patch || exit 1

make REF=${REF} GOLANG_IMAGE=${GO_IMAGE} BUILD_IMAGE=debian:buster-slim

popd || exit 1

mkdir -p dist
mv ${TMPDIR}/build/debian/buster/$(uname -m)/* dist/

rm -rf "${TMPDIR:?}"