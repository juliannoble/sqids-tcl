package require tcltest
set script_dir [file dirname [file normalize [info script]]]
set src_modules_dir [file join [file dirname $script_dir] modules]
tcl::tm::add $src_modules_dir

tcltest::configure -verbose "body pass skip error usec"
tcltest::configure -testdir [file dirname [file normalize [info script]]]
tcltest::configure -file *.test.tcl
tcltest::runAllTests