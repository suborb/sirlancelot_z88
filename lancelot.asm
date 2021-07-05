;Sir Lancelot Mk2
;It all went horribly wrong last time..maybe this time we can do
;better?
;Added in oz routines...hopefully lot better than last time!!!
;It works..yeah!
;Will modify ckobjects to make the things flash!
;udg bit not working..
;Including error handler to redraw things...
;Put front end in..
;Need to add - lives counter, flashing objects!
;Flash objects seems to work..lives counter based on udgs..grrr!
;Changed $5b to varbase!
;Lance right at 6a91+offs
;Have done objects, lives counter, flashing out..just need to add cheat
;and sort out some of the relocating problems - especially screen copier!
;Have implemented a step lives counter by poking direct to sbr file

;9/8/98
;Changed lancelot sprites to use 6 udgs each..and set up table so can
;edit the order..[have to rewrite step because removed it]

;10/8/98
;Changed filename, made new ROMable screen copy routine
;Changed all references (of screen) to defc, removed attr setting from
;Death sequence..will it all still work>

;11/8/98
;Getting there with redefinitions and making ROMable - setting up
;data structure for variables..
;
;13/8/98
;Changed error handler, and added front end init code...

                MODULE  lancelot


                INCLUDE "interrpt.def"
                INCLUDE "stdio.def"
                INCLUDE "map.def"
                INCLUDE "memory.def"
                INCLUDE "screen.def"
                INCLUDE "error.def"
                INCLUDE "time.def"
                INCLUDE "syspar.def"
                INCLUDE "director.def"
                INCLUDE "fileio.def"

;print
                XDEF    sbrbank
                XDEF    sbraddr
                XREF    plotabs
;for keys

                XDEF    pkeys
                XREF    keys
                XREF    mapkey
                XREF    ktest1
                XREF    kfind
;for screen copier

                XDEF    varbase
                XDEF    myflags
                XREF    ozscrcpy
                XREF    ozscrcpy_noc
                XDEF    cksound
                XDEF    ozaddr
                XDEF    ozbank
                XDEF    screen

;for topics etc...
                XREF    ozread  ;handles topics etc..

                XDEF    redefine





;                defc    varbase= $5b00
;                defc    myvarstore = 24576

IF BASIC
                defc    screen = 16384
ENDIF
IF !BASIC      
                defc    screen = 8192
                defc    reqpag = 21
                defc    in_bank = 63
ENDIF


                defc    attrmap = screen+4096
                defc    attrdiff = (attrmap/256)-88
                defc    varbase = screen+4096+768
                defc    myvarstore = varbase+270

                defc    level = varbase+$B6
                defc    lives = varbase+$B7



IF BASIC
                org     32768
ENDIF
IF  !BASIC
                org     53000
ENDIF



;        defc    stored_dat = 26500
;        defc    title_store = 25000 
;        defc    data_start = 26636
         defc   stored_dat = 59200
        defc    title_store = 58180

;This is to calculate the offset..not much special really!
        defc    orig_start = 26500

        defc    offs = (stored_dat) - (orig_start)

if BASIC
.start
        ld      hl,0
        add     hl,sp
        ld      (exitstk+1),hl
        ld      sp,($1FFE)
        call oz_init
        ld   a,SC_DIs
        call_oz(Os_Esc)
        xor     a
        ld      b,a
        ld      hl,errhan
        call_oz(os_erh)
        ld      (obou),a
        ld      (oerr),hl
        call gamein
.out
        ld   sp,($1FFE)
        ld      hl,(oerr)
        ld      a,(obou)
        ld      b,0
        call_oz(os_erh)
        ld   a,sc_ena
        call_oz(Os_Esc)
        ld   a,'5'
        ld   bc,mp_del
        call_oz(os_map)          ;remove our map
        ld   hl,baswindres       ;clear BASIC window
        call_oz(gn_sop)
.exitstk
        ld      sp,0
        ret
ENDIF

IF !BASIC
; Application DOR

.in_dor defb    0,0,0   ; links to parent, brother, son
        defw    0       ;brother_add
        defb    0       ;brother_bank
        defb    0,0,0
        defb    $83     ; DOR type - application
        defb    indorend-indorstart
.indorstart     
        defb    '@'     ; key to info section
        defb    ininfend-ininfstart
.ininfstart     
        defw    0
        defb    'L'     ; application key
        defb    reqpag      ; 5K contigious RAM
        defw    0       ; overhead
        defw    0       ; unsafe workspace
        defw    0       ; safe workspace
        defw    entry   ; entry point
        defb    0       ; bank bindings
        defb    0
        defb    0
        defb    in_bank
        defb    at_bad  ; application type
        defb    0       ; no caps lock
.ininfend       defb    'H'     ; key to help section
        defb    inhlpend-inhlpstart
.inhlpstart     defw    in_topics
        defb    in_bank
        defw    in_commands
        defb    in_bank
        defw    in_help
        defb    in_bank
        defb    0,0,0   ; no tokens
.inhlpend       defb    'N'     ; key to name section
        defb    innamend-innamstart
.innamstart     defm    "Sir Lancelot"	
		defb	0
.innamend       defb    $ff
.indorend

; Topic entries

.in_topics      defb    0

.inopt_topic    defb    inopt_topend-inopt_topic
        defm    "OPTIONS\x00"
        defb    0
        defb    0
        defb    1
        defb    inopt_topend-inopt_topic
.inopt_topend

.incom_topic    defb    incom_topend-incom_topic
        defm    "COMMANDS\x00"
        defb    0
        defb    0
        defb    0
        defb    incom_topend-incom_topic
.incom_topend
        defb    0

; Command entries

.in_commands    defb    0

.in_opts1       defb    in_opts2-in_opts1
        defb    $81
        defm    "OD\x00"
        defm    "Display\x00"
        defw    0
        defb    0
        defb    in_opts2-in_opts1

.in_opts2       defb    in_opts3-in_opts2
        defb    $85
        defm    "OI\x00"
        defm    "Invert\x00"
        defw    0
        defb    0
        defb    in_opts3-in_opts2

.in_opts3
;        defb    in_opts_end-in_opts3
;        defb    $82
;        defm    "OV"&0
;        defm    "Version"&0
;        defw    0
;        defb    0
;        defb    in_opts_end-in_opts3

.in_opts_end    defb    1

;.in_coms0       defb    in_coms1-in_coms0
;        defb    $84
;        defm    "L"&0
;        defm    "Load levels"&0
;        defw    0
;        defb    0
;        defb    in_coms1-in_coms0

.in_coms1       defb    in_coms2-in_coms1
        defb    $83
        defm    "R\x00"
        defm    "Redefine keys\x00"
        defw    0
        defb    0
        defb    in_coms2-in_coms1

.in_coms2       defb    in_coms_end-in_coms2
        defb    $80
        defm    "Q\x00"
        defm    "Quit\x00"
        defw    0
        defb    0
        defb    in_coms_end-in_coms2

.in_coms_end    defb    0


; Help entries

.in_help        defb    $7f
        defm    "A conversion of the ZX Spectrum Game\x7f"
        defm    "Originally published by Melbourne House 1984\x7f"
        defm    "Converted by Dominic Morris\x7f"
        defm    "github.com/suborb      \x7f"
        defm    "v1.01 -  5th July   2021\x7f"
        defb    0




.entry
        jp      init
        scf
        ret

;Entry point..ix points to info table
.init
        ld      a,(ix+2)
        cp      $20+reqpag
        ld      hl,nomemory
        jr      c,init_error
;Now find out if we have an expanded machine or not...
        ld      ix,-1
        ld      a,FA_EOF
        call_oz(os_frm)
        jr      z,init_continue
        ld      hl,need_expanded
.init_error
        push    hl
;Now define windows...
        ld      hl,baswindres  ;oops, no basic window!
        call_oz(gn_sop)
        ld      hl,windini
        call_oz(gn_sop)
        pop     hl
        call_oz(gn_sop)
        ld      bc,500
        call_oz(os_dly)
        xor     a
        call_oz(os_bye)

.init_continue
        ld   a,SC_DIS
        call_oz(Os_Esc)
        xor     a
        ld      b,a
        ld      hl,errhan
        call_oz(os_erh)
        ld      (obou),a
        ld      (oerr),hl
        call    oz_init
        ld      hl,applname
        call_oz(dc_nam)
;Flow into gamein
ENDIF


.gamein
        ld      (progstk),sp
        ld      iy,varbase+$b0
        set     6,(iy+14)

.restart  ld      hl,$3030                ;Clear the score
        ld      (varbase+$c4),hl
        ld      (varbase+$c6),hl
        ld      (varbase+$c8),hl
        xor     a
        ld      (level),a
        ld      (iy+$07),$03            ;Lives
        ld      (varbase+$c3),a
        ld      hl,myflags
        res     5,(hl)                  ;Clear cheat mode
        ld      sp,(progstk)
        call    introscreen

.startgame
        ld      ixh,varbase/256 ;$5b
        ld      sp,(progstk)                ;CHANGE
        ld      hl,myflags
        res     1,(hl)                    ;for error handler to know
        call    dolanceudg

.L5c33  ld      hl,$3939
        ld      (varbase+$cb),hl              ;Time
        ld      (varbase+$cc),hl
        xor     a
        ld      (varbase+$b0),a
        ld      (varbase+$b3),a
        ld      (iy+$08),$02
        call    L5fe8
        ld      hl,objtable
        ld      de,objtable+1
        ld      bc,15
        ld      (hl),0
        ldir
        ld      hl,myflags
        res     7,(hl)
        call    windclr
        call    gameinfo
        call    prt_levobjs
        call    prttime
        call    prtscore
        ld      (iy+$01),$07
        ld      ixl,$80
        call    L612a
        call    L6197
        call    dolanceinit


.mloop  
        call    ozscrcpy
        call    pause
        call    L63ac
        call    L5dce
        call    L61ff
        call    ckobjects
;Was space for 23672 here..
.L5c7b  call    proutbox
        call    displives
        call    L6507
        call    prttime
        call    ckfinish
        jp      nz,nextlev
        bit     1,(iy+$00)
        jr      nz,loselife                ; (9)
;        ld      h,d
;        ld      l,e
;        ld      bc,$0bb8
;        ldir    
        jr      mloop                   ; (-54)

.loselife  
        call    L61ce
        ld      hl,(varbase+$80)
        ld      a,l
        and     $f8
        ld      l,a
        ld      a,h
        and     $07
        ld      a,h
        jr      z,L5cae                 ; (2)
        add     a,$08

.L5cae  and     $f8
        ld      h,a
        ld      (varbase+$80),hl
        ld      c,l
        ld      b,$00
        call    dfaddr
        ld      a,h
        add     a,$10
        ld      b,a

.L5cbe  ld      a,255
        ld      (de),a
        inc     de
        ld      (de),a
        dec     de
;Don't need attributes!
;        push    de
;        call    df2att
;        ld      a,$57
;        ld      (de),a
;        inc     de
;        ld      (de),a
;        pop     de
        call    drow
        djnz    L5cbe                   ; (-20)
        ld      bc,(varbase+$80)
        call    dfaddr
        ld      hl,$6991+offs
        call    dosprite
        call    ozscrcpy                ;copy across
        push    ix
        ld      (iy+$13),$00
        ld      ix,$7dd1+offs

.L5ce9  push    ix
        call    L6755
        call    beeper
        call    ozread
        pop     ix
        ld      de,$0004
        add     ix,de
        ld      hl,varbase+$c3
        inc     (hl)
        ld      a,(hl)
        cp      $0b
        jr      nz,L5ce9                ; (-24)
        ld      hl,$0000

.L5d04  dec     h
        jr      nz,L5d04                ; (-3)
        dec     l
        jr      nz,L5d04                ; (-6)
        pop     ix
        ld      a,(varbase+$81)
        sub     $10
        ld      (varbase+$81),a
        ld      (varbase+$84),a
        dec     a
        cp      $ae
        jr      nc,L5d54                ; (56)
        ld      (iy+$01),$57
        ld      ixl,$80
        call    mkbcix3
        call    dfaddr
        ld      hl,$69b1+offs
        call    dosprite
        ld      b,(ix+$04)
        ld      hl,$69b1+offs

.L5d35  push    bc
        push    hl
        ld      a,b
        ld      (varbase+$84),a
        add     a,$3c
        ld      bc,$000c
        call    soundfx2_1
        call    ozread
        set     7,(iy+$00)
        pop     hl
        push    hl
        exx     
        pop     hl
        push    hl
        exx     
        call    L60db
        call    ozscrcpy
        pop     hl
        pop     bc
        djnz    L5d35                   ; (-31)

.L5d54  ld      hl,myflags
        bit     5,(hl)
        jr      nz,L5d7b                ;cheat!
        dec     (iy+$07)                ;want infy?
        jp      m,restart
        jr      L5d7b                   ; (31)


;Check for next level..

.nextlev  
        call    ozscrcpy
        call    dobonus
        ld      a,(varbase+$c5)
        cp      (iy+$14)
        jr      z,L5d6d                 ; (6)
        ld      (varbase+$c4),a
        inc     (iy+$07)                ;award extra life

.L5d6d  call    L5d7e
        ld      hl,level
        inc     (hl)
        ld      a,(hl)
        cp      $18
        jr      nz,L5d7b                ; (2)
        ld      (hl),$00

.L5d7b  jp      L5c33

.L5d7e  ld      hl,attrmap    ;keeping attribute address for convenience!
        ld      c,$10

.L5d83  ld      de,$0020
        call    L5d93
        ld      de,$ffe0
        call    L5d93
        dec     c
        jr      nz,L5d83                ; (-15)
        ret     


.L5d93  ld      b,$10

.L5d96  push    hl

        ld      a,h
        and     3
        rlca
        rlca
        rlca
        add     a,screen/256
        ld      h,a
        ld      a,8
.clrscr1
        ex      af,af'
        ld      (hl),0
        inc     h
        ex      af,af'
        dec     a
        jp      nz,clrscr1

        pop     hl
        add     hl,de
        djnz    L5d96                   ; (-4)
        and     a
        sbc     hl,de
        inc     hl
        push    hl
        push    de
        push    bc
        call    ozscrcpy_noc
        call    soundfx1
        pop     bc
        pop     de
        pop     hl
        ret     

;Sound effects
;Sound


.soundfx1
        ld      bc,20
.soundfx1_1  
        ld      a,(myflags)
        rrca
        ret     c
;Insert call for sound check and ret z/whatever
        ld      a,($4B0)
        and     63
.soundfx1_2  
        out     ($B0),a
        dec     l
        jr      nz,soundfx1_3
        ex      af,af'
        ld      a,r
        ld      l,a
        ex      af,af'
        xor     64
.soundfx1_3  
        djnz    soundfx1_2
        dec     c
        jr      nz,soundfx1_2
.soundres
        ld      a,($4B0)
        and     63
        ld      ($4B0),a
        out     ($B0),a
        ret     
;
.soundfx2
        ld      bc,2
.soundfx2_1  
        ld      l,a
        ld      h,a
        ld      a,(myflags)
        rrca
        ret     c
        ld      a,($4B0)
        and     63
.soundfx2_2  
        out     ($B0),a         ;CHANGE
        dec     l
        jr      nz,soundfx2_3
        ld      l,h
        xor     64
.soundfx2_3  
        djnz    soundfx2_2
        dec     c
        jr      nz,soundfx2_2
        call    soundres
        ret     


.L5dce  ld      ixl,$80
        call    L5ec8
        ld      (iy+$01),$07
        call    L60d8
        call    mkbcix3
        ld      a,b
        add     a,$11
        ld      b,a
        call    dfaddr
        sla     (iy+$0a)
        exx     
        call    L5f2c
        exx     
        bit     3,(iy+$00)
        ret     nz

        call    df2att
        res     0,(iy+$00)
        ex      de,hl
        bit     6,(hl)
        ret     nz

        inc     l
        bit     6,(hl)
        call    z,L5ef6 ;bright! - Ladder?
        ret     


;
;Aha..
;Keyboard routines CHANGE!
;This is the pause routine!!!


.pause
        call    keys
        bit     5,e     ;mini screen
        jr      z,pause0
        ld      a,(myflags)
        xor     8
        ld      (myflags),a
.pause0 
        bit     6,e
        jr      z,pause2        ;inverse
        ld      a,(myflags)
        xor     16      ;bit    4
        ld      (myflags),a
.pause2
        bit     4,e
IF BASIC
        jp      nz,out
ENDIF
IF !BASIC
        jp      nz,restart
ENDIF
        bit     3,e
        ret     z
        push    ix
        ld      bc,10
        call_oz(os_dly)
.pause1
        call    kfind
        inc     d
        jr      z,pause1
        call    ozread
        pop     ix
        ret


.L5e38  set     0,(hl)
        ret     

.L5e3b  set     1,(hl)
        ret     

.L5e3e  set     2,(hl)
        ret     


.readkeys  
        push    ix
        call    ozread
        pop     ix
        call    keys    ;this is our neat OZ call thing..
        ld      a,e
        and     7
        ld      d,a
        ld      hl,varbase+$be
        ld      a,(hl)
        and     248
        or      d
        ld      (hl),a


.L5ea9  ld      a,(hl)
        cpl     
        and     $03
        jr      nz,L5eba                ; (11)
        ld      a,(hl)
        ld      d,a
        cpl     
        and     $18
        rrca    
        rrca    
        rrca    
        xor     d
        ld      (hl),a
        ret     


.L5eba  ld      a,(hl)
        ld      d,a
        and     $03
        rla     
        rla     
        rla     
        ld      e,a
        ld      a,d
        and     $e7     ;11100111
        or      e
        ld      (hl),a
        ret     


.L5ec8  call    readkeys
        bit     0,(hl)
        call    nz,L5f84
        bit     1,(hl)
        call    nz,L5f74
        bit     2,(hl)
        call    nz,L5f19
        call    mkbcix3
        ld      a,c
        sub     (ix+$00)
        add     a,$04
        add     a,c
        ld      c,a
        ld      a,(varbase+$65)
        ld      (varbase+$b1),a
        call    L5f93
        ret     nz

        ld      a,(ix+$00)
        ld      (ix+$03),a
        ret     


.L5ef6  ld      a,(ix+$04)
        cp      $78
        ret     nc

        add     a,$04
        ld      (ix+$04),a
        ld      hl,varbase+$b9
        set     0,(iy+$00)
        ld      a,(hl)
        inc     (hl)
        cp      $05
        jr      nz,L5f10                ; (2)
        ld      (hl),$00

.L5f10  ld      a,(varbase+$b9)
        add     a,a
        add     a,a
        add     a,a
        jp      soundfx2

.L5f19  bit     3,(iy+$00)
        ret     nz

        bit     0,(iy+$00)
        ret     nz

        ld      (iy+$09),$05
        set     3,(iy+$00)
        ret     


.L5f2c  bit     3,(iy+$00)
        ret     z

        ld      a,(ix+$04)
        sub     $04
        bit     7,a
        jr      z,L5f43                 ; (9)
        xor     a
        ld      (ix+$04),a
        res     3,(iy+$00)
        ret     

;Moving up..

.L5f43  ld      (ix+$04),a
        ld      b,a
        ld      c,(ix+$00)
        call    dfaddr
        call    df2att
        ex      de,hl
        ld      a,(varbase+$65)
        cp      (hl)
        jr      z,L5f69                 ; (18)
        inc     l
        cp      (hl)
        jr      z,L5f69                 ; (14)
        push    hl
        call    L5f10
        pop     hl
        dec     (iy+$09)
        ret     nz

        res     3,(iy+$00)
        ret     


.L5f69  ld      a,(ix+$01)
        ld      (ix+$04),a
        res     3,(iy+$00)
        ret     


.L5f74  ld      a,(ix+$03)
        cp      $f4
        ret     nc

        set     0,(ix+$05)
        add     a,$04
        ld      (ix+$03),a
        ret     


.L5f84  ld      a,(ix+$03)
        or      a
        ret     z

        res     0,(ix+$05)
        sub     $04
        ld      (ix+$03),a
        ret     


.L5f93  call    dfaddr
        call    df2att
        ld      a,(varbase+$b1)
        ex      de,hl
        ld      de,$0020
        cp      (hl)
        ret     z

        add     hl,de
        cp      (hl)
        ret     z

        add     hl,de
        ld      d,a
        ld      a,(ix+$04)
        and     $07
        jr      nz,L5fb0                ; (2)
        or      h
        ret     


.L5fb0  ld      a,d
        cp      (hl)
        ret     


.L5fb3  ld      ixl,$40
        ld      (iy+$04),$ff
        ld      de,$001f

.L5fbd  call    mkbcix0
        ret     z

        ld      hl,varbase+$b4
        inc     (hl)
        ld      a,(hl)
        cp      $04
        ret     z

        ld      a,b
        or      $c0
        ld      l,a
        ld      h,$02
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        ld      b,attrdiff
        add     hl,bc
        ld      b,(ix+$02)
        ld      a,$46

.L5fdc  ld      (hl),a
        inc     l
        ld      (hl),a
        add     hl,de
        djnz    L5fdc                   ; (-6)
        ld      c,$03
        add     ix,bc
        jr      L5fbd                   ; (-43)

.L5fe8  call    L6057
        call    cls
        call    L658c
        call    L6363
        call    L5fb3
        ld      ixl,$63
        call    mkbcix0
        ld      (varbase+$80),bc
        ld      (varbase+$83),bc
        ld      a,(varbase+$7f)
        ld      (varbase+$82),a
        ld      (varbase+$85),a
        ld      (varbase+$b2),a
        ret     


.gameinfo  
        ld      bc,$2223
        ld      (iy+$01),$0f
        call    printtext
        defm    "Items Collected"
        defb    ':'+128

;items start at $2228

        ld      bc,$2023
        ld      (iy+$01),$17
        call    printtext
        defm    "SCORE: "
        defm    "00000"
        defb    ' '+128

        ld      bc,$2035
        call    printtext
        defm    "TIME "
        defm    "999"
        defb    ' '+128
        ret     


;Gets level...
.L6057  ld      h,(iy+$06)
        ld      l,$00
        srl     h
        rr      l
        ld      de,$71d1+offs
        add     hl,de
        ld      de,varbase+$00
        ld      bc,$0080
        ldir    
        ret     

;Clear screen

.cls  ld      hl,screen
        ld      de,screen+1

.L6073  ld      bc,4096
        ld      (hl),l
        ldir    
        ld      bc,512
        ld      (hl),$07
        ldir    
        ret     


.dosprite  
        ld      b,$10
.dosprite1  
        call    dosprline
        djnz    dosprite1                   ; (-5)
        ret     


.dotwospr  
        ld      b,$10
.dotwospr1  
        call    dosprline
        exx     
        call    dosprline
        exx     
        djnz    dotwospr1                   ; (-10)
        ret     

        

.dosprline  
        ld      a,(de)
        xor     (hl)
        ld      (de),a
        inc     e
        inc     hl
        ld      a,(de)
        xor     (hl)
        ld      (de),a
        dec     e
        inc     hl

;Drow

.drow  inc     d
        ld      a,d
        and     $07
        ret     nz

        ld      a,e
        add     a,$20
        ld      e,a
        and     $e0
        ret     z

        ld      a,d
        sub     $08
        ld      d,a
        ret     


;Needs to be changed for different attr map

.df2att 
        ld      a,d
        rrca    
        rrca    
        rrca    
        and     $03
        add     a,attrmap/256
        ld      d,a
        ret     


.dfaddr  ld      a,b
        rla     
        rla     
        and     $e0
        ld      e,a
        ld      a,c
        rra     
        rra     
        rra     
        and     $1f
        or      e
        ld      e,a
        ld      a,b
        rra     
        rra     
        rra     
        and     $18
        ld      d,a
        ld      a,b
        and     $07
        add     a,d
        or      screen/256
        ld      d,a
        ret     


.L60d8
         call    L6136

.L60db  call    mkbcix0
        call    dfaddr
        bit     7,(iy+$00)
        call    z,L6178
        exx     
        call    mkbcix3
        ld      a,(ix+$05)
        ld      (ix+$00),c
        ld      (ix+$01),b
        ld      (ix+$02),a
        call    dfaddr
        bit     7,(iy+$00)
        res     7,(iy+$00)
        call    z,L6178
        push    hl
        push    de
        call    dotwospr
        exx     
        pop     de
        pop     hl
        set     0,(iy+$0a)
        ld      b,$10

.L6114  ld      a,(de)
        and     (hl)
        cp      (hl)
        ret     nz

        inc     e
        inc     hl
        ld      a,(de)
        and     (hl)
        cp      (hl)
        ret     nz

        dec     e
        inc     hl
        call    drow
        djnz    L6114                   ; (-17)
        res     0,(iy+$0a)
        ret     


.L612a  call    mkbcix3
        call    dfaddr
        call    L6178
        call    dosprite

.L6136  call    mkbcix3
        call    dfaddr
        call    df2att
        ex      de,hl
        ld      de,$001f
        call    L615d
        inc     l
        call    L615d
        add     hl,de
        call    L615d
        inc     l
        call    L615d
        add     hl,de
        ld      a,(ix+$04)
        and     $07
        ret     z

        call    L615d
        inc     l

.L615d  ld      a,(hl)
        cp      $46
        ret     z

        and     $3f
        cp      $96
        ret     z

        ld      a,(varbase+$b1)
        ld      (hl),a
        ret     

;Get address of object...

.getobjudg  
        and     $7f
        ld      l,a
        ld      h,$00
        add     hl,hl
        add     hl,hl
        add     hl,hl
        ld      de,$688f+offs
        add     hl,de
        ret     

.L6178  push    de
        ld      a,(ix+$00)
        rrca    
        rrca    
        and     $03
        ld      l,a
        ld      a,(ix+$02)
        and     $3f
        rlca    
        rlca    
        or      l
        ld      l,a
        ld      h,$00
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        ld      de,$69d1+offs
        add     hl,de
        pop     de
        ret     


.L6197  ld      hl,varbase+$94
        ld      de,varbase+$95
        ld      bc,$001b
        ld      (hl),b
        ldir    
        ld      ixl,$67
        ld      (iy+$02),$ff
        ld      hl,varbase+$94

.L61ad  call    mkbcix0
        jr      z,L61ce                 ; (28)
        inc     (iy+$02)
        ld      a,(iy+$02)
        cp      $04
        jr      z,L61ce                 ; (18)
        ld      a,(ix+$04)
        call    L61f2
        ld      a,(ix+$05)
        ld      (hl),a
        inc     hl
        ld      de,$0006
        add     ix,de
        jr      L61ad                   ; (-33)

.L61ce  ld      (iy+$02),$ff
        ld      ixl,$94

.L61d5  call    mkbcix0
        ret     z

        inc     (iy+$02)
        ld      a,(iy+$02)
        cp      $04
        ret     z

        ld      a,(ix+$06)
        ld      (varbase+$b1),a
        call    L612a
        ld      de,$0007
        add     ix,de
        jr      L61d5                   ; (-29)

.L61f2  ld      (hl),c
        inc     l
        ld      (hl),b
        inc     l
        ld      (hl),a
        inc     l
        ld      (hl),c
        inc     l
        ld      (hl),b
        inc     l
        ld      (hl),a
        inc     l
        ret     


.L61ff  ld      ixl,$67
        ld      (iy+$02),$ff
        ld      de,varbase+$94

.L6209  call    mkbcix0
        ret     z

        ld      hl,varbase+$b2
        inc     (hl)
        ld      a,(hl)
        cp      $04
        ret     z

        push    ix
        push    de
        call    L6228
        pop     hl
        pop     ix
        ld      de,$0006
        add     ix,de
        inc     e
        add     hl,de
        ex      de,hl
        jr      L6209                   ; (-31)

.L6228  push    de
        push    ix
        call    L626a
        pop     ix
        bit     5,(iy+$00)
        jr      z,L623e                 ; (8)
        ld      a,(ix+$04)
        add     a,$80
        ld      (ix+$04),a

.L623e  pop     ix
        call    mkbcix0
        push    bc
        call    L60d8
        pop     bc
        bit     0,(iy+$0a)
        ret     z

        ld      ixl,$80
        push    bc
        call    mkbcix3
        pop     hl
        ld      a,l
        sub     c
        call    m,L64f7
        cp      $10
        ret     nc

        ld      a,h
        sub     b
        call    m,L64f7
        cp      $10
        ret     nc

        set     1,(iy+$00)
        ret     


.L626a  ld      a,(ix+$05)
        ld      (varbase+$b1),a
        res     5,(iy+$00)
        bit     7,(ix+$04)
        push    de
        ld      e,(ix+$03)
        jr      z,L6298                 ; (26)
        ld      d,(ix+$00)
        pop     ix
        ld      a,(ix+$03)
        or      a
        jr      z,L6293                 ; (10)
        res     0,(ix+$05)
        sub     e
        ld      (ix+$03),a
        cp      d
        ret     nc


.L6293  set     5,(iy+$00)
        ret     


.L6298  ld      d,(ix+$02)
        pop     ix
        ld      a,(ix+$03)
        cp      $f4
        jr      nc,L6293                ; (-17)
        set     0,(ix+$05)
        add     a,e
        ld      (ix+$03),a
        cp      d
        ret     c

        jr      L6293                   ; (-29)

;Get sprite into udgs!
;Lance right at 6a91



;Set the lancelot graphics up in udgs...

.dolanceinit
;First of all calculate width of all lances..each one is 3 chars wide
        xor     a
        ld      (livex),a
        inc     a
        ld      (livedir),a
        ld      a,(lives)
        ld      b,a
        add     a,a
        add     a,b
        ld      (livew),a
        ret

.dolanceudg
        push    ix
        ld      b,8
        ld      ix,lancedef
.deflancelp
        push    bc
        push    ix
        ld      l,(ix+0)
        ld      h,(ix+1)
        ld      a,(ix+2)
        call    dolanceudg0
        pop     ix
        pop     bc
        inc     ix
        inc     ix
        inc     ix
        djnz    deflancelp
        pop     ix

        ld      b,8
        ld      hl,udg2+1
.clear1
        ld      (hl),128
        inc     hl
        djnz    clear1
        ld      a,74+48-2
        ld      (udg2),a
        ld      hl,udgdeft
        call_oz(gn_sop)
        ret


.dolanceudg0
        ld      (dotemp),a
        ld      b,2
.dolanceudg1
        push    bc
        call    doluinit
        push    hl
.dolanceudg2
        ld      a,(hl)
        rrca
        rrca
        and     63
        or      128
        ld      (de),a
        inc     hl
        inc     hl
        inc     de
        djnz    dolanceudg2
        call    doluend
        pop     hl
        push    hl
.dolanceudg3
        ld      c,0
        ld      a,(hl)
        rlca
        rlca
        rlca
        rlca
        and     @00110000
        ld      c,a
        inc     hl
        ld      a,(hl)  ;shift 4 to right
        rrca
        rrca
        rrca
        rrca
        and     15
        or      c
        or      128
        ld      (de),a
        inc     de
        inc     hl
        djnz    dolanceudg3
        call    doluend
        pop     hl
        push    hl
        inc     hl
.dolanceudg4
        ld      a,(hl)
        rlca
        rlca
        and     @00111100
        or      128
        ld      (de),a
        inc     hl
        inc     hl
        inc     de
        djnz    dolanceudg4
        ld      a,(dotemp)
        dec     a          ;so don't waste udg
        ld      (dotemp),a
        call    doluend
        pop     hl
        ld      bc,16
        add     hl,bc
        pop     bc      
        djnz    dolanceudg1
        ret


;Tables for setting up Lancelot udgs..
.lancedef
        defw    $6a91+offs-64
        defb    74-2
        defw    $6a91+offs-32
        defb    74+6-2
        defw    $6a91+offs
        defb    74+12-2
        defw    $6a91+offs+32
        defb    74+18-2
;left
        defw    $69f1+offs+64
        defb    74+24-2
        defw    $69f1+offs-32
        defb    74+30-2
        defw    $69f1+offs+0
        defb    74+36-2
        defw    $69f1+offs+32
        defb    74+42-2



.plotlanceudg2
        ld      b,74-2
        ld      a,(livedir)
        dec     a
        jr      z,plotlance_1
        ld      b,74+24-2
.plotlance_1
        ld      a,(liveanim)
        ld      d,a
        add     a,a     ;2x
        add     a,d     ;3x
        add     a,a     ;6x
        add     a,b

;Do the plotting
;Entry: c=x position 
;       a=starting udg..
        ld      b,6
        call    plotabs
        inc     c
        add     a,65
        call    plotabs
        inc     c
        add     a,65
        call    plotabs
        inc     b
        add     a,67
        call    plotabs
        dec     c
        add     a,63
        call    plotabs
        dec     c
        add     a,63
        call    plotabs
        ret
        


.doluend
        ld      hl,udgdeft
        call_oz(gn_sop)

.doluinit
        ld      a,(dotemp)
        ld      (udg2),a
        inc     a
        ld      (dotemp),a
        ld      de,udg2+1
        ld      b,8
        ret

        
;Lives routine? Walking to and fro!

.displives  
        ld      a,(lives)
        and     a
        ret     z
        ld      a,(flashb)
        rrca
        ret     nc
        ld      a,(liveanim)
        inc     a
        and     3
        ld      (liveanim),a
        rrca
        jr      nc,displivechx
        ld      a,(livex)
        jr      displive_d
.displivechx
        push    ix
        ld      hl,myflags
        res     6,(hl)          ;blank indicator
        ld      ix,livedir
        ld      a,(ix+0)
        add     a,(ix+1)          ;old x pos
        ld      c,a
;        cp      2               ;min x
        jr      nz,displive_noleft
        ld      (ix+0),1        ;walking right
        set     6,(hl)          ;changed dir
.displive_noleft
        add     a,(ix+2)          ;width of all lances
        cp      30
        jr      c,displive_noright
        ld      (ix+0),255      ;moving left
        set     6,(hl)          ;changed dir
.displive_noright
        ld      (ix+1),c
        ld      a,c
        pop     ix
.displive_d
        add     a,32-14+3-2
        ld      c,a
        push    bc
        ld      a,(lives)
        ld      b,a
;        ld      c,32-14+3
.displives1
        push    bc
        call    plotlanceudg2
        pop     bc
        inc     c
        inc     c
        inc     c
        djnz    displives1
        pop     bc

;Clear out the trailing column..
        ld      b,6
        dec     c
        ld      a,74+48-2
        call    plotabs
        inc     b
        ld      a,74+48-2
        call    plotabs
        ret







.L6363  ld      ixl,$40
        ld      (iy+$04),$ff

.L636a  call    mkbcix0
        ret     z

        ld      hl,varbase+$b4
        inc     (hl)
        ld      a,(hl)
        cp      $04
        ret     z

        call    df_loc
        call    L6393
        ld      de,$0003
        add     ix,de
        jr      L636a                   ; (-25)

.mkbcix3  ld      c,(ix+$03)
        ld      b,(ix+$04)
        ret     


.mkbcix0  
        ld      c,(ix+$00)
        ld      b,(ix+$01)
        ld      a,b
        or      c
        ret     


.L6393  ld      l,(iy+$05)
        ld      h,$00
        ld      bc,$6951+offs
        add     hl,bc
        ld      a,(ix+$02)

.L639f  push    hl
        ex      af,af'
        ld      b,$08
        call    dosprite1
        ex      af,af'
        pop     hl
        dec     a
        jr      nz,L639f                ; (-12)
        ret     


.L63ac  ld      ixl,$40
        ld      a,(varbase+$b5)
        add     a,$02
        and     $0e
        ld      (varbase+$b5),a
        ld      (iy+$04),$ff

.L63bd  call    mkbcix0
        ret     z

        ld      hl,varbase+$b4
        inc     (hl)
        ld      a,(hl)
        cp      $04
        ret     z

        call    df_loc
        push    de
        ld      l,(iy+$05)
        ld      h,$00
        ld      bc,$6951+offs
        add     hl,bc
        push    hl
        ld      a,(ix+$02)
        exx     
        pop     hl
        pop     de
        dec     hl
        dec     hl
        exx     
        srl     a
        jr      nc,L63e9                ; (5)
        ld      b,$08
        inc     a
        jr      L63eb                   ; (2)

.L63e9  ld      b,$10

.L63eb  push    hl
        ex      af,af'
        call    dotwospr1
        ex      af,af'
        exx     
        pop     hl
        push    hl
        dec     hl
        dec     hl
        exx     
        pop     hl
        dec     a
        jr      nz,L63e9                ; (-18)
        ld      de,$0003
        add     ix,de
        jr      L63bd                   ; (-69)

;Get df address from lines...
.df_loc  
        ld      a,b
        and     $18
        or      screen/256
        ld      d,a
        ld      a,b
        and     $07
        rrca    
        rrca    
        rrca    
        or      c
        ld      e,a
        ret     

;This checks for level finish

.ckfinish  
        ld      ixl,$80
        call    mkbcix3
        call    dfaddr
        call    df2att

;Game over when we check for flash!
        ex      de,hl
        ld      de,$001f
        bit     7,(hl)
        ret     nz
        inc     l
        bit     7,(hl)
        ret     nz
        add     hl,de
        bit     7,(hl)
        ret     nz
        inc     l
        bit     7,(hl)
        ret     

;This checks to see if we have them all, then prints up the box...

.proutbox  
        bit     2,(iy+$00)
        ret     nz

        ld      ixl,$61
        call    mkbcix0
        call    df_loc
 ;       bit     6,(iy+$00)
 ;       jr      nz,L6452                ; (14)
        ld      hl,$6981+offs
        ld      a,(flashb)
        and     a
        jr      nz,L6452
        push    de
        ld      c,0
        ld      a,(myflags)
        and     128
        jr      z,proutbox1
        ld      c,255
.proutbox1
        ld      b,$08
.proutbox2
        ld      a,(hl)
        xor     c
        ld      (de),a
        inc     e
        inc     hl
        ld      a,(hl)
        xor     c
        ld      (de),a
        dec     e
        inc     d
        inc     hl
        djnz    proutbox2
;        call    dosprite1
        pop     de
        set     6,(iy+$00)

.L6452  call    df2att
        ld      a,$96
        ld      (de),a
        inc     e
        ld      (de),a
        ret     

;Check to see if we have an object

.ckobjects  
        ld      ixl,$4c
        res     2,(iy+$00)
        ld      (iy+$02),$ff
;This changes the colour of the objects...
        ld      a,(varbase+$bb)
        ld      c,a
        inc     a
        and     $07
        ld      b,a
        ld      a,c
        and     $f8
        or      b
        ld      (varbase+$bb),a
        ld      a,(flashb)
        inc     a
        and     3
        ld      (flashb),a
        jr      nz,L6475
        ld      a,(myflags)
        xor     128
        ld      (myflags),a
.L6475  call    mkbcix0
        ret     z

        ld      hl,varbase+$b2
        inc     (hl)
        ld      a,(hl)
        cp      $07
        ret     z

        bit     7,(ix+$02)
        jp      nz,L64ef                ; (104)
        set     2,(iy+$00)              ;mark finish.
        ld      a,(flashb)
        and     a
        jr      nz,noflash
        push    bc
        ld      a,(ix+2)
        call    getobjudg
        call    dfaddr
        call    proverchar
        pop     bc
.noflash
;        call    dfaddr
;        call    df2att
;        ld      a,(varbase+$bb)
;        ld      (de),a
        bit     1,(iy+$0a)
;        jr      z,L64ef                 ; (84) ;who knows why!
        ld      hl,(varbase+$83)        ;lancelot next coords
        ld      a,l
        and     $f8
        sub     c
        add     a,$04
        call    m,L64f7
        cp      $0c
        jr      nc,L64ef                ; (68)
        ld      a,h
        sub     b
        add     a,$04
        call    m,L64f7
        cp      $0c
        jr      nc,L64ef                ; (57)
;Have got the object here!
        set     7,(ix+$02)
        call    mkbcix0
        ld      a,(ix+$02)
        call    getobjudg
        push    hl
        call    dfaddr
        ld      a,(myflags)
        bit     7,a
        call    z,proverchar
;This is where we print it on screen, now, it would be nice to change
;it into a user graphic and dump it on screen..
        pop     hl
        inc     (iy+$03)
        call    doudg

        ld      a,(iy+$03)
        add     a,$34
        ld      c,a
        ld      b,$22
        call    doposn
        ld      a,(iy+3)
        call    printudg


;        inc     (iy+$03)
        push    ix
        ld      hl,varbase+$c8
        call    sco_inc_1
        ld      bc,$000a
        call    soundfx1_1
        call    prtscore
        pop     ix

.L64ef  ld      de,$0003
        add     ix,de
        jp      L6475

.L64f7  neg     
        ret     

;Now stores addy of udgs in objtable so can redefine after preempt
.doudg
        ex      de,hl
        ld      a,(iy+3)
        dec     a
        ld      l,a
        ld      h,0
        add     hl,hl
        ld      bc,objtable
        add     hl,bc
        ld      (hl),e
        inc     hl
        ld      (hl),d
        ex      de,hl
        ld      a,(iy+3)
.doudgent
        add     a,64
        ld      (udg2),a
        ld      de,udg2+1
        ld      b,8
.doudg1
        ld      a,(hl)
        rrca
        and     63
        or      128
        ld      (de),a
        inc    hl
        inc     de
        djnz    doudg1
        ld      hl,udgdeft
        call_oz(gn_sop)
        ret

.errhan
        ret     z       ;fatal error
IF BASIC
        cp      RC_Susp
ENDIF
IF !BASIC
        cp      RC_Draw         ;rc_susp        (Rc_susp for BASIC!)
ENDIF
        jr      nz,errhan2
        push    af
        call    windsetup
        ld      hl,myflags
        bit     1,(hl)
        jr      z,errhan_game
;Hmmm, it's the title screen problems..have been preempted, but
;not backed up map..so copy it back again!!!
        bit     2,(hl)
        call    z,introsetup
        call    nz,redefsetup
        jr      errhan3


;Redefine the udgs..hopefully! - During the game
.errhan_game
        call    gameinfo        ;print the window..
        call    dolanceudg
        call    displives
        ld      bc,$2235
        call    doposn
        ld      b,8
        ld      hl,objtable
.errhan1
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      a,d
        or      e
        jr      z,errhan3
        push    bc
        push    hl
        ld      a,8
        sub     b
        push    af
        ex      de,hl
        call    doudgent
        pop     af
        call    printudg
        pop     hl
        pop     bc
        djnz    errhan1
.errhan3
        pop     af
;This is to handle all errors
;Needs to be changed!
.errhan2
        cp      RC_Quit                 ;they don't like us!
        jr      nz,keine_error
        xor     a
        call_oz(os_bye)         


.keine_error
IF !BASIC
;        and     a
        xor     a
        ret
ENDIF
IF BASIC
;This for BASIC only
        ld      hl,(oerr)
        dec     a
        inc     a       ;z=0
        scf
        jp      (hl)
ENDIF

.printudg
        add     a,64
        push    af
        ld      hl,errhant
        call_oz(gn_sop)
        pop     af
        call_oz(os_out)
        ret






.sco_inc  
        ld      hl,varbase+$c9

.sco_inc_1  
        inc     (hl)
        ld      a,(hl)
        cp      $3a
        ret     nz
        ld      (hl),$30
        dec     hl
        jr      sco_inc_1                   ; (-10)

.L6507  bit     1,(iy+$00)
        ret     nz

        call    L6522
        ld      b,$03
        ld      hl,varbase+$cb
        xor     a
        add     a,(hl)
        inc     hl
        add     a,(hl)
        inc     hl
        add     a,(hl)
        cp      $90
        ret     nz

        set     1,(iy+$00)
        ret     


.L6522  ld      hl,varbase+$cd

.L6525  dec     (hl)
        ld      a,(hl)
        cp      $2f
        ret     nz

        ld      (hl),$39
        dec     hl
        inc     b
        jr      L6525                   ; (-11)

;Print time

.prttime  
        ld      bc,$203a
        ld      (iy+$01),$17
        ld      ix,varbase+$cb
        jp      printstr

;Print score
.prtscore  
        ld      bc,$202A
        ld      (iy+$01),$17
        ld      ix,varbase+$c5
        jp      printstr

;Increment the scores.. at tend of level...
;Gonna rewrite this to be quicker! Decrements each column

.dobonus
        ld      hl,varbase+$CD        ;time digit
        ld      de,varbase+$C9        ;score digit
        ld      a,0
        ld      (mysound),a
        ld      b,3
.dobonus0
        push    bc
.dobonus1
        dec     (hl)
        ld      a,47
        cp      (hl)
        jr      z,dobonus2
        push    hl
        push    de
        ex      de,hl
        call    sco_inc_1
        call    prtscore
        call    prttime
        ld      bc,5
        call_oz(os_dly)
        ld      hl,mysound
        ld      a,(hl)
        sub     10
        ld      (hl),a
        ld      bc,$000c
        call    soundfx2_1
        pop     de
        pop     hl
        jr      dobonus1
.dobonus2
        ld      (hl),'0'
        dec     hl
        dec     de
        pop     bc
        djnz    dobonus0
        ret


;.do_bonus  
;        bit     1,(iy+$00)
;        ret     nz
;        call    L6507
;        call    sco_inc
;        call    prtscore
;        call    prttime
;        ex      af,af'
;        inc     a
;        and     $07
;        out     ($fe),a
;        ex      af,af'
;        jr      do_bonus                   ; (-26)

.prt_levobjs  
        ld      ixl,$4c
        ld      (iy+$02),$ff

.L656d  call    mkbcix0
        ret     z

        ld      hl,varbase+$b2
        inc     (hl)
        ld      a,(hl)
        cp      $07
        ret     z

        ld      a,(ix+$02)
        call    getobjudg
        call    dfaddr
        call    proverchar
        ld      de,$0003
        add     ix,de
        jr      L656d                   ; (-31)

.L658c  ld      a,(varbase+$65)
        ld      (varbase+$b1),a
        ld      a,(varbase+$66)
        add     a,$10
        call    getobjudg
        ld      (varbase+$bc),hl
        ld      hl,varbase+$00
        ld      de,screen
        call    L65a9
        ld      de,screen+2048

.L65a9  ld      b,$20

.L65ab  push    bc
        call    L65b3
        pop     bc
        djnz    L65ab                   ; (-7)
        ret     


.L65b3  ld      c,$08
        ld      a,(hl)
        push    hl

.L65b7  rla     
        jr      nc,L65c9                ; (15)
        ex      af,af'
        ld      hl,(varbase+$bc)
        call    proverchar
        ld      a,d
        sub     $08
        ld      d,a
        call    L6611
        ex      af,af'

.L65c9  inc     de
        dec     c
        jr      nz,L65b7                ; (-22)
        pop     hl
        inc     hl
        ret     


.doposn
     push       bc
     ld   hl,doposnt
     call_oz(gn_sop)
     pop        bc
        ld      a,c
        call_oz(os_out)
        ld      a,b
        call_oz(os_out)
     ret







.printtext  
        pop     ix
        call    printstr
        jp      (hl)

.printstr  
;        call    df_loc
        call    doposn

.L65d9  ld      a,(ix+$00)
        and     127
        call_oz(os_out)
        ld      a,(ix+$00)
        inc     ix
        rla     
        jr      nc,L65d9                ; (-30)
        push    ix
        pop     hl
        ld      ixh,varbase/256
        ret     


.L65fe  ld      b,$08

.L6600  ld      a,(hl)
        ld      (de),a
        inc     hl
        inc     d
        djnz    L6600                   ; (-6)
        ret     


.proverchar  
        ld      b,$08
.L6609  ld      a,(de)
        xor     (hl)
        ld      (de),a
        inc     hl
        inc     d
        djnz    L6609                   ; (-7)
        ret     


.L6611  push    de
        call    df2att
        ld      a,(varbase+$b1)
        ld      (de),a
        pop     de
        ret     


.introscreen  
        ld      hl,myflags
        set     1,(hl)
        res     2,(hl)
        call    introsetup




        ld      (iy+$13),$00

.L66ea  ld      l,(iy+$13)
        srl     l
        ld      h,$00
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        ex      de,hl
        ld      ix,$7dfd+offs
        add     ix,de
        call    L670f
        inc     (iy+$13)
        ld      a,(iy+$13)
        cp      $40
        jr      c,L66ea                 ; (-31)

.L6709  ld      (iy+$13),$00
        jr      L66ea                   ; (-37)

.L670f  ld      b,$07

.L6711  push    ix
        djnz    L6711                   ; (-4)
        call    L6755
        call    dobeeper
        pop     ix
        call    L6747
        pop     ix
        call    L6762
        pop     ix
        call    L6747
        pop     ix
        ld      e,(ix+$04)
        ld      d,(ix+$0d)
        ld      l,(ix+$0e)
        ld      h,(ix+$0f)
        call    dobeeper
        pop     ix
        call    L6747
        pop     ix
        call    L6762
        pop     ix

.L6747  ld      e,(ix+$04)
        ld      d,(ix+$05)
        ld      l,(ix+$06)
        ld      h,(ix+$07)
        jr      dobeeper                   ; (103)

.L6755  ld      e,(ix+$00)
        ld      d,(ix+$01)
        ld      l,(ix+$02)
        ld      h,(ix+$03)
        ret     


.L6762  ld      e,(ix+$08)
        ld      d,(ix+$09)
        ld      l,(ix+$0a)
        ld      h,(ix+$0b)
;        jr      dobeeper                   ; (76)



.dobeeper  push    hl
        push    de
        call    L67e1
        ld      h,d
        ld      l,e
        ld      bc,$0bb8
        ldir    
        pop     de
        pop     hl

.beeper
          ld   a,(myflags)
          rrca
          ret  c
          call oz_di
          push af
          ld   a,l
          srl  l
          srl  l
          cpl
          and  3
          ld   c,a
          ld   b,0
          ld   ix,beixp3
          add  ix,bc
;OZ stuff here..
          ld   a,($4B0)
          and  63
          ld   ($4B0),a
          out  ($B0),a
.beixp3
          nop
          nop
          nop
          inc  b
          inc  c
.behllp   dec  c
          jr   nz,behllp
          ld   c,$3F
          dec  b
          jp   nz,behllp
          xor  64
          out  ($B0),a
          ld   b,h
          ld   c,a
          bit  6,a            ;if o/p go again!
          jr   nz,be_again
          ld   a,d
          or   e
          jr   z,be_end
          ld   a,c
          ld   c,l
          dec  de
          jp   (ix)
.be_again
          ld   c,l
          inc  c
          jp   (ix)
.be_end
          pop  af
          call oz_ei
          ret



.L67e1  
        call    cksound
        call    ozread
        call    keys
        bit     7,e
        jr      nz,redefine
        bit     2,e
        ret     z
        jp      startgame

;Redefine keys, clear window, input, and then jp to introscreen
.redefine
        ld      hl,myflags
        set     2,(hl)
        ld      bc,10
        call_oz(os_dly)
        ld      b,4
        ld      hl,pkeys
        ld      de,deftext
.redefine1
        push    bc
        push    hl
        ld      (redefpos),de
        call    redefsetup
        inc     hl
        push    hl


.redefine2
        call    ozread
        call    kfind
        jr      nz,redefine2
        inc     d
        jr      z,redefine2
        dec     d
        push    de
        call    mapkey
        pop     bc
        jr      z,redefine2
        push    bc
        call    soundfx3
        pop     bc
        pop     de
        pop     hl
        ld      (hl),b
        inc     hl
        ld      bc,10
        call_oz(os_dly)
        pop     bc
        djnz    redefine1
        ld      hl,pkeys
        ld      de,cheatkey
        ld      b,4
.ck1
        ld      a,(de)
        cp      (hl)
        jr      nz,nodef
        inc     hl
        inc     de
        djnz    ck1
        call    warpcall
        ld      hl,myflags
        set     5,(hl)
.nodef
        ld      hl,myflags
        res     2,(hl)
        jp      introscreen

.defintro
        defb    1,'3','@',33+3,33
        defm    "ENTER KEY FOR:"
        defb    1,'3','@',33+5,35,0

.deftext
        defm    "LEFT....\x00"
        defm    "RIGHT...\x00"
        defm    "JUMP....\x00"
        defm    "PAUSE...\x00"

.redefsetup
        call    windclr
        ld      hl,defintro
        call_oz(gn_sop)
        ld      hl,(redefpos)
        call_oz(gn_sop)
        ret


;Make this introsetup!

.introsetup
        call    title_Scrcpy
        call    windclr
        call    cls
        ld      bc,$2326
        ld      (iy+$01),$47
        call    printtext
        defm    "Press \x01R\x01FJUMP\x01F\x01R to start"
        defb    '!'+128
        ld      bc,$2423
        call    printtext
        defm    "(Press \x01RR\x01R to redefine keys"
        defb    ')'+128

        ld      bc,$2023
        call    printtext
        defm    "Written by Stephen Cargil"
        defb    'l'+128

        ld      bc,$2122
        call    printtext
        defm    "Converted to z88 by D Morri"
        defb    's'+128
        ld      a,1
        dec     a
        ret





;Blah, blah, blah...oz routines!!!


;Sort of strange warping sound
;Rising and falling..
          
.warpcall
          ld    hl,1600  
          ld    (snd_wkspc+5),hl
          ld    hl,-800  
          ld    (snd_wkspc+1),hl
          ld    hl,-100  
          ld    (snd_wkspc+3),hl
          ld   b,20
.warpcall1
          push bc
          call warps
          pop  bc
          djnz warpcall1
          ret   
          
.warps    ld    hl,(snd_wkspc+5)
          ld    de,6  
          call  beeper  
.warps1   ld    hl,(snd_wkspc+1)
.warps2   ld    de,(snd_wkspc+3)
          and   a  
          sbc   hl,de  
          ld    (snd_wkspc+1),hl
          jr    nz,warps3  
          ld    de,100  
          ld    (snd_wkspc+3),de
.warps3   ex    de,hl  
          ld    hl,1600  
          add   hl,de  
          ld    (snd_wkspc+5),hl
          ret   
          



;Make a beep (use for key define!)


.soundfx3
        ld      a,(myflags)
        rrca
        ret     c
        call  oz_di    
          push af
          ld   a,($4B0)
          and  63
          ld   ($4B0),a
          out  ($B0),a
          ld    e,150  
.fx2_1    out   ($B0),a  
          xor   64  
          ld    b,e  
.fx2_2    djnz  fx2_2  
          inc   e  
          jr    nz,fx2_1  
          pop  af
          call  oz_ei    
          ret   


;Check to see if sound is working...


.cksound
     ld   de,myworksp
     ld   bc,pa_snd
     ld   a,1
     call_oz(os_nq)
     ld   hl,myflags
     res  0,(hl)
     ld   a,(myworksp)
     cp   'N'
     ret  nz
     set  0,(hl)
     ret




;Handle the title screen

.title_Scrcpy
        ld      hl,title_store
        ld      de,screen
        ld      bc,2048
        ldir
        call    screen
        ld      hl,myflags
        res     3,(hl)
        res     4,(hl)
        xor     a
        ld      (varbase+$81),a       ;lancelot y position
        call    ozscrcpy
        ret
        



.oz_init

;Do OZ stuff now..
          ld   hl,baswindres
          call_oz(gn_sop)
;Now, find address of sbr...tricky!
        call    windsetup
;        xor     a
;        ld      (sbrbank),a
;        ld      b,0
;        ld      hl,0
;        ld      a,sc_sbr
;        call_oz(os_sci)
;        jr      c,nosbr
;        push    bc
;        push    hl
;        ld      a,sc_sbr
;        call_oz(os_sci)
;        pop     hl
;        pop     bc
;        ld      a,b

        ld      a,$21
        ld      (sbrbank),a
;        ld      a,h
;        and     63
;        or      128
;        ld      h,a
        ld      hl,$7800+16384
        ld      (sbraddr),hl
.nosbr
;        call    windsetup
;Copy data downwards..
        ld      hl,defkeys
        ld      de,pkeys
        ld      bc,8+13
        ldir
;        ld      hl,udgdefault
;        ld      de,udgdeft
;        ld      bc,14
;        ldir
        ld      hl,stored_dat
        ld      de,varbase+$80
        ld      bc,136
        ldir                    ;Copy the data which was below code back
        ret


.windsetup
          ld   hl,windini
          call_oz(gn_sop)
          ld   a,'5'       ;window number - ignored!
          ld   bc,mp_gra
          ld   hl,255
          call_oz(os_map)          ; create map width of 256 pixels
          ld   b,0
          ld   hl,0                ; dummy address
          ld   a,sc_hr0
          call_oz(os_sci)          ; get base address of map area (hires0)
          push bc
          push hl
          call_oz(os_sci)          ; (and re-write original address)
          pop  hl
          pop  bc
          ld   a,b
          ld   (ozbank),a
          ld   a,h
          and  63                  ;mask to bank
          or   128                 ;mask to segment 3 (49152)
          ld   h,a
          ld   (ozaddr),hl
          ret

        

.cheatkey
        defb    61,44,38,10



.doposnt
     defb 1,'3','@',0

.baswindres
;          defm ""&1&"2H1"&$0C&$0

.clrscr
        defb    1,'7','#','3',32,32,32+94,32+8,128,1,'2','C','3',0
          
.windini
          defb   1,'7','#','3',32+7,32+1,32+34,32+7,131     ;dialogue box
          defb   1,'2','C','3',1,'4','+','T','U','R',1,'2','J','C'
          defb   1,'3','@',32,32  ;reset to (0,0)
          defm   "Sir Lancelot z88"
          defb   1,'3','@',32,32 ,1,'2','A',32+34  ;keep settings for 10
          defb   1,'7','#','3',32+8,32+3,32+32,32+5,128     ;dialogue box
          defb   1,'2','C','3'
          defb   1,'3','@',32,32,1,'2','+','B'
          defb   0
          defm "Converted by D Morris 14/8/98"
          defm "                "

IF !BASIC
.nomemory
        defb    1,'3','@',32,32,1,'2','J','C'
        defm    "Not enough memory allocated to run Sir Lancelot z88"
        defb    13,13
        defm    "Sorry, please try again later!"
        defb    0

.need_expanded
        
        defb    1,'3','@',32,32,1,'2','J','C'
        defm    "Sorry, Sir Lancelot needs an expanded machine"
        defb    13,13
        defm    "Try again when you have expanded your machine"
        defb    0

.applname
        defm    "Sir Lancelot\x00"
ENDIF


.windclr
          ld   hl,windclrt
          call_oz(gn_sop)
          ret


.windclrt
	  defb 1
          defm "2C3\x012+B"
	  defb	0

.errhant
        defb    1,'2','?',0


;Player keys..to be defined!!
;left, right, jump, pause, quit, mini screen, inv toggle,redefine
;0,  ,1         2       3     4  5  (tab)          6            7
.defkeys
        defb    61,59,10,39,16,17,7,29


.udgdefault
        defb    1,138,'='
        defs    10




;some nice variables all nicely deffed up!

DEFVARS  myvarstore
{
        sbrbank         ds.b  1
        sbraddr         ds.w  1
        objtable        ds.w  8         ;holds addy of objects
        obou            ds.b  1         ;old error handler!
        oerr            ds.w  1
;Data for lives indicator
        livedir         ds.b  1
        livex           ds.b  1
        livew           ds.b  1
        liveanim        ds.b  1
        ozbank          ds.b  1
        ozaddr          ds.w  1
        dotemp          ds.b  1
        mysound         ds.b  1
        myflags         ds.b  1
        flashb          ds.b  1
        redefpos        ds.w  1
        progstk         ds.w  1
        myworksp        ds.w  1
        pkeys           ds.b  8
        udgdeft         ds.b  3         ;for defining udgs..
        udg2            ds.b  10
        snd_wkspc       ds.b  7

}

.end


