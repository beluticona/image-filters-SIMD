global efectoBayer_asm

section .rodata	
	ALIGN 16
	;máscaras:	
		transparencia: times 4 db 0x00, 0x00, 0x00, 0xFF		;en memoria pixel = |bgra|		  


section .text

%define shift_Byte_1 8
%define shift_Byte_2 16
%define shift_Byte_3 24
%define shift_Bit_1 1
%define shift_Bit_3 3
%define next_4_pixels 16
%define NULL 0


;void efectoBayer_c (	 unsigned char *src, 
						;unsigned char *dst, 
						;int cols, 
						;int filas,
                     	;int src_row_size, 
						;int dst_row_size);

;En RDI = *src, RSI = *dst, EDX = cols, ECX = filas, R8d =  src_row_size, R9d = dst_row_size
efectoBayer_asm:

	;armo el stack frame	
	push rbp
	mov rbp, rsp	;pila alineada
	push rbx
	sub rsp, 8
	
	

	;En RBX voy a tener el contador del Ciclo externo .bigLoop, itera filas/8 veces
	xor rbx, rbx			;reseteo rbx  
	mov ebx, ecx			
	shr rbx, shift_Bit_3 	;divido la cantidad de filas por 8 = 2^3 shiftea a derecha 3 veces

	;SETEO TRANSPARENCIA EN 255 PARA CADA PIXEL: levanto de memoria la mascara y la guardo en un registro
	movdqa xmm2, [transparencia]		; xmm2 = |a3 0 0 0|a2 0 0 0|a1 0 0 0|a0 0 0 0|  con ai = 255 = 0xFF

		
	.bigLoop:	

		;SETEO EL CONTADOR PARA CICLO_V-A EN #COL/2

		xor rcx, rcx			;reseteo el contador, pierdo el valor de las filas pero no lo vuelvo a necesitar
		mov ecx, edx			;levanto 4 pixels que seran verdes y 4 seran azules col/4 * 4_filas = col veces: en total 4 filas de tipo V A 
		shr rcx, shift_Bit_1	;Divido por 2 = 2^1,  cada ciclo se hace col/2 veces porque levanto 4 pixels -> verde y luego 4 pixels -> azul 									en cada ciclo.

		.cicloVA:
			;SETEO 4 PIXELS A VERDE + TRANSPARENCIA EN 255
			movdqu xmm1, [rdi]				; xmm1 = |px3|px2|px1|px0| = |argb3|argb2|argb1|argb0|
			lea rdi, [rdi + next_4_pixels]  ; me muevo 16 bytes hacia adelante en la memoria, source de la imagen 
			;obtengo el color VERDE mediante shifteos
			pslld xmm1, shift_Byte_2    	; xmm1 = |g3 b3 0 0|g2 b2 0 0|g1 b1 0 0|g0 b0 0 0|  quito la transparencia, no se que valor inicial 																							tiene 
	 		psrld xmm1, shift_Byte_3		; xmm1 = |0 0 0 g3|0 0 0 g2|0 0 0 g1|0 0 0 g0|   
			pslld xmm1, shift_Byte_1		; xmm1 = |0 0 g3 0|0 0 g2 0|0 0 g1 0|0 0 g0 0| 	
			;seteo la transparencia en 255
			por xmm1, xmm2 					; xmm1 = |a3 0 g3 0|a2 0 g2 0|a1 0 g1 0|a0 0 g0 0| 

			movdqu [rsi], xmm1				; guardo en el destino los pixels modificados a verde
			lea rsi, [rsi + next_4_pixels]	

			;SETEO 4 PIXELS A AZUL + TRANSPARENCIA EN 255
			movdqu xmm1, [rdi]				; xmm1 = |px3|px2|px1|px0| = |argb3|argb2|argb1|argb0|
			lea rdi, [rdi + next_4_pixels]  ; me muevo 16 bytes hacia adelante en la memoria, source de la imagen 
			;obtengo el color AZUL mediante shifteos
			pslld xmm1, shift_Byte_3		; xmm1 = |b3 0 0 0|b2 0 0 0|b1 0 0 0|b0 0 0 0| 
			psrld xmm1, shift_Byte_3		; xmm1 = |0 0 0 b3|0 0 0 b2|0 0 0 b1|0 0 0 b0|
			;seteo la transparencia en 255
			por xmm1, xmm2 					; xmm1 = |a3 0 0 b3|a2 0 0 b2|a1 0 0 b1|a0 0 0 b0|

			movdqu [rsi], xmm1				; guardo en el destino los pixels modificados a azul
			lea rsi, [rsi + next_4_pixels]

			loop .cicloVA

	
		;SETEO EL CONTADOR PARA CICLO_R-V EN #COL/2

		;El contador quedo en cero del ciclo anterior
		mov ecx, edx			;levanto 4 pixels que seran rojos y 4 seran verdes col/4 * 4_filas = col veces: en total 4 filas de tipo R V  
		shr rcx, shift_Bit_1	;Divido por 2 = 2^1, cada ciclo se hace col/2 veces porque levanto 4 pixels -> rojo y luego 4 pixels -> verde en 								cada ciclo.

		.cicloRV:
			;SETEO 4 PIXELS A ROJO + TRANSPARENCIA EN 255		
			movdqu xmm1, [rdi]				; xmm1 = |px3|px2|px1|px0| = |argb3|argb2|argb1|argb0|
			lea rdi, [rdi + next_4_pixels]  ; me muevo 16 bytes hacia adelante en la memoria, source de la imagen 
			;obtengo el color ROJO mediante shifteos
			pslld xmm1, shift_Byte_1		; xmm1 = |r3 g3 b3 0|r2 g2 b2 0|r1 g1 b1 0|r0 g0 b0 0|
			psrld xmm1, shift_Byte_3		; xmm1 = |0 0 0 r3|0 0 0 r2|0 0 0 r1|0 0 0 r0|	
			pslld xmm1, shift_Byte_2		; xmm1 = |0 r3 0 0|0 r2 0 0|0 r1 0 0|0 r0 0 0|

 			;seteo la transparencia en 255
			por xmm1, xmm2 					; xmm1 = |a3 r3 0 0|a2 r2 0 0|a1 r1 0 0|a0 r0 0 0|

			movdqu [rsi], xmm1				; guardo en el destino los pixels modificados a rojo
			lea rsi, [rsi + next_4_pixels]	
		

			;SETEO 4 PIXELS A VERDE + TRANSPARENCIA EN 255
			movdqu xmm1, [rdi]				; xmm1 = |px3|px2|px1|px0| = |argb3|argb2|argb1|argb0|
			lea rdi, [rdi + next_4_pixels]  ; me muevo 16 bytes hacia adelante en la memoria, source de la imagen 
			;obtengo el color VERDE mediante shifteos
			pslld xmm1, shift_Byte_2    	; xmm1 = |g3 b3 0 0|g2 b2 0 0|g1 b1 0 0|g0 b0 0 0|  quito la transparencia, no se que valor inicial 																							tiene 
	 		psrld xmm1, shift_Byte_3		; xmm1 = |0 0 0 g3|0 0 0 g2|0 0 0 g1|0 0 0 g0|   
			pslld xmm1, shift_Byte_1		; xmm1 = |0 0 g3 0|0 0 g2 0|0 0 g1 0|0 0 g0 0| 	
			;seteo la transparencia en 255
			por xmm1, xmm2 					; xmm1 = |a3 0 g3 0|a2 0 g2 0|a1 0 g1 0|a0 0 g0 0| 

			movdqu [rsi], xmm1				; guardo en el destino los pixels modificados a verde
			lea rsi, [rsi + next_4_pixels]	

			loop .cicloRV

		dec rbx			;decremento en 1 la cantidad de loops
		cmp rbx, NULL	;si llegue a cero termina
		jne .bigLoop	;sino vuelve a ciclar
						


	;desarmo el stack frame
	add rsp, 8
	pop rbx
	pop rbp
	ret
