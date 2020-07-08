INCLUDE COMMON.INC

KBDPORT         equ     060h

DATASEG
oldkb           dd      ?
keys            db      128 dup(?)

CODESEG
PROC            key_install
USES            ax,bx,dx,es
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
ENDP            key_install

PROC            key_uninstall
USES            ax,dx,ds
                ;install old handler
                mov     ax,02509h
                mov     dx,[word ptr oldkb]
                mov     ds,[word ptr oldkb+2]
                int     21h
                ret
ENDP            key_uninstall

PROC            keyboard
                pushall
                mov     ax,cs
                mov     ds,ax
                ;scancode in al
                in      al,060h
                ;register with keys array
                xor     bx,bx
                mov     bl,al
                and     bl,07Fh
                mov     ah,al
                not     ah
                rcl     ah,1
                mov     ah,0
                rcl     ah,1
                mov     [byte ptr keys+bx],ah
                ;process keypresses
                in      al,061h
                or      al,080h
                out     061h,al
                and     al,07Fh
                out     061h,al
                mov     al,020h
                out     020h,al
                popall
                iret
ENDP
END
