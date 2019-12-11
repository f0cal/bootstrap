#! /bin/bash

set -ex
HERE=$(dirname "$0")
HASH=$(git rev-parse HEAD)
BRANCH=$(git for-each-ref --format='%(objectname) %(refname:short)' refs/heads | awk "/^${HASH}/{print \$2}")

echo ${BRANCH}
pip install --upgrade gsutil
# gsutil mb gs://bootstrap.f0cal.com/master
# gsutil config
# gsutil mb gs://bootstrap.f0cal.com
# gsutil cp public/scripts/bootstrap.py gs://bootstrap.f0cal.com/
# gsutil iam ch allUsers:objectViewer gs://bootstrap.f0cal.com
# gsutil web set -m bootstrap.py
# gsutil web set -m bootstrap.py gs://bootstrap.f0cal.com
# gsutil rm gs://bootstrap.f0cal.com/bootstrap.py
# gsutil cp public/scripts/bootstrap.py gs://bootstrap.f0cal.com/master
gsutil cp ${HERE}/bootstrap.py gs://bootstrap.f0cal.com/${BRANCH}
