package require Tcl 8.6-

#MIT license
#Julian Noble 2026

#example:
# % package require sqids
# % set s [sqids::sqids new]
#   ::oo::Obj275
# % $s encode {1 2 3}
#   86Rf07
# % $s decode 86Rf07
#   1 2 3


namespace eval sqids {
    oo::class create sqids {
        variable o_alphabet
        variable o_alpha_re
        variable o_minlength
        variable o_blocklist
        constructor {args} {
            set defaults [dict create {*}{
                -alphabet   ""
                -minlength  ""
                -blocklist  ""
            }]
            if {[llength $args] %2 !=0} {
                error "sqids constructor: Require option value pairs. Known options:[dict keys $defaults]."
            }
            set useropts [dict create]
            set explicit_empty_blocklist 0 ;#as opposed to default due to being unspecified.
            dict for {k v} $args {
                set fullmatch [tcl::prefix::match -error "" {-alphabet -minlength -blocklist} $k]
                switch -exact -- $fullmatch {
                    -alphabet - -minlength {
                        dict set useropts $fullmatch $v
                    }
                    -blocklist {
                        if {[llength $v] == 0} {
                            set explicit_empty_blocklist 1
                        }
                        dict set useropts -blocklist $v
                    }
                    default {
                        error "sqids constructor: unknown option '$k'. Known options:[dict keys $defaults]."
                    }
                }
            }
            set opts [dict merge $defaults $useropts]

            set opt_alphabet    [dict get $opts -alphabet]
            if {$opt_alphabet eq ""} {
                set o_alphabet $::sqids::data::default_alphabet
            } else {
                #todo - deny multibyte - regex
                if {[string length $opt_alphabet] < 3} {
                    error "sqids constructor: -alphabet length must be at least 3."
                }
                if {[regexp {(.).*\1} $opt_alphabet]} {
                    error "sqids constructor: -alphabet must contain unique characters."
                }
                set o_alphabet $opt_alphabet
            }
            set alphamatch [string map [list . \\. \[ \\\[ \] \\\] \{ \\\{ \} \\\}] $o_alphabet] ;#review
            set o_alpha_re "^\[$alphamatch\]+\$"

            set o_alphabet [my shuffle $o_alphabet[set o_alphabet {}]]

            set opt_minlength   [dict get $opts -minlength]
            if {$opt_minlength eq ""} {
                set o_minlength $::sqids::data::default_minlength
            } else {
                set maxval 255
                if {![string is integer -strict $opt_minlength] || $opt_minlength < 0 || $opt_minlength > $maxval} {
                    error "sqids constructor: -minlength must be an integer from 0 to $maxval inclusive."
                }
                set o_minlength $opt_minlength
            }
            set opt_blocklist [dict get $opts -blocklist]
            if {!$explicit_empty_blocklist && $opt_blocklist eq ""} {
                set o_blocklist $::sqids::data::default_blocklist
            } else {
                set o_blocklist $opt_blocklist
            }

        }
        method alphabet {} {
            return $o_alphabet
        }
        method minlength {} {
            return $o_minlength
        }
        method blocklist_size {} {
            llength $o_blocklist
        }
        method encode {numlist} {
            if {[llength $numlist] == 0} {return}
            #cannot encode negative numbers, or non-integers.
            foreach num $numlist {
                if {![string is integer -strict $num] || $num < 0} {
                    error "sqids encode: can only encode non-negative integers. Invalid value: '$num'"
                }
            }
            return [my EncodeNumbers $numlist]
        }
        method EncodeNumbers {numlist {increment 0}} {
            if {$increment > [string length $o_alphabet]} {
                error "sqids EncodeNumbers: Reached max attempts to re-generate the ID"
            }
            set offset [llength $numlist]
            set i -1
            foreach v $numlist {
                incr i
                set x [scan [string index $o_alphabet [expr {$v % [string length $o_alphabet]}]] %c]
                set offset [expr {$offset + $x + $i}]
            }
            set offset  [expr {$offset % [string length $o_alphabet]}]
            set offset [expr {($offset + $increment) % [string length $o_alphabet]}]
            set alpha [string range $o_alphabet $offset end][string range $o_alphabet 0 $offset-1]
            set prefix [string index $alpha 0]
            set alpha [string reverse $alpha]
            set id $prefix
            set i -1
            foreach num $numlist {
                incr i
                append id [my ToId $num [string range $alpha 1 end]]
                if {$i < [llength $numlist]-1} {
                    append id [string index $alpha 0] 
                    set alpha [my shuffle $alpha[set alpha {}]]
                }
            }
            if {$o_minlength > [string length $id]} {
                append id [string index $alpha 0]
                while {$o_minlength - [string length $id] > 0} {
                    set alpha [my shuffle $alpha[set alpha {}]]
                    set numchars [expr {min($o_minlength - [string length $id],[string length $alpha])}]; #review alpha vs o_alphabet
                    append id [string range $alpha 0 $numchars-1]
                }
            }
            if {[my is_blocked $id]} {
                set id [my EncodeNumbers $numlist [expr {$increment+1}]] 
            }
            return $id
        }
        method is_blocked {id} {
            if {![llength $o_blocklist]} {
                return 0
            }
            set idtest [string tolower $id]
            set idlen [string length $idtest]
            if {$idlen < 3} {
                #sqids rule: short ids less than 3 chars will not be blocked.
                return 0
            }
            if {$idlen == 3} {
                if {$idtest in $o_blocklist} {
                    return 1
                }
            } else {
                foreach blocked $o_blocklist {
                    set posn [string first $blocked $idtest]
                    if {$posn == -1} {
                        continue
                    }
                    if {$posn == 0} {
                        #whether leetspeak or not, blocklist entries that match at the beginning of the id will be blocked.
                        return 1
                    }
                    if {[regexp {[0-9]} $blocked]} {
                        #sqids rule: blocklist entries with digits (leetspeak) will only be blocked if the match is at the beginning or end of the id.
                        #we've already checked the beginning, so check the end now.
                        set endpos [expr {$idlen - [string length $blocked]}]
                        if {$posn == $endpos} {
                            return 1
                        }
                    } else {
                        #sqids rule: blocklist entries without digits will be blocked if they match anywhere in the id.
                        return 1
                    }
                }
            }
            return 0
        }
        method ToId {num alpha} {
            set id ""
            while 1 {
                set str [string index $alpha [expr {$num % [string length $alpha]}]]
                set id ${str}$id
                set num [expr {$num / [string length $alpha]}]
                if {!($num > 0)} break
            }
            return $id
        }
        method ToNumber {id alpha} {
            set number 0
            for {set i 0} {$i < [string length $id]} {incr i} {
                set posn [string first [string index $id $i] $alpha]
                set number [expr {($number * [string length $alpha]) + $posn}]
            }
            return $number
        }
        #consistent shuffle (always produce the same result for same input)
        method shuffle {alpha} {
            set alpha_len [string length $alpha]
            for {set i 0; set j [expr {$alpha_len-1}]} {$j > 0} {incr i; incr j -1} {
                set iv [scan [string index $alpha $i] %c]
                set jv [scan [string index $alpha $j] %c]
                set r [expr {($i * $j + $iv + $jv) % $alpha_len}]

                set item2 [string index $alpha $r]
                set alpha [string replace $alpha $r $r [string index $alpha $i]]
                set alpha [string replace $alpha $i $i $item2]

                #set alpha_charlist [split $alpha ""]
                ##lswap
                #set item2 [lindex $alpha_charlist $r]
                #lset alpha_charlist $r [lindex $alpha_charlist $i]
                #lset alpha_charlist $i $item2
                #set alpha [join $alpha_charlist ""]
            }
            return $alpha
        }
        method decode {id} {
            if {$id eq ""} {return}
            set result [list]

            if {![regexp $o_alpha_re $id]} {
                puts stderr "sqids decode: ID contains characters not in the alphabet. re: $re id: $id"
                return [list]
            }
            set prefix [string index $id 0]
            set offset [string first $prefix $o_alphabet]
            set alpha [string range $o_alphabet $offset end][string range $o_alphabet 0 $offset-1]
            set alpha [string reverse $alpha]
            set id [string range $id 1 end]
            while {[string length $id] > 0} {
                set separator [string index $alpha 0]
                #split on first occurrence of separator only.
                set sep_posn [string first $separator $id]
                if {$sep_posn == -1} {
                    set parts [list $id]
                } else {
                    set parts [list [string range $id 0 $sep_posn-1] [string range $id $sep_posn+1 end]]
                }
                #assert parts has 1 or 2 elements

                if {[lindex $parts 0] eq ""} {
                    #separator was at start of the id - done.
                    return $result
                }
                lappend result [my ToNumber [lindex $parts 0] [string range $alpha 1 end]]
                if {[llength $parts] == 2} {
                    set alpha [my shuffle $alpha[set alpha {}]]
                    set id [lindex $parts 1]
                } else {
                    set id ""
                }
            }
            return $result
        }
    }
}
namespace eval sqids::lib {

}
namespace eval sqids::data {
    variable default_alphabet {abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789}
    variable default_minlength 0
    variable default_blocklist {
        0rgasm
        1d10t
        1d1ot
        1di0t
        1diot
        1eccacu10
        1eccacu1o
        1eccacul0
        1eccaculo
        1mbec11e
        1mbec1le
        1mbeci1e
        1mbecile
        a11upat0
        a11upato
        a1lupat0
        a1lupato
        aand
        ah01e
        ah0le
        aho1e
        ahole
        al1upat0
        al1upato
        allupat0
        allupato
        ana1
        ana1e
        anal
        anale
        anus
        arrapat0
        arrapato
        arsch
        arse
        ass
        b00b
        b00be
        b01ata
        b0ceta
        b0iata
        b0ob
        b0obe
        b0sta
        b1tch
        b1te
        b1tte
        ba1atkar
        balatkar
        bastard0
        bastardo
        batt0na
        battona
        bitch
        bite
        bitte
        bo0b
        bo0be
        bo1ata
        boceta
        boiata
        boob
        boobe
        bosta
        bran1age
        bran1er
        bran1ette
        bran1eur
        bran1euse
        branlage
        branler
        branlette
        branleur
        branleuse
        c0ck
        c0g110ne
        c0g11one
        c0g1i0ne
        c0g1ione
        c0gl10ne
        c0gl1one
        c0gli0ne
        c0glione
        c0na
        c0nnard
        c0nnasse
        c0nne
        c0u111es
        c0u11les
        c0u1l1es
        c0u1lles
        c0ui11es
        c0ui1les
        c0uil1es
        c0uilles
        c11t
        c11t0
        c11to
        c1it
        c1it0
        c1ito
        cabr0n
        cabra0
        cabrao
        cabron
        caca
        cacca
        cacete
        cagante
        cagar
        cagare
        cagna
        cara1h0
        cara1ho
        caracu10
        caracu1o
        caracul0
        caraculo
        caralh0
        caralho
        cazz0
        cazz1mma
        cazzata
        cazzimma
        cazzo
        ch00t1a
        ch00t1ya
        ch00tia
        ch00tiya
        ch0d
        ch0ot1a
        ch0ot1ya
        ch0otia
        ch0otiya
        ch1asse
        ch1avata
        ch1er
        ch1ng0
        ch1ngadaz0s
        ch1ngadazos
        ch1ngader1ta
        ch1ngaderita
        ch1ngar
        ch1ngo
        ch1ngues
        ch1nk
        chatte
        chiasse
        chiavata
        chier
        ching0
        chingadaz0s
        chingadazos
        chingader1ta
        chingaderita
        chingar
        chingo
        chingues
        chink
        cho0t1a
        cho0t1ya
        cho0tia
        cho0tiya
        chod
        choot1a
        choot1ya
        chootia
        chootiya
        cl1t
        cl1t0
        cl1to
        clit
        clit0
        clito
        cock
        cog110ne
        cog11one
        cog1i0ne
        cog1ione
        cogl10ne
        cogl1one
        cogli0ne
        coglione
        cona
        connard
        connasse
        conne
        cou111es
        cou11les
        cou1l1es
        cou1lles
        coui11es
        coui1les
        couil1es
        couilles
        cracker
        crap
        cu10
        cu1att0ne
        cu1attone
        cu1er0
        cu1ero
        cu1o
        cul0
        culatt0ne
        culattone
        culer0
        culero
        culo
        cum
        cunt
        d11d0
        d11do
        d1ck
        d1ld0
        d1ldo
        damn
        de1ch
        deich
        depp
        di1d0
        di1do
        dick
        dild0
        dildo
        dyke
        encu1e
        encule
        enema
        enf01re
        enf0ire
        enfo1re
        enfoire
        estup1d0
        estup1do
        estupid0
        estupido
        etr0n
        etron
        f0da
        f0der
        f0ttere
        f0tters1
        f0ttersi
        f0tze
        f0utre
        f1ca
        f1cker
        f1ga
        fag
        fica
        ficker
        figa
        foda
        foder
        fottere
        fotters1
        fottersi
        fotze
        foutre
        fr0c10
        fr0c1o
        fr0ci0
        fr0cio
        fr0sc10
        fr0sc1o
        fr0sci0
        fr0scio
        froc10
        froc1o
        froci0
        frocio
        frosc10
        frosc1o
        frosci0
        froscio
        fuck
        g00
        g0o
        g0u1ne
        g0uine
        gandu
        go0
        goo
        gou1ne
        gouine
        gr0gnasse
        grognasse
        haram1
        harami
        haramzade
        hund1n
        hundin
        id10t
        id1ot
        idi0t
        idiot
        imbec11e
        imbec1le
        imbeci1e
        imbecile
        j1zz
        jerk
        jizz
        k1ke
        kam1ne
        kamine
        kike
        leccacu10
        leccacu1o
        leccacul0
        leccaculo
        m1erda
        m1gn0tta
        m1gnotta
        m1nch1a
        m1nchia
        m1st
        mam0n
        mamahuev0
        mamahuevo
        mamon
        masturbat10n
        masturbat1on
        masturbate
        masturbati0n
        masturbation
        merd0s0
        merd0so
        merda
        merde
        merdos0
        merdoso
        mierda
        mign0tta
        mignotta
        minch1a
        minchia
        mist
        musch1
        muschi
        n1gger
        neger
        negr0
        negre
        negro
        nerch1a
        nerchia
        nigger
        orgasm
        p00p
        p011a
        p01la
        p0l1a
        p0lla
        p0mp1n0
        p0mp1no
        p0mpin0
        p0mpino
        p0op
        p0rca
        p0rn
        p0rra
        p0uff1asse
        p0uffiasse
        p1p1
        p1pi
        p1r1a
        p1rla
        p1sc10
        p1sc1o
        p1sci0
        p1scio
        p1sser
        pa11e
        pa1le
        pal1e
        palle
        pane1e1r0
        pane1e1ro
        pane1eir0
        pane1eiro
        panele1r0
        panele1ro
        paneleir0
        paneleiro
        patakha
        pec0r1na
        pec0rina
        pecor1na
        pecorina
        pen1s
        pendej0
        pendejo
        penis
        pip1
        pipi
        pir1a
        pirla
        pisc10
        pisc1o
        pisci0
        piscio
        pisser
        po0p
        po11a
        po1la
        pol1a
        polla
        pomp1n0
        pomp1no
        pompin0
        pompino
        poop
        porca
        porn
        porra
        pouff1asse
        pouffiasse
        pr1ck
        prick
        pussy
        put1za
        puta
        puta1n
        putain
        pute
        putiza
        puttana
        queca
        r0mp1ba11e
        r0mp1ba1le
        r0mp1bal1e
        r0mp1balle
        r0mpiba11e
        r0mpiba1le
        r0mpibal1e
        r0mpiballe
        rand1
        randi
        rape
        recch10ne
        recch1one
        recchi0ne
        recchione
        retard
        romp1ba11e
        romp1ba1le
        romp1bal1e
        romp1balle
        rompiba11e
        rompiba1le
        rompibal1e
        rompiballe
        ruff1an0
        ruff1ano
        ruffian0
        ruffiano
        s1ut
        sa10pe
        sa1aud
        sa1ope
        sacanagem
        sal0pe
        salaud
        salope
        saugnapf
        sb0rr0ne
        sb0rra
        sb0rrone
        sbattere
        sbatters1
        sbattersi
        sborr0ne
        sborra
        sborrone
        sc0pare
        sc0pata
        sch1ampe
        sche1se
        sche1sse
        scheise
        scheisse
        schlampe
        schwachs1nn1g
        schwachs1nnig
        schwachsinn1g
        schwachsinnig
        schwanz
        scopare
        scopata
        sexy
        sh1t
        shit
        slut
        sp0mp1nare
        sp0mpinare
        spomp1nare
        spompinare
        str0nz0
        str0nza
        str0nzo
        stronz0
        stronza
        stronzo
        stup1d
        stupid
        succh1am1
        succh1ami
        succhiam1
        succhiami
        sucker
        t0pa
        tapette
        test1c1e
        test1cle
        testic1e
        testicle
        tette
        topa
        tr01a
        tr0ia
        tr0mbare
        tr1ng1er
        tr1ngler
        tring1er
        tringler
        tro1a
        troia
        trombare
        turd
        twat
        vaffancu10
        vaffancu1o
        vaffancul0
        vaffanculo
        vag1na
        vagina
        verdammt
        verga
        w1chsen
        wank
        wichsen
        x0ch0ta
        x0chota
        xana
        xoch0ta
        xochota
        z0cc01a
        z0cc0la
        z0cco1a
        z0ccola
        z1z1
        z1zi
        ziz1
        zizi
        zocc01a
        zocc0la
        zocco1a
        zoccola
    }
}


package provide sqids [namespace eval sqids {
    variable version
    set version 0.1
}]
