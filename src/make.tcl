#---------------------------------------------------------------------------------------
#project-specific simplified build system - only writes to folders within the project - e.g to .gitignored <projectdir>/modules folder.
#---------------------------------------------------------------------------------------
#this is not intended to be a general-purpose build system, but rather a simple way to build this project without needing to install a more complex build system.
#full make.tcl from punkshell has dependencies on tcllib and many punk libraries.
#This simplified system has no support for zipfs based .tm files, zipkits, starkits etc.
#It is intended to be used with tclsh 8.6 or later, and should work on any platform that supports Tcl.
#cut-down version of make.tcl from punkshell which builds module tests into single zip based .tm files.
#
#---------------------------------------------------------------------------------------
#usage: tclsh make.tcl [project|help|modules]
package prefer latest
lassign [split [info tclversion] .] tclmajorv tclminorv
set scriptfolder [file normalize [file dirname [info script]]]
set sourcefolder $scriptfolder ;#<project>/src
set projectroot [file normalize [file join $scriptfolder ..]]

puts "projectroot: $projectroot"


#-----------------------------------------------------------------------
#maintenance - from punk::mix::util package
#-----------------------------------------------------------------------
proc is_valid_tm_version {versionpart} {
    #Needs to be suitable for use with Tcl's 'package vcompare'
    if {![catch [list package vcompare $versionpart $versionpart]]} {
        return 1
    } else {
        return 0
    }
}
proc magic_tm_version {} {
    set magicbase 999999  ;#deliberately large so given load-preference when testing directly.
    #we split the literal to avoid the literal appearing here - reduce risk of accidentally converting to a release version
    return ${magicbase}.0a1.0
}
#split modulename (as present in a filename or namespaced name) into name/version ignoring leading namespace path
#ignore trailing .tm .TM if present
#if version doesn't pass validation - treat it as part of the modulename and return empty version string without error
#Up to caller to validate.
proc split_modulename_version {fullmodulename} {
    set lastpart [namespace tail $fullmodulename]
    set lastpart [file tail $lastpart] ;# should be ok to use file tail now that we've ensured no namespace components
    if {[string equal -nocase [file extension $fullmodulename] ".tm"]} {
        set fileparts [split [file rootname $lastpart] -]
    } else {
        set fileparts [split $lastpart -]
    }
    if {[is_valid_tm_version [lindex $fileparts end]]} {
        set versionsegment [lindex $fileparts end]
        set namesegment [join [lrange $fileparts 0 end-1] -];#re-stitch
    } else {
        set namesegment [join $fileparts -]
        set versionsegment ""
    }
    set base [namespace qualifiers $fullmodulename]
    if {$base ne ""} {
        set modulename "${base}::$namesegment"
    } else {
        set modulename $namesegment
    }
    return [list $modulename $versionsegment]
}
#-----------------------------------------------------------------------

#Note: extremely cut-down functionality.
#FLAT build of .tm files in src/modules - no support for nested module folders or namespaces.
# A real tcl build system even just for modules should be aware of nested module folders corresponding to library/module namespaces.
# Here we are only dealing with plain text .tm files (not zipkitted .tm files)
# So all we have to do is adjust the version number of the filename and the package provide statement within the file.
#Unlike punkshell's make.tcl - we don't do any change detection - we just build all .tm files every time. This is simpler and fast enough for our purposes.

set current_source_dir [file join $sourcefolder modules] ;#simplified flat.
set src_modules [glob -nocomplain -directory $current_source_dir -type f -tail *.tm]
set target_modules_dir [file join $projectroot modules] ;#simplified flat.
file mkdir $target_modules_dir ;#ensure target folder exists - no harm if it already exists.
foreach fname $src_modules {
    set tmname [file rootname $fname]
    lassign [split_modulename_version $tmname] basename tmfile_versionsegment

    if {$tmfile_versionsegment ne [magic_tm_version]} {
        puts stderr "SKIP: TM version '$tmfile_versionsegment' for module '$tmname' does not match magic version - skipping build of this file"
        continue
    }
    #basic sanity check on basename
    if {$basename eq "" || [regexp {/s} $basename]} {
        puts stderr "SKIP: Invalid TM filename '$fname' - basename is empty or contains whitespace"
        continue
    }

    puts stdout "Building $fname"

    set versionfile $current_source_dir/$basename-buildversion.txt
    set versionfiledata ""
    if {![file exists $versionfile]} {
        puts stderr "\nWARNING: Missing buildversion text file: $versionfile"
        puts stderr "Using version 0.1 - create $versionfile containing the desired version number as the top line to avoid this warning\n"
        set module_build_version "0.1"
    } else {
        set fd [open $versionfile r]
        set versionfiledata [read $fd]; close $fd
        set ln0 [lindex [split $versionfiledata \n] 0]
        set ln0 [string trim $ln0]; set ln0 [string trim $ln0 \r]
        if {![is_valid_tm_version $ln0]} {
            puts stderr "ERROR: build version '$ln0' specified in $versionfile is not suitable. Please ensure a proper version number is at first line of file"
            exit 3
        }
        set module_build_version $ln0
    }

    #readFile not avail on tcl 8.6 - so we do it manually.
    set fd [open $current_source_dir/$fname r]
    set filedata [read $fd]; close $fd
    set filedata [string map [list [magic_tm_version] $module_build_version] $filedata]
    set installed_file [file join $projectroot modules $basename-$module_build_version.tm]
    puts "installing $tmname as $installed_file"

    set fd [open $installed_file w]
    chan configure $fd -translation binary -encoding utf-8
    puts $fd $filedata; close $fd

    puts "Built $installed_file"
    #set magic_version [magic_tm_version]
}
