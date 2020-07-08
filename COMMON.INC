IDEAL
MODEL TINY,PASCAL
JUMPS
LOCALS __
P8086

;*****************
;***** Types *****
;*****************
STRUC           Piece
offs            dw      ?
rot             dw      ?
x               db      ?
y               db      ?
color           db      ?
pad             db      ?
ENDS            Piece

;******************
;***** Macros *****
;******************
MACRO           pushall
                push    ax
                push    cx
                push    dx
                push    bx
                push    sp
                push    bp
                push    si
                push    di
ENDM            pushall

MACRO           popall
                pop     di
                pop     si
                pop     bp
                pop     sp
                pop     bx
                pop     dx
                pop     cx
                pop     ax
ENDM            popall

;*********************
;***** Constants *****
;*********************
B               equ     219

KBDPORT         equ     060h
ESCAPE          equ     1
UP              equ     72
DOWN            equ     80
LEFT            equ     75
RIGHT           equ     77

BLACK           equ     0
BLUE            equ     1
GREEN           equ     2
CYAN            equ     3
RED             equ     4
MAGENT          equ     5
BROWN           equ     6
WHITE           equ     7
GREY            equ     8
BBLUE           equ     9
BGREEN          equ     10
BRED            equ     11
BCYAN           equ     12
BMAGENT         equ     13
BBROWN          equ     14
BWHITE          equ     15

BRDCOL          equ     RED

SWIDTH          equ     40
SHEIGHT         equ     25

BWIDTH          equ     10
BHEIGHT         equ     20
BRDX            equ     ((SWIDTH - BWIDTH) / 2)
BRDY            equ     ((SHEIGHT - BHEIGHT) / 2)

NPIECES         equ     7
PCLEN           equ     8

SPAWNX          equ     4
SPAWNY          equ     0
NPCCOLS         equ     4
STSPEED         equ     20

;****************
;***** Code *****
;****************
CODESEG
GLOBAL          rand_seed:PROC
GLOBAL          rand:PROC

GLOBAL          key_install:PROC
GLOBAL          key_uninstall:PROC

GLOBAL          vid_sync:PROC
GLOBAL          vid_init:PROC
GLOBAL          vid_reset:PROC
GLOBAL          vid_draw_border:PROC

GLOBAL          piece_try_move:PROC
GLOBAL          piece_foreach:PROC
GLOBAL          piece_draw:PROC
GLOBAL          piece_erase:PROC
GLOBAL          piece_collide:PROC
GLOBAL          piece_spawn:PROC

;****************
;***** Data *****
;****************
DATASEG
GLOBAL          key:byte

GLOBAL          pieces
GLOBAL          cur_pc:Piece
GLOBAL          col_pc:Piece
GLOBAL          collide:byte
