#!/bin/sh
sbt assembly
rm -rf pkg
mkdir -p pkg
cp target/barbers-assembly-0.0.1.jar pkg/
cp lifter pkg/
cp install pkg/
cp PACKAGES pkg/
cp README pkg/
cd pkg
tar -cvzf barbers.tgz *
cd ..
mv pkg/barbers.tgz ./
