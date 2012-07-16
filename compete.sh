#!/bin/sh
ruby src/compete/compete.rb "java -jar target/barbers-assembly-0.0.1.jar icfp2012.barbers.MCTS $1" src/compete/compete_maps/ $2 | ruby src/compete/analyze.rb
