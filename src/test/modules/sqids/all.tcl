package require tcltest
tcltest::configure -testdir [file dirname [file normalize [info script]]]
#tcltest::configure -debug 1
tcltest::runAllTests