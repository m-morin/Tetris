T=TETRIS

.OBJ.ASM:
  TASM $**

$T.COM: $T.OBJ
  TLINK/t $**

RUN: $T.COM
  $T
