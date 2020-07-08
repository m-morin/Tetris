INCLUDE COMMON.INC

VIDMEM          equ     0B800h

CODESEG
PROC            vid_sync
USES            ax,dx
                mov     dx,003DAh
__10:           in      al,dx
                test    al,8
                jz      __10
__20:           in      al,dx
                test    al,8
                jnz     __20
                ret
ENDP            vid_sync

PROC            vid_init
USES            ax,bx,dx
                mov     ax,VIDMEM
                mov     es,ax
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
ENDP            vid_init

PROC            vid_reset
USES            ax
                mov     ax,00003h
                int     10h
                ret
ENDP            vid_reset

PROC            vid_draw_border
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
__10:           mov     [word ptr es:di],ax
                mov     [word ptr es:di + (BWIDTH+1)*2],ax
                add     di,SWIDTH*2
                loop    __10
                ret
ENDP            vid_draw_border
END
