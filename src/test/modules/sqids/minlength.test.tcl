
#test definitions: https://github.com/sqids/sqids-spec/blob/main/tests/minlength.test.ts


package require tcltest

namespace eval ::testspace {
    namespace import ::tcltest::*
    variable common {
        set result ""
        package require sqids
    }

    test simple {Test encode decode roundtrip with minlength length of default alphabet}\
        -setup $common -body {
            set s [sqids::idscope new -minlength [string length $::sqids::data::default_alphabet]]
            set numbers {1 2 3}
            set id "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTM"

            lappend result [string equal [$s encode $numbers] $id]
            lappend result [string equal [$s decode $id] $numbers]

        }\
        -cleanup {
            $s destroy
        }\
        -result [list {*}{
            1 1
        }]


    test incremental {Test encode decode roundtrip with minlength various}\
        -setup $common -body {
            set default_alphabet_length [string length $::sqids::data::default_alphabet]
            set numbers {1 2 3}

            set map [dict create {*}{
                    6                                   "86Rf07"
                    7                                   "86Rf07x"
                    8                                   "86Rf07xd"
                    9                                   "86Rf07xd4"
                    10                                  "86Rf07xd4z"
                    11                                  "86Rf07xd4zB"
                    12                                  "86Rf07xd4zBm"
                    13                                  "86Rf07xd4zBmi"
                }   [expr {$default_alphabet_length+0}] "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTM"    {*}{
                }   [expr {$default_alphabet_length+1}] "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTMy"   {*}{
                }   [expr {$default_alphabet_length+2}] "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTMyf"  {*}{
                }   [expr {$default_alphabet_length+3}] "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTMyf1" {*}{
                }
            ]

            dict for {minlength id} $map {
                set s [sqids::idscope new -minlength $minlength]
                 lappend result [string equal [$s encode $numbers] $id]
                 #original test ran the 'encode numbers' twice - so we will too.
                 lappend result [expr {[string length [$s encode $numbers]] == $minlength}]
                 lappend result [string equal [$s decode $id] $numbers]
                 $s destroy
            }

            set result
        }\
        -cleanup {
        }\
        -result [list {*}{
            1 1 1 1 1 1 1 1 1 1 1 1
            1 1 1 1 1 1 1 1 1 1 1 1
            1 1 1 1 1 1 1 1 1 1 1 1
        }]

    test "incremental numbers" {Test encode decode roundtrip with minlength various}\
        -setup $common -body {
            set default_alphabet_length [string length $::sqids::data::default_alphabet]
            set s [sqids::idscope new -minlength $default_alphabet_length]

            set ids [dict create {*}{
                SvIzsqYMyQwI3GWgJAe17URxX8V924Co0DaTZLtFjHriEn5bPhcSkfmvOslpBu {0 0}
                n3qafPOLKdfHpuNw3M61r95svbeJGk7aAEgYn4WlSjXURmF8IDqZBy0CT2VxQc {0 1}
                tryFJbWcFMiYPg8sASm51uIV93GXTnvRzyfLleh06CpodJD42B7OraKtkQNxUZ {0 2}
                eg6ql0A3XmvPoCzMlB6DraNGcWSIy5VR8iYup2Qk4tjZFKe1hbwfgHdUTsnLqE {0 3}
                rSCFlp0rB2inEljaRdxKt7FkIbODSf8wYgTsZM1HL9JzN35cyoqueUvVWCm4hX {0 4}
                sR8xjC8WQkOwo74PnglH1YFdTI0eaf56RGVSitzbjuZ3shNUXBrqLxEJyAmKv2 {0 5}
                uY2MYFqCLpgx5XQcjdtZK286AwWV7IBGEfuS9yTmbJvkzoUPeYRHr4iDs3naN0 {0 6}
                74dID7X28VLQhBlnGmjZrec5wTA1fqpWtK4YkaoEIM9SRNiC3gUJH0OFvsPDdy {0 7}
                30WXpesPhgKiEI5RHTY7xbB1GnytJvXOl2p0AcUjdF6waZDo9Qk8VLzMuWrqCS {0 8}
                moxr3HqLAK0GsTND6jowfZz3SUx7cQ8aC54Pl1RbIvFXmEJuBMYVeW9yrdOtin {0 9}
            }]

            dict for {id numlist} $ids {
                lappend result [string equal [$s encode $numlist] $id]
                lappend result [string equal [$s decode $id] $numlist]
            }

            set result
        }\
        -cleanup {
            $s destroy
        }\
        -result [lrepeat 20 1]

    test "min lengths" {Test encode decode with 5 minlengths and 7 lists (5x7)}\
        -setup $common -body {
            set default_alphabet_length [string length $::sqids::data::default_alphabet]
            set s [sqids::idscope new -minlength $default_alphabet_length]

            #todo - tcl9 vs tcl8 MAX_SAFE_INTEGER.
            set MAX_SAFE_INTEGER [expr {2**32-1}]

            set minlengths [list 0 1 5 10 $default_alphabet_length]
            #we will use integer forms without underscores e.g 1000 vs 1_000
            #Tcl9 will accept both forms, but Tcl8.6 only accepts the non-underscore form.
            #should be irrelevant to the intents of the test.
            set numlists [list {*}{
                {0}
                {0 0 0 0 0}
                {1 2 3 4 5 6 7 8 9 10}
                {100 200 300}
                {1000 2000 3000}
                {1000000}
                } $MAX_SAFE_INTEGER
            ]
            foreach minlength $minlengths {
                foreach numbers $numlists {
                    set s [sqids::idscope new -minlength $minlength]
                    set id [$s encode $numbers]
                    lappend result [expr {[string length $id] >= $minlength}]
                    lappend result [string equal [$s decode $id] $numbers]
                    $s destroy
                }
            }

            #5 x 7 x 2 = 70 results
            set result
        }\
        -cleanup {
        }\
        -result [lrepeat 70 1]
    
    test "out-of-range invalid min length" {Test -minlength only accepts from 1 to 255 inclusive}\
        -setup $common -body {
            set err_match "*must be an integer from 0 to 255 inclusive*"
            if {[catch {
                set s [sqids::idscope new -minlength -1]
            } errMsg]} {
                if {[string match $err_match $errMsg]} {
                    lappend result "OK expected_error"
                } else {
                    lappend result "FAIL: Unexpected error message: '$errMsg'"
                }
            } else {
                lappend result "FAIL: Expected error was not raised."
            }
            catch {$s destroy}

            if {[catch {
                set s [sqids::idscope new -minlength 256]
            } errMsg]} {
                if {[string match $err_match $errMsg]} {
                    lappend result "OK expected_error"
                } else {
                    lappend result "FAIL: Unexpected error message: '$errMsg'"
                }
            } else {
                lappend result "FAIL: Expected error was not raised."
            }
            catch {$s destroy}
            set result
        }\
        -cleanup {
        }\
        -result [list {*}{
            "OK expected_error"
            "OK expected_error"
        }]

    cleanupTests ;#needed to produce test summary.
}
