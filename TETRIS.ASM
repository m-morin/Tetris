INCLUDE COMMON.INC

;****************
;***** Data *****
;****************
DATASEG
speed           dw      ?
fall            dw      0

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
                mov     bh,0
                mov     bl,[byte ptr keys+SCAN_DOWN]
                call    vid_debug_print
                cmp     [byte ptr keys+SCAN_ESCAPE],1
                je      __done
__up:           cmp     [byte ptr keys+SCAN_UP],1
                jne     __left
                mov     [byte ptr keys+SCAN_UP],0
                mov     cx,2
                xor     dx,dx
                call    piece_try_move
                jmp     __draw
__left:         cmp     [byte ptr keys+SCAN_LEFT],1
                jne     __right
                mov     [byte ptr keys+SCAN_LEFT],0
                mov     dh,0
                mov     dl,-1
                xor     cx,cx
                call    piece_try_move
                jmp     __draw
__right:        cmp     [byte ptr keys+SCAN_RIGHT],1
                jne     __fall
                mov     [byte ptr keys+SCAN_RIGHT],0
                mov     dh,0
                mov     dl,1
                xor     cx,cx
                call    piece_try_move
                jmp     __draw
__fall:         mov     ax,[word ptr fall]
                inc     ax
                mov     [word ptr fall],ax
                cmp     [byte ptr keys+SCAN_DOWN],1
                jne     __fall2
                shl     ax,3
__fall2:        cmp     ax,[word ptr speed]
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
                call    delete_full_rows
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

;delete full rows starting from the
;y position of the current piece downward
;a maximum of 4
PROC            delete_full_rows
USES            ax,bx,cx,dx,si,di
                xor     dl,dl
                mov     dh,[cur_pc.y]
                mov     cx,4
                call    piece_to_screen
                mov     si,dx
__loop1:        mov     dx,cx
                mov     cx,BWIDTH
                xor     bx,bx
__loop2:        cmp     [byte ptr es:si + bx],B
                jne     __loop1e
                add     bx,2
                loop    __loop2
                call    shift_down
__loop1e:       mov     cx,dx
                add     si,SWIDTH * 2
                cmp     si,(BRDY + BHEIGHT) * SWIDTH * 2
                jae     __ret
                loop    __loop1
__ret:          ret
ENDP            delete_full_rows

;shift the entire board down starting at si
PROC            shift_down
USES            cx,si,di,ds
                mov     cx,es
                mov     ds,cx
__loop:         mov     di,si
                sub     si,SWIDTH * 2
                cmp     si,BRDY * SWIDTH * 2
                jl      __ret
                mov     cx,BWIDTH
                push    si
                rep     movsw
                pop     si
                jmp     __loop
__ret:          ret
ENDP

END
