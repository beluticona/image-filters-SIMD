align 16
dqword_cuatro_floats_iguales_a_uno: times 4 DD 1.0
dqword_cuatro_floats_iguales_a_512: times 4 DD 512.0

global cambiaColor_asm

%define shift_Bit_1 1
%define shift_Bit_2 2
%define shift_Bit_8 8
%define shift_Bit_9 9
%define shift_Bit_16 16
%define shift_Bit_24 24
%define shift_Bit_32 32
%define shift_Byte_1 1
%define shift_Byte_2 2
%define shift_Byte_3 3
%define shift_Byte_4 4
%define shift_Byte_8 8
%define next_4_pixels 16

cambiaColor_asm:

; RDI = unsigned char *src
; RSI = unsigned char *dst
; EDX = int width
; ECX = int height
; R8D = int src_row_size
; R9D = int dst_row_size

; luego del stack frame
; [RBP+16] = unsigned char _Nr
; [RBP+24] = unsigned char _Ng
; [RBP+32] = unsigned char _Nb
; [RBP+40] = unsigned char _Or
; [RBP+48] = unsigned char _Og
; [RBP+56] = unsigned char _Ob
; [RBP+64] = int _lim

push rbp
mov rbp, rsp

mov eax, r8d
mul ecx			        ; rax = src_row_size * height
lea r8, [rdi + rax]	; r8 = puntero donde cortar el ciclo

mov eax, [rbp+64]

; PREPARO COLOR POR PARÁMETRO CADA UNO EN UN XMM |argb3|argb2|argb1|argb0|
; inserto parámetros en lugar correspondiente 
pxor xmm11, xmm11
pxor xmm12, xmm12
pxor xmm13, xmm13

mov dl, [rbp+40]
pinsrb xmm11, dl, 0 	 ; parámetro red
pinsrb xmm11, dl, 4 	 ; 
pinsrb xmm11, dl, 8 	 ; 
pinsrb xmm11, dl, 12 	 ; xmm11 = |0 0 0 Or|0 0 0 Or|0 0 0 Or|0 0 0 Or| 

mov dl, [rbp+48]
pinsrb xmm12, dl, 0 	 ; parámetro green 
pinsrb xmm12, dl, 4 	 ; 
pinsrb xmm12, dl, 8 	 ; 
pinsrb xmm12, dl, 12 	 ; xmm12 = |0 0 0 Og|0 0 0 Og|0 0 0 Og|0 0 0 Og| 

mov dl, [rbp+56]
pinsrb xmm13, dl, 0 	 ; parámetro blue
pinsrb xmm13, dl, 4 	 ; 
pinsrb xmm13, dl, 8 	 ; 
pinsrb xmm13, dl, 12 	 ; xmm13 = |0 0 0 Ob|0 0 0 Ob|0 0 0 Ob|0 0 0 Ob| 
			
; Comentario de Color: también puedo shiftear y hacer por, chequear al final eficiencia			

; xmm en uso:
; xmm11 = Or3|Or2|Or1|Or0 (int32)
; xmm12 = Og3|Og2|Og1|Og0 (int32)
; xmm13 = Ob3|Ob2|Ob1|Ob0 (int32)

; ------------------------------------------------------------------------------

.ciclo:

; OBTENGO DISTANCIA (d)

; OBTENCIÓN DELTA COLORS
; separo por colores 
movdqu xmm1, [rdi]			; xmm1 = |px3|px2|px1|px0|
movdqu xmm2, xmm1			; xmm2 = |argb3|argb2|argb1|argb0|
movdqu xmm3, xmm1			; xmm3 = |argb3|argb2|argb1|argb0|

; guardo src para retornar
movdqu xmm0, xmm1

;@informe: notar que lo guardo en lugar de volver a buscar datos en memoria

; RED X1
pslld xmm1, shift_Bit_8		; xmm3 = |r3 g3 b3 0|r2 g2 b2 0|r1 g1 b1 0|r0 g0 b0 0|
psrld xmm1, shift_Bit_24		; xmm3 = | 0 0 0 r3|0 0 0 r2|0 0 0 r1|0 0 0 r0| 

; GREEN X2
pslld xmm2, shift_Bit_16		; xmm2 = |g3 b3 0 0|g2 b2 0 0|g1 b1 0 0|g0 b0 0 0|
psrld xmm2, shift_Bit_24		; xmm2 = | 0 0 0 g3|0 0 0 g2|0 0 0 g1|0 0 0 g0| 

; BLUE X3
pslld xmm3, shift_Bit_24		; xmm1 = |b3 0 0 0|b2 0 0 0|b1 0 0 0|b0 0 0 0|
psrld xmm3, shift_Bit_24		; xmm1 = | 0 0 0 b3|0 0 0 b2|0 0 0 b1|0 0 0 b0|

movdqa xmm10, xmm1          ; preservar r
movdqa xmm14, xmm2          ; preservar g
movdqa xmm15, xmm3          ; preservar b

; xmm en uso:
; xmm0  = px3|px2|px1|px0 (int32) con px[i] con formato argb
; xmm11 = Or3|Or2|Or1|Or0 (int32)
; xmm12 = Og3|Og2|Og1|Og0 (int32)
; xmm13 = Ob3|Ob2|Ob1|Ob0 (int32)
; xmm1  =  r3| r2| r1| r0 (int32)
; xmm2  =  g3| g2| g1| g0 (int32)
; xmm3  =  b3| b2| b1| b0 (int32)
; xmm10 =  r3| r2| r1| r0 (int32) - copia para preservar
; xmm14 =  g3| g2| g1| g0 (int32) - copia para preservar
; xmm15 =  b3| b2| b1| b0 (int32) - copia para preservar

; ------------------------------------------------------------------------------ 

; OBTENCIÓN PROMEDIO r
movdqu xmm4, xmm1
paddd xmm4, xmm11			; suma rojo pixel + rojo parámetros
	
; realizo resta
psubd xmm1, xmm11			; X1 = |ΔR3|ΔR2|ΔR1|ΔR0|
psubd xmm2, xmm12			; X2 = |ΔG3|ΔG2|ΔG1|ΔG0|
psubd xmm3, xmm13			; X3 = |ΔB3|ΔB2|ΔB1|ΔB0|

; xmm en uso:
; xmm0  = px3|px2|px1|px0 (int32) con px[i] con formato argb
; xmm11 = Or3|Or2|Or1|Or0 (int32)
; xmm12 = Og3|Og2|Og1|Og0 (int32)
; xmm13 = Ob3|Ob2|Ob1|Ob0 (int32)
; xmm1  = dr3|dr2|dr1|dr0 (int32)
; xmm2  = dg3|dg2|dg1|dg0 (int32)
; xmm3  = db3|db2|db1|db0 (int32)
; xmm4  =  a3| a2| a1| a0 (int32) con a[i] = rr*2
; xmm10 =  r3| r2| r1| r0 (int32)
; xmm14 =  g3| g2| g1| g0 (int32)
; xmm15 =  b3| b2| b1| b0 (int32)

; ------------------------------------------------------------------------------

; OBTENCIÓN DELTA COLORS CUADRADO ( ΔR^2 | ΔG^2 | ΔB^2)
; ROJO		
movdqu xmm5, xmm1
pmuldq xmm1, xmm1		; xmm1 = |0 0 ΔR2*ΔR2|0 0 ΔR0*ΔR0|		PMULDQ: multiplica la primer y la tercer dword
psrldq xmm5, shift_Byte_4			;shiftea todo el registro 4 bytes hacia la derecha |0|ΔR3|ΔR2|ΔR1|
pmuldq xmm5, xmm5		; xmm5 = |0 0 ΔR3*ΔR3|0 0 ΔR1*ΔR1|

; @informe: Δ es de tamaño byte como mucho (trabajo a DW porque son 4 datos por registro), al cuadrado no supera Word.
; Por eso vale el empaquetado DOuble a Word 

psllq xmm5, shift_Bit_32
por xmm1, xmm5		; xmm1 = | 0 | ΔR3*ΔR3 | 0 | ΔR2*ΔR2 | 0 | ΔR1*ΔR1 | 0 | ΔR0*ΔR0|
			
; VERDE
movdqu xmm5, xmm2
pmuldq xmm2, xmm2		; X2 = |0 0 0 ΔG1*ΔG1|0 0 0 ΔG2*GR0|
psrldq xmm5, shift_Byte_4
pmuldq xmm5, xmm5		; X4 = |0 0 0 ΔG3*ΔG3|0 0 0 ΔG2*ΔG2|

psllq xmm5, shift_Bit_32			
por xmm2, xmm5		; X2 = | 0 | ΔG2*ΔG3 | 0 | ΔG2*ΔG2 | 0 | ΔG1*ΔG1 | 0 | ΔG0*ΔG0|

; BLUE
movdqu xmm5, xmm3
pmuldq xmm3, xmm3		; X1 = |0 0 0 ΔB1*ΔB1|0 0 0 ΔB0*ΔB0|
psrldq xmm5, shift_Byte_4
pmuldq xmm5, xmm5		; X4 = |0 0 0 ΔB3*ΔB3|0 0 0 ΔB2*ΔB2|
		
psllq xmm5, shift_Bit_32
por xmm3, xmm5		; X3 = | 0 | ΔB3*ΔB3 | 0 | ΔB2*ΔB2 | 0 | ΔB1*ΔB1 | 0 | ΔB0*ΔB0|

; xmm en uso:
; xmm0  = px3|px2|px1|px0 (int32) con px[i] con formato argb
; xmm11 = Or3|Or2|Or1|Or0 (int32)
; xmm12 = Og3|Og2|Og1|Og0 (int32)
; xmm13 = Ob3|Ob2|Ob1|Ob0 (int32)
; xmm1  =  u3| u2| u1| u0 (int32) con u[i] = dr*dr
; xmm2  =  v3| v2| v1| v0 (int32) con v[i] = dg*dg
; xmm3  =  w3| w2| w1| w0 (int32) con w[i] = db*db
; xmm4  =  a3| a2| a1| a0 (int32) con a[i] = rr*2
; xmm10 =  r3| r2| r1| r0 (int32)
; xmm14 =  g3| g2| g1| g0 (int32)
; xmm15 =  b3| b2| b1| b0 (int32)

; ------------------------------------------------------------------------------

; resta 
movdqu xmm5, xmm1		; X5 = ΔR^2
psubd xmm5, xmm3		; X5 = ΔR^2-ΔB^2 = WORD | ΔR^2-ΔB^2 3 |  ΔR^2-ΔB^2 2 |  ΔR^2-ΔB^2 1 |  ΔR^2-ΔB^2 0 |
; ΔR^2-ΔB^2 estrictamente es Word, en el registro es Double Word

; xmm en uso:
; xmm0  = px3|px2|px1|px0 (int32) con px[i] con formato argb
; xmm11 = Or3|Or2|Or1|Or0 (int32)
; xmm12 = Og3|Og2|Og1|Og0 (int32)
; xmm13 = Ob3|Ob2|Ob1|Ob0 (int32)
; xmm1  =  u3| u2| u1| u0 (int32) con u[i] = dr*dr
; xmm2  =  v3| v2| v1| v0 (int32) con v[i] = dg*dg
; xmm3  =  w3| w2| w1| w0 (int32) con w[i] = db*db
; xmm4  =  a3| a2| a1| a0 (int32) con a[i] = rr*2
; xmm5  =  x3| x2| x1| x0 (int32) con x[i] = dr*dr - db*db
; xmm10 =  r3| r2| r1| r0 (int32)
; xmm14 =  g3| g2| g1| g0 (int32)
; xmm15 =  b3| b2| b1| b0 (int32)

; ------------------------------------------------------------------------------

; multiplico r * (ΔR*2-ΔB*2)

movdqu xmm8, xmm4
pmuldq xmm8, xmm5             ; xmm8 = rr*2*(dr*dr - db*db) (píxeles 2 y 0)

psrldq xmm5, shift_Byte_4
psrldq xmm4, shift_Byte_4
pmuldq xmm4, xmm5             ; xmm4 = rr*2*(dr*dr - db*db) (píxeles 3 y 1)

; OJO supongo que la multiplicación escribe el QWORD sobre el r en posición menos significativa 

psllq xmm4, shift_Bit_32
blendps xmm4, xmm8, 0b0101    ; xmm4 = rr*2*(dr*dr - db*db) (los cuatro píxeles)

; @informe: hay que usar "blend" en lugar de "por" porque si el núm es negativo,
; está relleno de unos.

cvtdq2ps xmm4, xmm4
divps xmm4, [dqword_cuatro_floats_iguales_a_512]

; xmm en uso:
; xmm0  = px3|px2|px1|px0 (int32) con px[i] con formato argb
; xmm11 = Or3|Or2|Or1|Or0 (int32)
; xmm12 = Og3|Og2|Og1|Og0 (int32)
; xmm13 = Ob3|Ob2|Ob1|Ob0 (int32)
; xmm1  =  u3| u2| u1| u0 (int32) con u[i] = dr*dr
; xmm2  =  v3| v2| v1| v0 (int32) con v[i] = dg*dg
; xmm3  =  w3| w2| w1| w0 (int32) con w[i] = db*db
; xmm4  =  a3| a2| a1| a0 (float) con a[i] = rr*(dr*dr - db*db)/256
; xmm10 =  r3| r2| r1| r0 (int32)
; xmm14 =  g3| g2| g1| g0 (int32)
; xmm15 =  b3| b2| b1| b0 (int32)

; ------------------------------------------------------------------------------
			
; CUENTAS DE DELTAS Δs

pslld xmm1, shift_Bit_1     ; xmm1 = 2*dr*dr
pslld xmm2, shift_Bit_2     ; xmm2 = 4*dg*dg
movdqa xmm6, xmm3
pslld xmm3, shift_Bit_1
paddd xmm3, xmm6            ; xmm3 = 3*db*db

; OBTENGO d^2 EN LUGAR DE D (en DW)

paddd xmm1, xmm2
paddd xmm1, xmm3
cvtdq2ps xmm1, xmm1
addps xmm1, xmm4            ; xmm1 = d^2

; xmm en uso:
; xmm0  = px3|px2|px1|px0 (int32) con px[i] con formato argb
; xmm11 = Or3|Or2|Or1|Or0 (int32)
; xmm12 = Og3|Og2|Og1|Og0 (int32)
; xmm13 = Ob3|Ob2|Ob1|Ob0 (int32)
; xmm1  =  z3| z2| z1| z0 (float) con z[i] = d^2
; xmm10 =  r3| r2| r1| r0 (int32)
; xmm14 =  g3| g2| g1| g0 (int32)
; xmm15 =  b3| b2| b1| b0 (int32)

; FINALIZADO CÁLCULO DE D^2

; ------------------------------------------------------------------------------

; Cálculo del valor de c y las máscaras

cvtsi2ss xmm3, eax
movss xmm2, xmm3

pslldq xmm2, shift_Byte_4
movss xmm2, xmm3

pslldq xmm2, shift_Byte_4
movss xmm2, xmm3

pslldq xmm2, shift_Byte_4
movss xmm2, xmm3                     ; xmm2 = lim como float (cuatro veces)

mulps xmm2, xmm2		     ; xmm2 = lim^2 como float (cuatro veces)
			             
movdqa xmm6, xmm1
cmpltps xmm6, xmm2                   ; xmm6 = d^2 < lim^2

divps xmm1, xmm2                     ; xmm1 = c = d^2/lim^2 como float

movdqa xmm2, [dqword_cuatro_floats_iguales_a_uno]
subps xmm2, xmm1                     ; xmm2 = 1 - c (cuatro veces)

; xmm en uso:
; xmm0  = px3|px2|px1|px0 (int32) con px[i] con formato argb
; xmm11 = Or3|Or2|Or1|Or0 (int32)
; xmm12 = Og3|Og2|Og1|Og0 (int32)
; xmm13 = Ob3|Ob2|Ob1|Ob0 (int32)
; xmm1  =  c3| c2| c1| c0 (float)
; xmm2  =  z3| z2| z1| z0 (float) con z[i] = 1-c
; xmm6  =  x3| x2| x1| x0 (int32) con x[i] = 0xFFFFFFFF si d^2 < lim^2, 0 si no
; xmm10 =  r3| r2| r1| r0 (int32)
; xmm14 =  g3| g2| g1| g0 (int32)
; xmm15 =  b3| b2| b1| b0 (int32)

; ------------------------------------------------------------------------------

; Lectura del color N (el color nuevo que se pone en lugar de O)

; Lectura del rojo:

xor r10, r10
mov r10b, [rbp+16]               ; al = unsigned char _Nr
cvtsi2ss xmm3, r10d
movss xmm7, xmm3

pslldq xmm7, shift_Byte_4
movss xmm7, xmm3

pslldq xmm7, shift_Byte_4
movss xmm7, xmm3

pslldq xmm7, shift_Byte_4
movss xmm7, xmm3                 ; xmm7 = _Nr como float (4 veces)

; Lectura del verde:

mov r10b, [rbp+24]               ; al = unsigned char _Ng
cvtsi2ss xmm3, r10d
movss xmm8, xmm3

pslldq xmm8, shift_Byte_4
movss xmm8, xmm3

pslldq xmm8, shift_Byte_4
movss xmm8, xmm3

pslldq xmm8, shift_Byte_4
movss xmm8, xmm3                 ; xmm8 = _Ng como float (4 veces)

; Lectura del azul:

mov r10b, [rbp+32]               ; al = unsigned char _Nb
cvtsi2ss xmm3, r10d
movss xmm9, xmm3

pslldq xmm9, shift_Byte_4
movss xmm9, xmm3

pslldq xmm9, shift_Byte_4
movss xmm9, xmm3

pslldq xmm9, shift_Byte_4
movss xmm9, xmm3                 ; xmm9 = _Nb como float (4 veces)

; xmm en uso:
; xmm0  = px3|px2|px1|px0 (int32)
; xmm11 = Or3|Or2|Or1|Or0 (int32)
; xmm12 = Og3|Og2|Og1|Og0 (int32)
; xmm13 = Ob3|Ob2|Ob1|Ob0 (int32)
; xmm1  =  c3| c2| c1| c0 (float)
; xmm2  =  z3| z2| z1| z0 (float) con z[i] = 1-c
; xmm6  =  x3| x2| x1| x0 (int32) con x[i] = 0xFFFFFFFF si d^2 < lim^2, 0 si no
; xmm7  = Nr3|Nr2|Nr1|Nr0 (float)
; xmm8  = Ng3|Ng2|Ng1|Ng0 (float)
; xmm9  = Nb3|Nb2|Nb1|Nb0 (float)
; xmm10 =  r3| r2| r1| r0 (int32)
; xmm14 =  g3| g2| g1| g0 (int32)
; xmm15 =  b3| b2| b1| b0 (int32)

; ------------------------------------------------------------------------------

; Cálculo del color nuevo

; Color azul:

mulps xmm9, xmm2

cvtdq2ps xmm3, xmm15
mulps xmm3, xmm1

addps xmm3, xmm9                    ; Nb*(1-c) + src_matrix[i][j].b*c 

; Color verde:

mulps xmm8, xmm2

cvtdq2ps xmm4, xmm14
mulps xmm4, xmm1

addps xmm4, xmm8                    ; Nb*(1-c) + src_matrix[i][j].b*c

; Color rojo:

mulps xmm7, xmm2

cvtdq2ps xmm5, xmm10
mulps xmm5, xmm1

addps xmm5, xmm7                    ; Nr*(1-c) + src_matrix[i][j].r*c

; Resultados en int32:

cvtps2dq xmm3, xmm3
cvtps2dq xmm4, xmm4
cvtps2dq xmm5, xmm5

; xmm en uso:
; xmm0  = px3|px2|px1|px0 (int32) con px[i]
; xmm11 = Or3|Or2|Or1|Or0 (int32)
; xmm12 = Og3|Og2|Og1|Og0 (int32)
; xmm13 = Ob3|Ob2|Ob1|Ob0 (int32)
; xmm6  = x3| x2| x1| x0 (int32) con x[i] = 0xFFFFFFFF si d^2 < lim^2, 0 si no
; xmm3  = Nb*(1-c) + src_matrix[i][j].b*c (cuatro int32)
; xmm4  = Ng*(1-c) + src_matrix[i][j].g*c (cuatro int32)
; xmm5  = Nr*(1-c) + src_matrix[i][j].r*c (cuatro int32)

; ------------------------------------------------------------------------------

; Saturación del color nuevo

pcmpeqq xmm1, xmm1                                 ; máscara: todos los bit en 1
movdqa xmm15, xmm1
pslld xmm15, shift_Bit_24
psrld xmm15, shift_Bit_24                          ; máscara: cuatro 255
pxor xmm8, xmm8                                    ; máscara: cuatro ceros

; Saturación del azul:

movdqa xmm10, xmm3
movdqa xmm9, xmm15
pcmpgtd xmm9, xmm10          ; xmm9 = 0x00000000 si resultado_azul >= 255

movdqa xmm7, xmm3
pcmpgtd xmm7, xmm8           ; xmm7 = 0x00000000 si resultado_azul <= 0

pand xmm3, xmm9

movdqa xmm14, xmm15
pxor xmm9, xmm1
pand xmm14, xmm9             ; xmm14 = 255 si resultado_azul >= 255, 0 si no

por xmm3, xmm14
pand xmm3, xmm7              ; xmm3 = sat(Nb*(1-c) + src_matrix[i][j].b*c)

; Saturación del verde:

movdqa xmm10, xmm4
movdqa xmm9, xmm15
pcmpgtd xmm9, xmm10          ; xmm9 = 0x00000000 si resultado_verde >= 255

movdqa xmm7, xmm4
pcmpgtd xmm7, xmm8           ; xmm7 = 0x00000000 si resultado_verde <= 0

pand xmm4, xmm9

movdqa xmm14, xmm15
pxor xmm9, xmm1
pand xmm14, xmm9             ; xmm14 = 255 si resultado_verde >= 255, 0 si no

por xmm4, xmm14
pand xmm4, xmm7              ; xmm4 = sat(Ng*(1-c) + src_matrix[i][j].g*c)

; Saturación del rojo:

movdqa xmm10, xmm5
movdqa xmm9, xmm15
pcmpgtd xmm9, xmm10          ; xmm9 = 0x00000000 si resultado_rojo >= 255

movdqa xmm7, xmm5
pcmpgtd xmm7, xmm8           ; xmm7 = 0x00000000 si resultado_rojo <= 0

pand xmm5, xmm9

movdqa xmm14, xmm15
pxor xmm9, xmm1
pand xmm14, xmm9             ; xmm14 = 255 si resultado_rojo >= 255, 0 si no

por xmm5, xmm14
pand xmm5, xmm7              ; xmm5 = sat(Nr*(1-c) + src_matrix[i][j].r*c)

; xmm en uso:
; xmm0  = px3|px2|px1|px0 (int32)
; xmm11 = Or3|Or2|Or1|Or0 (int32)
; xmm12 = Og3|Og2|Og1|Og0 (int32)
; xmm13 = Ob3|Ob2|Ob1|Ob0 (int32)
; xmm6  =  x3| x2| x1| x0 (int32) con x[i] = 0xFFFFFFFF si d^2 < lim^2, 0 si no
; xmm3  = sat(Nb*(1-c) + src_matrix[i][j].b*c) (cuatro int32)
; xmm4  = sat(Ng*(1-c) + src_matrix[i][j].g*c) (cuatro int32)
; xmm5  = sat(Nr*(1-c) + src_matrix[i][j].r*c) (cuatro int32)
; xmm15 = 255|255|255|255 (máscara)

; ------------------------------------------------------------------------------

; Pisar con cero el color original donde d^2 < lim^2:

pcmpeqq xmm7, xmm7
pxor xmm7, xmm6              ; 0x0 si d^2 < lim^2, 0xFFFFFFFF si no

pand xmm0, xmm7              ; imagen original con ceros donde d^2 < lim^2

; Pisar con cero el nuevo color donde d^2 >= lim^2:

; El guión representa el número cero en 8 bits para facilitar la legibilidad

pand xmm3, xmm6              ; -|-|-|b3|-|-|-|b2|-|-|-|b1|-|-|-|b0 (bytes)
pand xmm4, xmm6              ; -|-|-|g3|-|-|-|g2|-|-|-|g1|-|-|-|g0 (bytes)
pand xmm5, xmm6              ; -|-|-|r3|-|-|-|r2|-|-|-|r1|-|-|-|r0 (bytes)

; Unir el resultado en formato argb:

pslldq xmm15, shift_Byte_3   ; a|-|-|-|a|-|-|-|a|-|-|-|a|-|-|-
pslldq xmm5, shift_Byte_2    ; -|r|-|-|-|r|-|-|-|r|-|-|-|r|-|-
pslldq xmm4, shift_Byte_1    ; -|-|g|-|-|-|g|-|-|-|g|-|-|-|g|-
                             ; -|-|-|b|-|-|-|b|-|-|-|b|-|-|-|b

por xmm15, xmm3
por xmm15, xmm4
por xmm15, xmm5              ; valor final para dst_matrix[i][j] si d^2 < lim^2

; xmm en uso:
; xmm0 = 4 px de la img original (formato bgra) con ceros donde d^2 < lim^2
; xmm15 = 4 px de la img resultado (formato bgra) con ceros donde d^2 >= lim^2
; xmm11 = Or3|Or2|Or1|Or0 (int32)
; xmm12 = Og3|Og2|Og1|Og0 (int32)
; xmm13 = Ob3|Ob2|Ob1|Ob0 (int32)

; ------------------------------------------------------------------------------

; Resultado final:

por xmm0, xmm15              ; 4 px para escribir en destino
movdqu [rsi], xmm0

add rdi, next_4_pixels
add rsi, next_4_pixels
cmp rdi, r8
jb .ciclo

pop rbp 
ret
