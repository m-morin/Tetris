INCLUDE COMMON.INC

;****************
;***** Data *****
;****************
DATASEG
speed           dw      ?
fall            dw      0

hex             db      "0123456789ABCDEF"

CODESEG
STARTUPCODE
PROC            main
                call    key_install
                call    rand_seed
                mov     [word ptr speed],STSPEED
                call    vid_init
                call    vid_draw_border
                call    piece_spawn
                jmp     __fall
__lp:           call    vid_sync
                mov     ah,[byte ptr key]
                cmp     ah,ESCAPE
                je      __done
__up:           cmp     ah,UP
                jne     __left
                mov     [byte ptr key],0
                mov     cx,2
                xor     dx,dx
                call    piece_try_move
                jmp     __draw
__left:         cmp     ah,LEFT
                jne     __right
                mov     [byte ptr key],0
                mov     dh,0
                mov     dl,-1
                xor     cx,cx
                call    piece_try_move
                jmp     __draw
__right:        cmp     ah,RIGHT
                jne     __fall
                mov     [byte ptr key],0
                mov     dh,0
                mov     dl,1
                xor     cx,cx
                call    piece_try_move
                jmp     __draw
__fall:         mov     ax,[word ptr fall]
                inc     ax
                mov     [word ptr fall],ax
                cmp     ax,[word ptr speed]
                jb      __draw
                mov     [word ptr fall],0
                mov     dx,00100h
                xor     cx,cx
                call    piece_try_move
                cmp     [byte ptr collide],0
                je      __draw
                mov     si,OFFSET cur_pc
                mov     bx,OFFSET piece_draw
                call    piece_foreach
                call    piece_spawn
__draw:         ;draw piece
                mov     si,OFFSET cur_pc
                mov     bx,OFFSET piece_draw
                call    piece_foreach
                jmp     __lp
__done:         call    vid_reset
                call    key_uninstall
                mov     ax,04C00h
                int     21h
ENDP            main
END
