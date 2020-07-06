IDEAL
MODEL   TINY,PASCAL
JUMPS
LOCALS  __
P8086


STRUC   Piece
offs    dw      ?
rot     dw      ?
x       db      ?
y       db      ?
color   db      ?
pad     db      ?
ENDS    Piece

MACRO   pushall
        push    ax
        push    cx
        push    dx
        push    bx
        push    sp
        push    bp
        push    si
        push    di
ENDM    pushall

MACRO   popall
        pop     di
        pop     si
        pop     bp
        pop     sp
        pop     bx
        pop     dx
        pop     cx
        pop     ax
ENDM    popall

DATASEG
VIDMEM  equ     0B800h
B       equ     219

KBDPORT equ     060h
ESCAPE  equ     1
UP      equ     72
DOWN    equ     80
LEFT    equ     75
RIGHT   equ     77

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

cur_pc  Piece   <?>
col_pc  Piece   <?>
collide db      ?

oldkb   dd      ?
key     db      0
hex     db      "0123456789ABCDEF"

CODESEG
STARTUPCODE
PROC    main
        call    install_keyboard
        mov     ax,VIDMEM
        mov     es,ax
        call    clear_screen
        call    draw_border
        ;TEST: setup test piece
        mov     [cur_pc.offs],offset piece_t
        mov     [cur_pc.rot],0
        mov     [cur_pc.x],1
        mov     [cur_pc.y],3
        mov     [cur_pc.color],BLUE
        jmp     __draw
__lp:   mov     ah,[byte ptr key]
        cmp     ah,ESCAPE
        je      __done
__up:   cmp     ah,UP
        jne     __left
        mov     [byte ptr key],0
        mov     cx,2
        xor     dx,dx
        call    try_move_piece
        jmp     __draw
__left: cmp     ah,LEFT
        jne     __right
        mov     [byte ptr key],0
        mov     dh,0
        mov     dl,-1
        xor     cx,cx
        call    try_move_piece
        jmp     __draw
__right:cmp     ah,RIGHT
        jne     __lp
        mov     [byte ptr key],0
        mov     dh,0
        mov     dl,1
        xor     cx,cx
        call    try_move_piece
        jmp    __draw
__draw: ;draw piece
        mov     si,offset cur_pc
        mov     bx,offset draw_piece
        call    foreach_piece
        jmp     __lp
__done: call    reset_screen
        call    uninstall_keyboard
        mov     ax,04C00h
        int     21h
ENDP    main


PROC    install_keyboard
USES    ax,bx,dx,es
        ;save old handler
        mov     ax,03509h
        int     21h
        mov     [word ptr oldkb],bx
        mov     [word ptr oldkb+2],es
        ;install new handler
        mov     ax,02509h
        mov     dx,OFFSET keyboard
        int     21h
        ret
ENDP    install_keyboard

PROC    uninstall_keyboard
USES    ax,dx,ds
        ;install old handler
        mov     ax,02509h
        mov     dx,[word ptr oldkb]
        mov     ds,[word ptr oldkb+2]
        int     21h
        ret
ENDP    uninstall_keyboard

PROC    keyboard
        pushall
        mov     ax,cs
        mov     ds,ax
        ;process keypresses
        in      al,060h
        test    al,080h
        jnz     __nodwn
        mov     [byte ptr key],al
        ;debug print to screen
        mov     bx,VIDMEM
        mov     es,bx
        mov     ch,RED
        mov     bx,offset hex
        mov     ah,al
        and     al,00Fh
        xlat
        mov     cl,al
        mov     [word ptr es:2],cx
        mov     al,ah
        shr     al,4
        xlat
        mov     cl,al
        mov     [word ptr es:0],cx
__nodwn:in      al,061h
        or      al,080h
        out     061h,al
        and     al,07Fh
        out     061h,al
        mov     al,020h
        out     020h,al
        popall
        iret
ENDP


PROC    clear_screen
USES    ax,bx,dx
        ;set video mode
        mov     ax,00001h
        int     10h
        ;set 200 scanlines
        mov     ax,01200h
        mov     bl,003h
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


;Try to move a piece, don't move if it collides
;Erases piece from board first
;Parameters:    dh=deltay, dl=deltax
;               cx=rotation
PROC    try_move_piece
USES    si,di,ax,bx,cx
        ;copy current piece to collision piece
        mov     ax,[word ptr cur_pc]
        mov     [word ptr col_pc],ax
        mov     ax,[word ptr cur_pc + 2]
        mov     [word ptr col_pc + 2],ax
        mov     ax,[word ptr cur_pc + 4]
        mov     [word ptr col_pc + 4],ax
        mov     ax,[word ptr cur_pc + 6]
        mov     [word ptr col_pc + 6],ax
        ;move collision piece
        add     [col_pc.y],dh
        add     [col_pc.x],dl
        add     [col_pc.rot],cx
        ;add    [word ptr col_pc.y],dx
        ;erase piece from screen
        mov     bx,offset erase_piece
        mov     si,offset cur_pc
        call    foreach_piece
        ;test for collision
        mov     [byte ptr collide],0
        mov     bx,offset collide_piece
        mov     si,offset col_pc
        call    foreach_piece
        cmp     [byte ptr collide],0
        jne     __ret
        ;copy moved piece to current piece
        mov     ax,[word ptr col_pc]
        mov     [word ptr cur_pc],ax
        mov     ax,[word ptr col_pc + 2]
        mov     [word ptr cur_pc + 2],ax
        mov     ax,[word ptr col_pc + 4]
        mov     [word ptr cur_pc + 4],ax
        mov     ax,[word ptr col_pc + 6]
        mov     [word ptr cur_pc + 6],ax
__ret:  ret
ENDP    try_move_piece


;Parameters:
;       si=piece
;       bx=func
PROC    foreach_piece
USES    ax,cx,si,di
        ;place piece on board
        mov     dh,[(Piece ptr si).y]
        mov     dl,[(Piece ptr si).x]
        add     dh,BRDY
        add     dl,BRDX 
        ;get offset to piece data
        mov     ax,[(Piece ptr si).offs]
        mov     cx,[(Piece ptr si).rot]
        and     cx,00007h
        add     ax,cx
        mov     si,ax
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
USES    ax
        mov     ah,[cur_pc.color]
        mov     al,B
        mov     [word ptr es:di],ax
        ret
ENDP    draw_piece


PROC    erase_piece
        mov     [word ptr es:di],00020h
        ret
ENDP    erase_piece


PROC    collide_piece
        cmp     [byte ptr es:di],B
        jne     __ret
        inc     [byte ptr collide]
__ret:  ret
ENDP    collide_piece


END
