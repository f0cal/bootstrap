#! /bin/bash

set -ex
HERE=$(dirname "$0")
HASH=$(git rev-parse HEAD)
BRANCH=$(git for-each-ref --format='%(objectname) %(refname:short)' refs/heads | awk "/^${HASH}/{print \$2}")

echo ${BRANCH}
gsutil cp ${HERE}/bootstrap.py gs://bootstrap.f0cal.com/${BRANCH}
