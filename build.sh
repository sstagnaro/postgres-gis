#!/usr/bin/env bash
set -o errexit
IMAGENAME=postgres-gis
IMAGETAG=latest
EXTRAPKG=( postgis31_13 )
BASEIMG=ubi8-minimal
RELEASEVER=8
EXTREG=quay.io/sstagnaro
IMAGEAUTH="Erik Tiengo <erik.tiengo@neratech.it>"
IMAGESUM="PostreSQL 13 with PostGIS"
IMAGEDESC="This image has been derived from ubi8-minimal and then extended with PostgreSQL 13 and PostGIS"
IMAGECMD="run-postgresql"

# Create a container
container=$(buildah from ${BASEIMG})

# Mount the container filesystem
mountpoint=$(buildah mount $container)

# Install packages
dnf module disable --installroot $mountpoint postgresql \
                   --setopt reposdir=/etc/yum.repos.d/ -y
dnf install --installroot $mountpoint  \
            --releasever ${RELEASEVER} ${EXTRAPKG[@]} \
            --setopt install_weak_deps=false \
            --setopt reposdir=/etc/yum.repos.d/ -y
dnf clean all --installroot $mountpoint

# Extra actions
buildah run $container mkdir -p /var/lib/pgsql/data

# Set image properties
buildah config --cmd "${IMAGECMD}" \
               --user 26 \
               --port 5432 \
               --label maintainer="${IMAGEAUTH}" \
               --label summary="${IMAGESUM}" \
               --label description="${IMAGEDESC}" \
               --label name="${EXTREG}/${IMAGENAME}" \
               --label io.k8s.description="${IMAGEDESC}" \
               --label io.k8s.display-name="${IMAGESUM}" \
               --label io.k8s.display-name="${IMAGESUM}" \
               --label io.openshift.expose-services="5432:postgresql" \
               --label io.openshift.tags="database,postgresql,postgresql13,postgresql-13" \
               --label io.openshift.s2i.assemble-user="26" \
               $container

# Save the container to an image
buildah commit --format oci $container ${EXTREG}/${IMAGENAME}:${IMAGETAG}

# Cleanup
buildah unmount $container
buildah delete $container

# Push the image to the Docker daemon’s storage
#buildah push ${EXTREG}/${IMAGENAME}:${IMAGETAG}
