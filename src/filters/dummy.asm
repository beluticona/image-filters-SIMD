%macro  newFilterAsm 1
extern %1_c
global %1_asm
%1_asm:
jmp %1_c
%endmacro 

newFilterAsm edgeSobel
newFilterAsm tresColores
newFilterAsm efectoBayer
newFilterAsm cambiaColor
