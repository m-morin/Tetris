IDEAL
MODEL   TINY,PASCAL
JUMPS
LOCALS  __
P8086

DATASEG
VIDMEM  equ     0B800h
B       equ     219

BLACK   equ     0
BLUE    equ     1
GREEN   equ     2
CYAN    equ     3
RED     equ     4
MAGENT  equ     5
BROWN   equ     6
WHITE   equ     7
GREY    equ     8
BBLUE   equ     9
BGREEN  equ     10
BRED    equ     11
BCYAN   equ     12
BMAGENT equ     13
BBROWN  equ     14
BWHITE  equ     15

BRDCOL  equ     RED

SWIDTH  equ     40
SHEIGHT equ     25

BWIDTH  equ     10
BHEIGHT equ     20
BRDX    equ     ((SWIDTH - BWIDTH) / 2)
BRDY    equ     ((SHEIGHT - BHEIGHT) / 2)

NPIECES equ     7
piece_i db      00001111b, 00000000b
        db      00100010b, 00100010b
        db      00000000b, 11110000b
        db      01000100b, 01000100b
piece_j db      10001110b, 00000000b
        db      01100010b, 00100000b
        db      00001110b, 00100000b
        db      01000100b, 11000000b
piece_l db      00101110b, 00000000b
        db      01000100b, 01100000b
        db      00001110b, 10000000b
        db      11000100b, 01000000b
piece_o db      01100110b, 00000000b
        db      01100110b, 00000000b
        db      01100110b, 00000000b
        db      01100110b, 00000000b
piece_s db      01101100b, 00000000b
        db      01001100b, 10000000b
        db      00000110b, 11000000b
        db      10001100b, 01000000b
piece_t db      01001110b, 00000000b
        db      01000110b, 01000000b
        db      00001110b, 01000000b
        db      01001100b, 01000000b
piece_z db      11000110b, 00000000b
        db      00100110b, 01000000b
        db      00001100b, 01100000b
        db      01001100b, 10000000b

CODESEG
STARTUPCODE
PROC    main
        mov     ax,VIDMEM
        mov     es,ax
        call    clear_screen
        call    draw_border
        ;TEST: draw piece
        mov     dh,3
        mov     dl,4
        mov     si,offset piece_l
        mov     bx,offset draw_piece
        call    foreach_piece
        mov     ah,0
        int     16h
        call    reset_screen
        mov     ax,04C00h
        int     21h
ENDP    main


PROC    clear_screen
USES    ax,bx,dx
        ;set video mode
        mov     ax,00000h
        int     10h
        ;hide cursor
        mov     ah,002h
        xor     bx,bx
        mov     dx,(SHEIGHT + 1) SHL 8
        int     10h
        ret
ENDP    clear_screen


PROC    reset_screen
USES    ax
        mov     ax,00003h
        int     10h
        ret
ENDP    reset_screen


PROC    draw_border
        mov     ax,(BRDCOL SHL 8) OR B
        ;top
        mov     di,(BRDY-1)*SWIDTH*2 + (BRDX-1)*2
        mov     cx,BWIDTH+2
        rep     stosw
        ;bottom
        mov     di,(BRDY+BHEIGHT)*SWIDTH*2 + (BRDX-1)*2
        mov     cx,BWIDTH+2
        rep     stosw
        ;sides
        mov     cx,BHEIGHT
        mov     di,BRDY*SWIDTH*2 + (BRDX-1)*2
__10:   mov     [word ptr es:di],ax
        mov     [word ptr es:di + (BWIDTH+1)*2],ax
        add     di,SWIDTH*2
        loop    __10
        ret
ENDP    draw_border


;Parameters:
;       dh=y, dl=x in board coordinates
;       si=piece
;       bx=func
PROC    foreach_piece
USES    ax,cx,si,di
        add     dh,BRDY
        add     dl,BRDX 
        ;multiply y by 80, which is SWIDTH * 2
        xor     ch,ch
        mov     cl,dh
        shl     cx,4
        mov     di,cx
        shl     cx,2
        add     di,cx
        ;multiply x by 2
        xor     ch,ch
        mov     cl,dl
        shl     cx,1
        add     di,cx
        ;iterate over the piece
        mov     ch,2
__10:   lodsb
        mov     cl,8
__20:   shl     al,1
        jnc     SHORT __30
        call    bx
__30:   add     di,2
        dec     cl
        test    cl,003h
        jnz     SHORT __40
        add     di,(SWIDTH-4)*2
__40:   cmp     cl,0
        jnz     SHORT __20
        sub     ch,1
        jnz     SHORT __10
        ret
ENDP    foreach_piece

PROC    draw_piece
        mov     [word ptr es:di],(GREEN SHL 8) OR 178
        ret
ENDP    draw_piece

END
