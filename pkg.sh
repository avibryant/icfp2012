#!/bin/sh
sbt assembly
rm -rf pkg
mkdir -p pkg
cp target/barbers-assembly-0.0.1.jar pkg/
cp lifter pkg/
cp install pkg/
cp PACKAGES pkg/
cp README pkg/
cp -r src/main/scala pkg/src
cd pkg
tar -cvzf icfp-96223304.tgz *
cd ..
mv pkg/icfp-96223304.tgz ./
