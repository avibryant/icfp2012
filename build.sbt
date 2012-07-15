import AssemblyKeys._

name := "barbers"

version := "0.0.1"

organization := "icfp2012"

scalaVersion := "2.9.1"

parallelExecution in Test := false

seq(assemblySettings: _*)

// Uncomment if you don't want to run all the tests before building assembly
// test in assembly := {}
