; ROM header

	org	65472


; 19 bytes
.frontdor
        defb    0,0,0           ;link to parent
        defb    0,0,0           ;link to help
        defw    53000-49152     ;link to first app
        defb    $3F             ;bank
        defb    $13             ;ROM front DOR
        defb    8               ;DOR length
        defb    'N'             ;key for name field
        defb    5               ;name length
        defm    "APPL\x00"
        defb    $FF
        defs    37              ;blanks..fill out space!

; 8 bytes
.eprom_header
        defw    5687             ;card ID
        defb    5               ;country code
        defb    80
        defb    2               ;card size
        defb    0
        defm    "OZ"

.EpromTop



