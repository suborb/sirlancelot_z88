;Miscellaneous OZ routines for applications

                MODULE  miscoz

                INCLUDE "stdio.def"
                INCLUDE "director.def"

                XDEF    ozread
                XREF    myflags
                XREF    redefine


.ozread
        ld      bc,0
        call_oz(os_tin)
        ret     c
        and     a
        ret     nz
        ld      bc,0
        call_oz(os_tin)
        and     a
        ret     z
;Deal with command a..for now, just ret
        ld      hl,myflags
        sub     $80
        jr      nz,oz_notq
;Quit
        xor     a
        call_oz(os_bye)
.oz_notq
        dec     a               ;$81
        jr      nz,oz_notsize
        bit     1,(hl)
        ret     nz
        ld      a,(hl)
        xor     8
        ld      (hl),a
.oz_notsize
        dec     a               ;$82
        dec     a               ;$83 - redefine keys..
        jr      nz,oz_notredef
        bit     1,(hl)
        ret     z
        bit     2,(hl)
        ret     nz
        jp      redefine

.oz_notredef
        dec     a
        dec     a               ;$85 - inverse
        ret     nz
        bit     1,(hl)
        ret     nz
        ld      a,(hl)
        xor     16
        ld      (hl),a
        ret


