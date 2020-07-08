INCLUDE COMMON.INC

DATASEG
prng            dw      ?

CODESEG
PROC            rand_seed
USES            ax,cx,dx
                xor     ax,ax
                int     01Ah
                mov     [word ptr prng],dx
                ret
ENDP            rand_seed

PROC            rand
USES            bx
                mov     ax,[word ptr prng]
                mov     bx,ax
                shl     bx,7
                xor     ax,bx
                mov     bx,ax
                shr     bx,9
                xor     ax,bx
                xor     ah,al
                mov     [word ptr prng],ax
                ret
ENDP            rand
END
