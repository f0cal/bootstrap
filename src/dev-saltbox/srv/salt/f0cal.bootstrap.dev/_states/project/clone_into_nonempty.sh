set -ex
cd ${2}
git init
git remote add origin ${1}
git fetch
git branch master origin/master
git checkout master
