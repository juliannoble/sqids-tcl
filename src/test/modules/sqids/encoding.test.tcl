
#test definitions: https://github.com/sqids/sqids-spec/blob/main/tests/encoding.test.ts

package require tcltest

namespace eval ::testspace {
    namespace import ::tcltest::*
    variable common {
        set result ""
        package require sqids
    }

    test simple {Test basic encode decode with default alphabet}\
        -setup $common -body {
            set s [sqids::idscope new]
            set numbers {1 2 3}
            set id "86Rf07"


            lappend result [string equal [$s encode $numbers] $id]
            lappend result [string equal [$s decode $id] $numbers]

        }\
        -cleanup {
            $s destroy
        }\
        -result [list\
            1 1
        ]
    


    test "different inputs" {Test encode decode roundtrip with different numbers} {*}[
        #MAX_SAFE_INTEGER should be the biggest unsigned integer that the language can safely/mathematically support.
        #tcl supports bignums - so numbers can easily be bigger than for example u128
        #Not clear if there is really a concept of MAX_SAFE_INTEGER in tcl as they can be arbitrarily large.
        #consider perhaps DOS regarding ram and time to process for huge numbers?
        #e.g
        #set bignum [expr {[string repeat "9" 1000]}] ;#1000 digits
        #tested with 10,000 digits       - takes  ~0.5seconds to encode 5ms to decode
        #tested with 20_000 digit number - encoding took approximately 9 seconds on a threadripper.
        #in the context of web urls - 10,000 digits is possibly big enough to start to get in to DOS territory,
        #although presumably nobody is accepting huge inputs from unknown sources.
        #The usecases of huge numbers is unknown.
        #we use a default of 1 googol (10**100) - which is approximately 2**332
        #this takes on the order of a couple of hundreds of microseconds to encode and decode.
        #- but this is somewhat arbitrary and can be overridden by providing a -maxsafeinteger option to the idscope constructor.

        #tcl 8.6 doesn't support underscores in numeric literals, but tcl 9 does.
        #We should test that underscores are supported in tcl 9, but not in tcl 8.6
        #note that returned decoded numbers will be normalized to numbers without underscores even in tcl 9
        #- as the decode function returns a list of numbers, not strings.
        ]\
        -setup $common -body {
            set s [sqids::idscope new]

            set MAX_SAFE_INTEGER [$s config -maxsafeinteger]
            set numbers [list 0 0 0 1 2 3 100 1000 100000 1000000 $MAX_SAFE_INTEGER]

            set id [$s encode $numbers]
            set returned_numbers [$s decode $id]
            foreach original $numbers returned $returned_numbers {
                lappend result [expr {$original == $returned}]
            }

            set result
        }\
        -cleanup {
            $s destroy
        }\
        -result [list\
            1 1 1 1 1 1 1 1 1 1 1
        ]


    test "incremental numbers" {Test encode decode 0-9 default alphabet}\
        -setup $common -body {
            set s [sqids::idscope new]
            set num_dict [dict create {*}{
                bM 0
                Uk 1
                gb 2
                Ef 3
                Vq 4
                uw 5
                OI 6
                AX 7
                p6 8
                nJ 9
            }]
            #single element list of a single number is the same as the number itself in tcl
            #we could wrap in 'list' but it's unnecessary.
            dict for {id numlist} $num_dict {
                 lappend result [string equal [$s encode $numlist] $id]
                 lappend result [string equal [$s decode $id] $numlist]
            }

            set result
        }\
        -cleanup {
            $s destroy
        }\
        -result [list {*}{
            1 1 1 1 1 1 1 1 1 1
            1 1 1 1 1 1 1 1 1 1
        }]


    test "incremental numbers, same index 0" {Test encode decode pairs 0 and 0-9 default alphabet}\
        -setup $common -body {
            set s [sqids::idscope new]
            set num_dict [dict create {*}{
                SvIz {0 0}
                n3qa {0 1}
                tryF {0 2}
                eg6q {0 3}
                rSCF {0 4}
                sR8x {0 5}
                uY2M {0 6}
                74dI {0 7}
                30WX {0 8}
                moxr {0 9}
            }]

            dict for {id numlist} $num_dict {
                 lappend result [string equal [$s encode $numlist] $id]
                 lappend result [string equal [$s decode $id] $numlist]
            }

            set result
        }\
        -cleanup {
            $s destroy
        }\
        -result [list {*}{
            1 1 1 1 1 1 1 1 1 1
            1 1 1 1 1 1 1 1 1 1
        }]

    test "incremental numbers, same index 1" {Test encode decode pairs 0-9 and 0 default alphabet}\
        -setup $common -body {
            set s [sqids::idscope new]
            set num_dict [dict create {*}{
                SvIz {0 0}
                nWqP {1 0}
                tSyw {2 0}
                eX68 {3 0}
                rxCY {4 0}
                sV8a {5 0}
                uf2K {6 0}
                7Cdk {7 0}
                3aWP {8 0}
                m2xn {9 0}
            }]

            dict for {id numlist} $num_dict {
                 lappend result [string equal [$s encode $numlist] $id]
                 lappend result [string equal [$s decode $id] $numlist]
            }

            set result
        }\
        -cleanup {
            $s destroy
        }\
        -result [list {*}{
            1 1 1 1 1 1 1 1 1 1
            1 1 1 1 1 1 1 1 1 1
        }]

    test "multi input" {Test encode decode roundtrip 100 numbers with default alphabet}\
        -setup $common -body {
            set s [sqids::idscope new]

            #in tcl9 we could just use 'lseq 0 100' - but lseq unavailable in 8.6
            set numlist [list {*}{
                0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
                26 27 27 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49
                50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73
                74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97
                98 99
            }]

            lappend result [string equal [$s decode [$s encode $numlist]] $numlist]

        }\
        -cleanup {
            $s destroy
        }\
        -result [list {*}{
            1
        }]

    test "encoding no numbers" {Test encode no numbers with default alphabet}\
        -setup $common -body {
            set s [sqids::idscope new]
            set numlist [list] 
            lappend result [string equal [$s encode $numlist] ""] ;#encode of empty list should be empty string
        }\
        -cleanup {
            $s destroy
        }\
        -result [list {*}{
            1
        }]

    test "decoding empty string" {Test  decode empty string with default alphabet}\
        -setup $common -body {
            set s [sqids::idscope new]
            #decode of empty string should be empty list (equivalent to empty string in tcl)
            lappend result [string equal [$s decode ""] [list]]
        }\
        -cleanup {
            $s destroy
        }\
        -result [list {*}{
            1
        }]

    test "decoding an ID with an invalid character" {Test  decode invalid string with default alphabet}\
        -setup $common -body {
            set s [sqids::idscope new]
            lappend result [string equal [$s decode "*"] [list]]
        }\
        -cleanup {
            $s destroy
        }\
        -result [list {*}{
            1
        }]

    test "encode out-of-range numbers" {Test out-of-range numbers raise error}\
        -setup $common -body {
            set s [sqids::idscope new]
            if {[catch {
                $s encode -1
            } errMsg]} {
                #todo - check error message 
                lappend result "OK expected_error"
            } else {
                lappend result "FAIL: Expected error was not raised"
            }


            set MAX_SAFE_INTEGER [$s config -maxsafeinteger]

            if {[catch {
                $s encode [expr {$MAX_SAFE_INTEGER + 1}]
            } errMsg]} {
                #todo - check error message 
                lappend result "OK expected_error"
            } else {
                lappend result "FAIL: Expected error was not raised"
            }

            set result
        }\
        -cleanup {
            $s destroy
        }\
        -result [list {*}{
            "OK expected_error"
            "OK expected_error"
        }]

    cleanupTests ;#needed to produce test summary.
}