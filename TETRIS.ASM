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
PCLEN   equ     8
LABEL   pieces
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

NPCCOLS equ     4
pccols  db      BLUE, GREEN, CYAN, RED

SPAWNX  equ     4
SPAWNY  equ     0
cur_pc  Piece   <?>
col_pc  Piece   <?>
collide db      ?
fall    dw      ?

STSPEED equ     10
speed   dw      ?
oldkb   dd      ?
key     db      0
oldtmr  dd      ?
ticks   dw      0
hex     db      "0123456789ABCDEF"
prng    dw      ?

CODESEG
STARTUPCODE
PROC    main
        call    install_keyboard
        call    install_timer
        call    prng_seed
        mov     [word ptr speed],STSPEED
        mov     ax,VIDMEM
        mov     es,ax
        call    clear_screen
        call    draw_border
        call    spawn_piece
        jmp     __fall
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
        jne     __fall
        mov     [byte ptr key],0
        mov     dh,0
        mov     dl,1
        xor     cx,cx
        call    try_move_piece
        jmp     __draw
__fall: mov     ax,[word ptr ticks]
        cmp     ax,[word ptr speed]
        jb      __draw
        mov     [word ptr ticks],0
        mov     dh,1
        mov     dl,0
        xor     cx,cx
        call    try_move_piece
__draw: ;draw piece
        mov     si,offset cur_pc
        mov     bx,offset draw_piece
        call    foreach_piece
        jmp     __lp
__done: call    reset_screen
        call    uninstall_keyboard
        call    uninstall_timer
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


PROC    install_timer
USES    ax,bx,es
        ;save old handler
        mov     ax,03508h
        int     21h
        mov     [word ptr oldtmr],bx
        mov     [word ptr oldtmr+2],es
        ;install new handler
        mov     ax,02508h
        mov     dx,OFFSET timer
        int     21h
        ret
ENDP    install_timer

PROC    uninstall_timer
USES    ax,dx,ds
        mov     ax,02508h
        mov     dx,[word ptr oldtmr]
        mov     ds,[word ptr oldtmr+2]
        int     21h
        ret
ENDP    uninstall_timer

PROC    timer
        pushall
        inc     [word ptr ticks]
        pushf
        call    [cs:oldtmr]
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


PROC    spawn_piece
        ;get number from 0 to NPIECES (7)
        call    prng_rand
        and     ax,00007h
        cmp     ax,NPIECES
        jl      __10
        dec     ax
__10:   ;convert to offset
        shl     ax,3
        add     ax,OFFSET pieces
        ;spawn piece
        mov     [cur_pc.offs],ax
        mov     [cur_pc.rot],0
        mov     [cur_pc.x],SPAWNX
        mov     [cur_pc.y],SPAWNY
        ;generate random color
        call    prng_rand
        and     ax,00003h
        mov     bx,ax
        mov     al,[byte ptr pccols+bx]
        mov     [cur_pc.color],al
        ret
ENDP    spawn_piece


PROC    prng_seed
USES    ax,cx,dx
        xor     ax,ax
        int     01Ah
        mov     [word ptr prng],dx
        ret
ENDP    prng_seed


PROC    prng_rand
USES    bx
        mov     ax,[word ptr prng]
        mov     bx,ax
        shl     bx,7
        xor     ax,bx
        mov     bx,ax
        shl     bx,9
        xor     ax,bx
        mov     bx,ax
        mov     bh,bl
        xor     bl,bl
        xor     ax,bx
        mov     [word ptr prng],ax
        ret
ENDP    prng_rand


END
