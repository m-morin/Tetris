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
pieces  db      0E4h, 0E2h, 0C6h, 0CCh, 06Ch, 0E8h, 0F0h

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
        mov     si,offset pieces
        mov     ah,GREEN
        mov     bh,1
        call    draw_piece
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
;       ah=color
;       bh=1 - draw, bh=0 - erase
PROC    draw_piece
USES    ax,bx,cx,dx,si,di
        add     dh,BRDY
        add     dl,BRDX 
        ;multiply y by 80, which is SWIDHT * 2
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
        ;TEST: put a single block
        mov     al,B
        mov     [word ptr es:di],ax
        ret
ENDP    draw_piece

END
