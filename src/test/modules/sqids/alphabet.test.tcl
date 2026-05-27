
#test definitions: https://github.com/sqids/sqids-spec/blob/main/tests/alphabet.test.ts

package require tcltest

namespace eval ::testspace {
    namespace import ::tcltest::*
    variable common {
        set result ""
        package require sqids
    }

    test simple {Test basic alphabet encode decode}\
        -setup $common -body {
            set s [sqids::idscope new -alphabet "0123456789abcdef"]
            set numbers {1 2 3}
            set id "489158"

            lappend result [string equal [$s encode $numbers] $id]
            lappend result [string equal [$s decode $id] $numbers]

        }\
        -cleanup {
            $s destroy
        }\
        -result [list\
            1 1
        ]

    test "short alphabet" {Test short alphabet encode decode roundtrip numbers}\
        -setup $common -body {
            set s [sqids::idscope new -alphabet "abc"]
            set numbers {1 2 3}

            lappend result [string equal [$s decode [$s encode $numbers]] $numbers]
        }\
        -cleanup {
            $s destroy
        }\
        -result [list\
            1
        ]


    test "long alphabet" {Test long alphabet encode decode roundtrip numbers}\
        -setup $common -body {
            set s [sqids::idscope new -alphabet "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_+|\{\}\[\]\;:'\"/?.>,<`~"]
            set numbers {1 2 3}

            lappend result [string equal [$s decode [$s encode $numbers]] $numbers]
        }\
        -cleanup {
            $s destroy
        }\
        -result [list\
            1
        ]

    test "multibyte characters" {Test multibyte entry in alphabet raises error}\
        -setup $common -body {
            set errmatch "*must not contain multibyte*"
            if {[catch {
                set s [sqids::idscope new -alphabet "ë1092"]
            } errMsg]} {
                if {[string match $errmatch $errMsg]} {
                    lappend result "OK expected_error"
                } else {
                    lappend result "FAIL: Unexpected error message: '$errMsg'"
                }
            } else {
                lappend result "FAIL: Expected error was not raised"
            }
        }\
        -cleanup {
            catch {$s destroy}
        }\
        -result [list\
            "OK expected_error"
        ]

    test "repeating alphabet characters" {Test repeated entry in alphabet raises error}\
        -setup $common -body {
            set errmatch "*must contain unique*"
            if {[catch {
                set s [sqids::idscope new -alphabet "aabcdefg"]
            } errMsg]} {
                if {[string match $errmatch $errMsg]} {
                    lappend result "OK expected_error"
                } else {
                    lappend result "FAIL: Unexpected error message: '$errMsg'"
                }
            } else {
                lappend result "FAIL: Expected error was not raised"
            }
        }\
        -cleanup {
            catch {$s destroy}
        }\
        -result [list\
            "OK expected_error"
        ]

    test "too short of an alphabet" {Test too short alphabet raises error}\
        -setup $common -body {
            set errmatch "*length must be at least*"
            if {[catch {
                set s [sqids::idscope new -alphabet "ab"]
            } errMsg]} {
                if {[string match $errmatch $errMsg]} {
                    lappend result "OK expected_error"
                } else {
                    lappend result "FAIL: Unexpected error message: '$errMsg'"
                }
            } else {
                lappend result "FAIL: Expected error was not raised"
            }
        }\
        -cleanup {
            catch {$s destroy}
        }\
        -result [list\
            "OK expected_error"
        ]



    cleanupTests ;#needed to produce test summary.
}