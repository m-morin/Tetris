INCLUDE COMMON.INC

DATASEG
LABEL           pieces
piece_i         db      00001111b, 00000000b
                db      00100010b, 00100010b
                db      00000000b, 11110000b
                db      01000100b, 01000100b
piece_j         db      10001110b, 00000000b
                db      01100010b, 00100000b
                db      00001110b, 00100000b
                db      01000100b, 11000000b
piece_l         db      00101110b, 00000000b
                db      01000100b, 01100000b
                db      00001110b, 10000000b
                db      11000100b, 01000000b
piece_o         db      01100110b, 00000000b
                db      01100110b, 00000000b
                db      01100110b, 00000000b
                db      01100110b, 00000000b
piece_s         db      01101100b, 00000000b
                db      01000110b, 00100000b
                db      00000110b, 11000000b
                db      10001100b, 01000000b
piece_t         db      01001110b, 00000000b
                db      01000110b, 01000000b
                db      00001110b, 01000000b
                db      01001100b, 01000000b
piece_z         db      11000110b, 00000000b
                db      00100110b, 01000000b
                db      00001100b, 01100000b
                db      01001100b, 10000000b
pccols          db      BLUE, GREEN, CYAN, RED

cur_pc          Piece   <?>
col_pc          Piece   <?>
collide         db      ?

CODESEG
;Try to move a piece, don't move if it collides
;Erases piece from board first
;Parameters:    dh=deltay, dl=deltax
;               cx=rotation
PROC            piece_try_move
USES            si,di,ax,bx,cx
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
                ;erase piece from screen
                mov     bx,offset piece_erase
                mov     si,offset cur_pc
                call    piece_foreach
                ;test for collision
                mov     [byte ptr collide],0
                mov     bx,offset piece_collide
                mov     si,offset col_pc
                call    piece_foreach
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
__ret:          ret
ENDP            piece_try_move


;Parameters:
;       si=piece
;       bx=func
PROC            piece_foreach
USES            ax,cx,si,di
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
__10:           lodsb
                mov     cl,8
__20:           shl     al,1
                jnc     SHORT __30
                call    bx
__30:           add     di,2
                dec     cl
                test    cl,003h
                jnz     SHORT __40
                add     di,(SWIDTH-4)*2
__40:           cmp     cl,0
                jnz     SHORT __20
                sub     ch,1
                jnz     SHORT __10
                ret
ENDP            piece_foreach


PROC            piece_draw
USES            ax
                mov     ah,[cur_pc.color]
                mov     al,B
                mov     [word ptr es:di],ax
                ret
ENDP            piece_draw


PROC            piece_erase
                mov     [word ptr es:di],00020h
                ret
ENDP            piece_erase


PROC            piece_collide
                cmp     [byte ptr es:di],B
                jne     __ret
                inc     [byte ptr collide]
__ret:          ret
ENDP            piece_collide


PROC            piece_spawn
USES            ax,bx
                ;get number from 0 to NPIECES (7)
                call    rand
                and     ax,00007h
                cmp     ax,NPIECES
                jl      __10
                dec     ax
__10:           ;convert to offset
                shl     ax,3
                add     ax,OFFSET pieces
                ;spawn piece
                mov     [cur_pc.offs],ax
                mov     [cur_pc.rot],0
                mov     [cur_pc.x],SPAWNX
                mov     [cur_pc.y],SPAWNY
                ;generate random color
                call    rand
                and     ax,00003h
                mov     bx,ax
                mov     al,[byte ptr pccols+bx]
                mov     [cur_pc.color],al
                ret
ENDP            piece_spawn
END
