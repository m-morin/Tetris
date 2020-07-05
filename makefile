T=TETRIS

.ASM.OBJ:
  TASM/l $**

$T.COM: $T.OBJ
  TLINK/t $**

RUN: $T.COM
  $T

CLEAN:
  del *.obj
  del $T.com
