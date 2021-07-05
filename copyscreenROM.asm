;Copy a screen from 16384 to OZ Map
;Needs to be reworked for each game..
;Rewriting so can ROM it..


                MODULE  screen

                INCLUDE "interrpt.def"


                XREF    cksound
                XREF    myflags
                XREF    varbase
                XREF    ozbank
                XREF    ozaddr
                XREF    screen

                XDEF    ozscrcpy
                XDEF    ozscrcpy_noc

;Myflags
;bit 0 = sound on/off
;bit 1 = game/intro
;bit 2 = standard/define keys
;bit 3 = resoluion
;bit 4 = inverse
;bit 5 = cheat on/off
;bit 6 = referred to by lives
;bit 7 = on/off flag

          
.ozscrcpy
        call    cksound         ;might as well do it here!
.ozscrcpy_noc  
        ld      hl,$4D2
        ld      a,(hl)
        push    af
        ld      a,(ozbank)
        ld      (hl),a
        out     ($D2),a
          ld   de,ozfullcpy
          ld   a,(myflags)
          bit   3,a              ;bit 3
          jr   z,ozskhalf
          ld   de,ozhalfcpy
.ozskhalf
          exx
          ld    c,0
          bit   4,a
          jr    z,ozskinv
          ld    c,255
.ozskinv
          ld   hl,(ozaddr)
          exx
          call oz_di
          push af
          call ozcallch
          pop  af
          call oz_ei
          pop   af
          ld  ($4D2),a
          out ($D2),a
          ret

.ozcallch
          push de
          ret

.ozfullcpy
        ld  a,(varbase+$81)      ;23425 (pixel line)
        rrca
        rrca
        rrca
        and     15
          cp   12
          jr   c,scrcpya
          ld   a,11
.scrcpya  sub  3
          jr   nc,scrcpy0
          xor  a
.scrcpy0  ld   b,a
          ld   c,8
.scrcpy1  push bc
          ld   a,b
          and  248
          add  a,screen/256
          ld   d,a
          ld   a,b
          and  7
          rrca
          rrca
          rrca
          ld   e,a
;OZ screen is handled like characters..grrr!
          ld   c,32
.scrcpy2
          ld   b,8
          push de
.scrcpy3  ld   a,(de)
          exx
          xor   c
          ld    (hl),a
          inc   hl
          exx
          inc  d
          djnz scrcpy3
          pop  de
          inc  e
          dec  c
          jp   nz,scrcpy2

          pop  bc
          inc  b
.scrcpy36 ex   af,af
          dec  c
          jp   nz,scrcpy1
          ret


;Screen copy for half size

.ozhalfcpy
          ld   de,screen
.ozhalfcpy1
          ld   b,4
.ozhalfcpy2
          ld   a,(de)
          exx
          xor   c
          ld    (hl),a
          inc   hl
          exx
          inc  d
          inc  d
          djnz ozhalfcpy2
          ld   a,d
          sub  8
          ld   d,a
          ld   a,e
          add  a,32
          ld   e,a
          ld   b,4
.ozhalfcpy3
          ld   a,(de)
          exx
          xor   c
          ld   (hl),a
          inc  hl
          exx
          inc  d
          inc  d
          djnz ozhalfcpy3
          ld   a,d
          sub  8
          ld   d,a
          ld   a,e
          sub  31
          ld   e,a
          and  31
          jp   nz,ozhalfcpy1
          ld   a,e
          add  a,32
          ld   e,a
          and  a
          jp   nz,ozhalfcpy1
          ld   a,d
          add  a,8
          ld   d,a
          cp   32+16
          jp   c,ozhalfcpy1
          ret

;The ROMable screen copy!
;Could have sort of scam where we 
;Do the screen in two bits..
;Invert flag will be held in alternate register and XOR done

.docopy


;Will copy a row onto the map (either 
;Entry:  c = number of lines to copy (4/8)
;       de = addy in map
;       hl = bytes to skip at end of cell (4/0)
;       hl'= screen address
;        c = invert mask (0/255)
;        e = line skip (1/2)


.docopy_l0
        ld      b,c
        push    hl
.docopy_l1
        exx
        ld      d,(hl)
        ld      a,h
        add     a,e     ;e=1/2
        ld      h,a
        ld      a,d
        xor     c
        exx
        ld      (de),a
        inc     de
        djnz    docopy_l1
        ex      de,hl   ;hl=4/0
        add     hl,de   
        ex      de,hl
        exx
        pop     hl
        inc     l
        jr      nz,docopy_l0





