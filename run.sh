#!/bin/sh
exec java -Xms800m -Xmx800m -jar target/barbers-assembly-0.0.1.jar icfp2012.barbers.$@
