
global tresColores_asm

section .rodata				
		ALIGN 16
	; constantes:	
		cte_dw_3: times 4 dd 3.0
		cte_dw_85: times 4 dd 0x55
		cte_dw_170: times 4 dd 0xAA	

	; máscaras: 
		color_rojo_4dw: times 4 db 0x41, 0x58, 0xF4, 0x00
		color_verde_4dw: times 4 db 0x6E, 0x70, 0x00, 0x00
		color_crema_4dw: times 4 db 0xD6, 0xE9, 0xEC, 0x00

section .text

	;void tresColores_c(
	;    unsigned char *src,
	;    unsigned char *dst,
	;    int width,
	;    int height,
	;    int src_row_size,
	;    int dst_row_size)

%define shift_Byte_1 8
%define shift_Byte_2 16
%define shift_Byte_3 24
%define shift_Bit_2 2
%define shift_Bit_1 1
%define next_4_pixels 16

tresColores_asm:

		; RDI = *src , RSI = *dst, EDX = width, ECX = height, R8d = src_row_size, R9d = dst_row_size 
	
		push rbp
		mov rbp, rsp

		mov eax, R8d
		mul ecx			; rax = src_row_size * height
		lea R8, [rax + rdi]	; R8 = *src.end()
	
		movdqa xmm13, [cte_dw_3]
		movdqa xmm12, [cte_dw_85] 	
		movdqa xmm11, [cte_dw_170]
		movdqa xmm10, [color_rojo_4dw]
		movdqa xmm9, [color_verde_4dw]
		movdqa xmm8, [color_crema_4dw]
	
	.ciclo:	
		cmp rdi, R8		; no necesito *src, directamente modifico rdi
		je .end
	
		; OBTENCIÓN DE SUMA DE COLORES

			movdqu xmm1, [rdi]			; xmm1 = |px3|px2|px1|px0|
			movdqu xmm2, xmm1			; xmm2 = |argb3|argb2|argb1|argb0|
			movdqu xmm3, xmm1			; xmm3 = |argb3|argb2|argb1|argb0|

			; BLUE X1
			pslld xmm1, shift_Byte_3		; xmm1 = |b3 0 0 0|b2 0 0 0|b1 0 0 0|b0 0 0 0|
			psrld xmm1, shift_Byte_3		; xmm1 = | 0 0 0 b3|0 0 0 b2|0 0 0 b1|0 0 0 b0| 

			; GREEN X2
			pslld xmm2, shift_Byte_2		; xmm2 = |g3 b3 0 0|g2 b2 0 0|g1 b1 0 0|g0 b0 0 0|
			psrld xmm2, shift_Byte_3		; xmm2 = | 0 0 0 g3|0 0 0 g2|0 0 0 g1|0 0 0 g0| 

			; RED X3
			pslld xmm3, shift_Byte_1		; xmm3 = |r3 g3 b3 0|r2 g2 b2 0|r1 g1 b1 0|r0 g0 b0 0|
			psrld xmm3, shift_Byte_3		; xmm3 = | 0 0 0 r3|0 0 0 r2|0 0 0 r1|0 0 0 r0| 

			; suma de colores X1
			paddd xmm1, xmm3			; xmm1 = blue + red
			paddd xmm1, xmm2 			; xmm1 = blue + red + green = | s3 | s2 | s1 | s0 | INTEGERS DW

			; Comentario de color: googlear Division of integers by constants
			; Hay formas de dividir copadas con shift y módulos en lugar de trabajar con floats
				
		; DIVISIÓN POR 3

			; conversión de integer a float
			cvtdq2ps xmm1, xmm1			; xmm1 = | s3 | s2 | s1 | s0 | FLOATS

			; división por 3
			divps xmm1, xmm13			; xmm1 = | brillo3 | brillo2 | brillo1 | brillo0 |

			; conversión de float a integer (packed single FP to packed dwords integers) por truncación Ej 3.7 -> 3
			cvttps2dq xmm1, xmm1			; xmm1 = | brillo3 | brillo2 | brillo1 | brillo0 | INTEGERS

		; MÁSCARAS SEGÚN INTENSIDAD DE BRILLO

			movdqu xmm2, xmm1
			movdqu xmm0, xmm1
			movdqu xmm3, xmm1						
		
			; máscara W < 85 X3
			movdqa xmm3, xmm12			; X3 <-[máscara_85] 
			pcmpgtd xmm3, xmm2			; X3 = mscara W < 85 (es 85 mayor a brillo n-ésimo)		

			; máscara W >= 170 X2
			pcmpgtd xmm2, xmm11			; X2 <- máscara W > 170 (es brillo n-ésimo mayor a 170?)
			pcmpeqd xmm0, xmm11			; X0 <- máscara W = 170
			por xmm2, xmm0				; X2 <- máscara W >= 170

			; máscara 85 < W <= 170 X4
			movdqu xmm4, xmm3			
			por xmm4, xmm2 				;  X4 = máscara W >= 170 or W < 85 ?
			pcmpeqd xmm0, xmm0
			pandn xmm4, xmm0			; not (W >= 170 or W < 85) <==> 85 <= W < 170

		; OBTENCIÓN NUEVOS COLORES
		; registros empleados: X1<-brillos, X2<-máscara >=170, X3<-máscara <85, X4<-máscara 85 < W <= 170,  X8-X13<-máscaras en memoria

			movdqa xmm5, xmm10			; X5 = rojo 
			movdqa xmm6, xmm9			; X6 = verde
			movdqa xmm7, xmm8			; X7 = crema 

			; dejo el color solo si se cumple la condición de intensidad de W
			; rojo con W<85	en X3	
			pand  xmm3, xmm5			; X3 = | rojo | 0 | 0 | 0 |
			; verde con 85 < W <= 170 en X4
			pand xmm4, xmm6				; X4 = | 0 | verde | verde | 0 |
			; crema con  W >= 170 en X2
			pand xmm2, xmm7				; X2 = | 0 | 0 | 0 | crema |

		; X1<-W X2<-crema X3<-rojo X4<-verde todo el DW    X8-X13 <- máscaras		
			
			; Desdoblo brillo de DW a W para sumar colores donde cada componente es word			

			pxor xmm7, xmm7

			movdqu xmm0, xmm1
			punpckldq xmm1, xmm7			; X1 = | 0 0 0 0 0 0 0 w1 | 0 0 0 0 0 0 0 w0 |
			punpckhdq xmm0, xmm7 			; X0 = | 0 0 0 0 0 0 0 w3 | 0 0 0 0 0 0 0 w2 |
			
			;obtengo brillos en cada WORD LOW 			
			movdqu xmm5, xmm1
			psllq xmm5, shift_Byte_2		; X5 = | 0 0 | 0 0 | 0 w1 | 0 0 | 0 0 | 0 0 | 0 w0 | 0 0 |
			por xmm1, xmm5				; X1 = | 0 0 0 0 0 w1 0 w1 | 0 0 0 0 0 w0 0 w0 |
			psllq xmm5, shift_Byte_2	
			por xmm1, xmm5				; X1 = | 0 0 | 0 w1 | 0 w1 | 0 w1 | 0 0 | 0 w0 | 0 w0 | 0 w0 |

			;obtengo brillos en cada WORD HIGH 			
			movdqu xmm5, xmm0
			psllq xmm5, shift_Byte_2		; X5 = | 0 0 | 0 0 | 0 w3 | 0 0 | 0 0 | 0 0 | 0 w2 | 0 0 |
			por xmm0, xmm5				; X0 = | 0 0 0 0 0 w3 0 w3 | 0 0 0 0 0 w2 0 w2 |
			psllq xmm5, shift_Byte_2
			por xmm0, xmm5				; X0 = | 0 0 | 0 w3 | 0 w3 | 0 w3 | 0 0 | 0 w2 | 0 w2 | 0 w2 |

		; X0<-brillos_low, X1<-brillos_high, (en word) X2<-crema, X3<-rojo, X4<-verde, (colores filtrados en DW), X8-X13 <- máscaras

				movdqa xmm5, xmm2
				punpcklbw xmm2, xmm7		; X2<-low crema
				punpckhbw xmm5, xmm7		; X5<-high crema
			
				movdqa xmm6, xmm3
				punpcklbw xmm3, xmm7		; X3<-low rojo
				punpckhbw xmm6, xmm7		; X6<-high rojo

				movdqa xmm14, xmm4
				punpcklbw xmm4, xmm7		; X4<-low verde
				punpckhbw xmm14, xmm7		; X14<-high verde

				por xmm2, xmm3
				por xmm2, xmm4			; merge tono de colores parte LOW

				por xmm5, xmm6
				por xmm5, xmm14			; merge tono de colores parte HIGH
				
				movdqa xmm15, xmm2
				paddw xmm2, xmm2
				paddw xmm2, xmm15		; tonos*3 LOW

				movdqa xmm15, xmm5
				paddw xmm5, xmm5
				paddw xmm5, xmm15		; tonos*3 HIGH

				paddw xmm1, xmm2		; tonos*3 LOW + brillos LOW
				paddw xmm0, xmm5		; tonos*3 HIGH + brillos HIGH
			
			; división por 4
			psrlw xmm1, shift_Bit_2		; X1 = 1/4*| 0 0 | 3C+w1 | 3C+ w1 | 3C + w1 | 0 0 | 3C + w0 | 3C + w0 | 3C + w0 |
			psrlw xmm0, shift_Bit_2		; X0 = 1/4*| 0 0 | 3C+w3 | 3C+ w3 | 3C + w3 | 0 0 | 3C + w2 | 3C + w2 | 3C + w2 |
			packuswb xmm1, xmm0 		; X1 = |0|3C+w3|3C+w3|3C+w3|0|3C+w2|3C+w2|3C+w2|0|3C+w1|3C+w1|3C+w1|0|3C+w0|3C+w0|3C+w0| 	

			; FINALIZADO MERGE COLORES NUEVOS + BRILLO

		; AGREGO TRANSPARENCIA

			pcmpeqd xmm0, xmm0			; seteo todos los bits en 1
			pslld xmm0, shift_Byte_3		; X0 = | 1 0 0 0 | 1 0 0 0  | 1 0 0 0  | 1 0 0 0  |
			por xmm0, xmm1				
	
		; RETORNO EN DESTINO
		movdqu [rsi], xmm0
		lea rsi, [rsi + next_4_pixels]
		lea rdi, [rdi + next_4_pixels]
		jmp .ciclo

	.end:
		pop rbp 
		ret









































