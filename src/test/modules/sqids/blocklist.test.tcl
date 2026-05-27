#test definitions: https://github.com/sqids/sqids-spec/blob/main/tests/blocklist.test.ts


package require tcltest

namespace eval ::testspace {
    namespace import ::tcltest::*
    variable common {
        set result ""
        package require sqids
    }

    test "default blocklist" {if no custom blocklist param, use the default blocklist}\
        -setup $common -body {
            set s [sqids::idscope new]
            lappend result [string equal [$s decode "aho1e"] 4572721]
            lappend result [string equal [$s encode 4572721] "JExTR"]
        }\
        -cleanup {
            $s destroy
        }\
        -result [list {*}{
            1 1
        }]

    test "empty blocklist" {if an empty blocklist param passed, don't use any blocklist}\
        -setup $common -body {
            set s [sqids::idscope new -blocklist {}]
            lappend result [string equal [$s decode "aho1e"] 4572721]
            lappend result [string equal [$s encode 4572721] "aho1e"]
        }\
        -cleanup {
            $s destroy
        }\
        -result [list {*}{
            1 1
        }]


    test "non-empty blocklist" {if a non-empty blocklist param passed, use only that}\
        -setup $common -body {
            set s [sqids::idscope new -blocklist [list "ArUO"]] ;#originally encoded 100000

            #make sure we don't use the default blocklist.
            lappend result [string equal [$s decode "aho1e"] 4572721]
            lappend result [string equal [$s encode 4572721] "aho1e"]

            #make sure we are using the passed blocklist.
            lappend result [string equal [$s decode "ArUO"] 100000]
            lappend result [string equal [$s encode 100000] "QyG4"]
            lappend result [string equal [$s decode "QyG4"] 100000]

        }\
        -cleanup {
            $s destroy
        }\
        -result [list {*}{
            1 1 1 1 1
        }]

        #    'JSwXFaosAN', // normal result of 1st encoding, let's block that word on purpose
        #    'OCjV9JK64o', // result of 2nd encoding
        #    'rBHf', // result of 3rd encoding is `4rBHfOiqd3`, let's block a substring
        #    '79SM', // result of 4th encoding is `dyhgw479SM`, let's block the postfix
        #    '7tE6' // result of 4th encoding is `7tE6jdAHLe`, let's block the prefix
    test "blocklist" {block 1st and 2nd encoding, substring, postfix prefix}\
        -setup $common -body {
            set blocklist [list {*}[
                #normal result of 1st encoding, let's block that word on purpose.
                ] JSwXFaosAN              {*}[
                #result of 2nd encoding.
                ] OCjV9JK64o              {*}[
                #result of 3rd encoding is '4rBHfOiqd3', let's block a substring.
                ] rBHf                    {*}[
                #result of 4th encoding is 'dyhgw479SM', let's block the postfix.
                ] 79SM                    {*}[
                #result of 5th encoding is '7tE6jdAHLe', let's block the prefix.
                ] 7tE6                    {*}[
                ]
            ]
            set s [sqids::idscope new -blocklist $blocklist]
            lappend result [string equal [$s encode {1000000 2000000}] "1aYeB7bRUt"]
            lappend result [string equal [$s decode "1aYeB7bRUt"] {1000000 2000000}]
        }\
        -cleanup {
            $s destroy
        }\
        -result [list {*}{
            1 1
        }]

    test "blocked word decoding" {decoding blocklist words should still work}\
        -setup $common -body {
            set s [sqids::idscope new -blocklist {86Rf07 se8ojk ARsz1p Q8AI49 5sQRZO}]

            lappend result [string equal [$s decode "86Rf07"] {1 2 3}]
            lappend result [string equal [$s decode "se8ojk"] {1 2 3}]
            lappend result [string equal [$s decode "ARsz1p"] {1 2 3}]
            lappend result [string equal [$s decode "Q8AI49"] {1 2 3}]
            lappend result [string equal [$s decode "5sQRZO"] {1 2 3}]
        }\
        -cleanup {
            $s destroy
        }\
        -result [list {*}{
            1 1 1 1 1
        }]

    test "short word" {match against a short blocklist word}\
        -setup $common -body {
            set s [sqids::idscope new -blocklist {pnd}]

            #this test is strange. It doesn't actually test that the word 'pnd' is blocked.
            #upstream REVIEW? check for discussion first.
            lappend result [string equal [$s decode [$s encode 1000]] 1000]
        }\
        -cleanup {
            $s destroy
        }\
        -result [list {*}{
            1
        }]

    test "constructor" {blocklist filtering in constructor}\
        -setup $common -body {
            #lowercase blocklist in only-uppercase alphabet.
            set s [sqids::idscope new -alphabet {ABCDEFGHIJKLMNOPQRSTUVWXYZ} -blocklist {sxnzkl}]

            set id [$s encode {1 2 3}]
            set numbers [$s decode $id]

             lappend result [string equal $id "IBSHOZ"] ;#without blocklist, would've been "SXNZKL"
             lappend result [string equal $numbers {1 2 3}]
        }\
        -cleanup {
            $s destroy
        }\
        -result [list {*}{
            1 1
        }]

    test "max encoding attempts" {must raise error when reach max attempts to re-generate the ID}\
        -setup $common -body {
            set alphabet {abc}
            set minlength 3
            set blocklist [list "cab" "abc" "bca"]
            set errmatch "*Reached max attempts to re-generate the ID*"
            set s [sqids::idscope new -alphabet $alphabet -minlength $minlength -blocklist $blocklist]

            lappend result [expr {[string length $alphabet] == $minlength}]
            lappend result [expr {[llength $blocklist] == $minlength}]

            if {[catch {
                $s encode 0
            } errMsg]} {
                if {[string match $errmatch $errMsg]} {
                    lappend result "OK expected_error"
                } else {
                    lappend result "FAIL: Error message did not match expected pattern. Got: $errMsg"
                }
            } else {
                lappend result "FAIL: Expected error was not raised."
            }

            set result
        }\
        -cleanup {
            $s destroy
        }\
        -result [list {*}{
            1 1
            "OK expected_error"
        }]

    test "specific blocks" {test specific isBlockedId scenarios}\
        -setup $common -body {
            #id or word less than 3 chars should match exactly.
            #normally 100 -> 86u
            set s [sqids::idscope new -blocklist {hey}]
            #should *not* regenerate id
            lappend result [string equal [$s encode 100] "86u"]
            $s destroy


            #id or word less than 3 chars should match exactly.
            #normally 100 -> 86u
            set s [sqids::idscope new -blocklist {86u}]
            #should regenerate id
            lappend result [string equal [$s encode 100] "sec"]
            $s destroy

            #id or word less than 3 chars should match exactly.
            #normally 1_000_000 -> gMvFo
            set s [sqids::idscope new -blocklist {vFo}]
            #should *not* regenerate id
            #1_000_000
            lappend result [string equal [$s encode 1000000] "gMvFo"]
            $s destroy

            #word with ints should match id at the beginning
            # normally: [100, 202, 303, 404] -> "lP3iIcG1HkYs"
            set s [sqids::idscope new -blocklist {lP3i}]
            #should regenerate id
            lappend result [string equal [$s encode [list 100 202 303 404]] "oDqljxrokxRt"]
            $s destroy


            #word with ints should match id at the end
            #normally: [100, 202, 303, 404] -> "lP3iIcG1HkYs"
            set s [sqids::idscope new -blocklist {1HkYs}]
            #should regenerate id
            lappend result [string equal [$s encode [list 100 202 303 404]] "oDqljxrokxRt"]
            $s destroy

            #word with ints should *not* match id in the middle
            #normally: [101, 202, 303, 404, 505, 606, 707] -> "862REt0hfxXVdsLG8vGWD"
            set s [sqids::idscope new -blocklist {0hfxX}]
            #should *not* regenerate id
            lappend result [string equal [$s encode [list 101 202 303 404 505 606 707]] "862REt0hfxXVdsLG8vGWD"]
            $s destroy

            #word *without* ints should match id in the middle
            #normally: [101, 202, 303, 404, 505, 606, 707] -> "862REt0hfxXVdsLG8vGWD"
            set s [sqids::idscope new -blocklist {hfxX}]
            #should regenerate id
            lappend result [string equal [$s encode [list 101 202 303 404 505 606 707]] "seu8n1jO9C4KQQDxdOxsK"]
            $s destroy

            set result
        }\
        -cleanup {
        }\
        -result [list {*}{
            1 1 1 1 1 1 1
        }]

    cleanupTests ;#needed to produce test summary.
}
