package require tcltest
set script_dir [file dirname [file normalize [info script]]]
set src_modules_dir [file join [file dirname $script_dir] modules]
tcl::tm::add $src_modules_dir

tcltest::configure -verbose "body pass skip error usec"
tcltest::configure -testdir $script_dir
tcltest::configure -file *.test.tcl
#review - single process has less isolation - but works better in this case.
#(some tclsh shells can hang when running with -singleproc false - needs investigation)
tcltest::configure -singleproc true
tcltest::runAllTests