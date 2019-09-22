global edgeSobel_asm
edgeSobel_asm:
; rdi = unsigned char *src
; rsi = unsigned char *dst
; edx = int width
; ecx = int height
; r8d = int src_row_size
; r9d = int dst_row_size

push rbp
mov rbp, rsp

mov r10, rsi              ; preservar dst
mov r11d, edx             ; preservar width

mov eax, r8d
mul ecx                   ; eax = row_size*height

mov r8d, r8d
sub rax, r8               ; rax = índice de 1ra celda de última fila

lea rdx, [rsi + rax]      ; rdx -> última fila de la matriz dst

sub rax, r8               ; rax = índice de 1ra celda de anteúltima fila

lea rax, [rdi + rax - 16] ; rax -> celda de src donde cortar el ciclo

.ciclo_principal:

; El "r8*2" significa "dos filas". Es medio hack porque el 2 no es la escala,
; pero funciona. Si quisiera sumar tres filas tendría que hacer otra cosa.
 
movdqu xmm1, [rdi + r8*2]     ; arriba a la izquierda
movdqu xmm2, [rdi + r8*2 + 1] ; arriba
movdqu xmm3, [rdi + r8*2 + 2] ; arriba a la derecha
movdqu xmm4, [rdi + r8]       ; a la izquierda
movdqu xmm6, [rdi + r8 + 2]   ; a la derecha
movdqu xmm7, [rdi]            ; abajo a la izquierda
movdqu xmm8, [rdi + 1]        ; abajo
movdqu xmm9, [rdi + 2]        ; abajo a la derecha

; ESQUINAS SUPERIORES (parte baja)
; ------------------------------------------------------------------------------

; izquierda:

pxor xmm10, xmm10
punpcklbw xmm10, xmm1
psrlw xmm10, 8        ; 00|p7|00|p6|00|p5|00|p4|00|p3|00|p2|00|p1|00|p0

; derecha:

pxor xmm11, xmm11
punpcklbw xmm11, xmm3
psrlw xmm11, 8

; xmm10 ---------- xmm11

pxor xmm12, xmm12
psubw xmm12, xmm11
psubw xmm12, xmm10 ; operador Y, parte baja

psubw xmm11, xmm10 ; operador X, parte baja

; xmm en uso:
; datos: 1, 2, 3, 4, 6, 7, 8, 9
; resultados: 11 (X-low), 12 (Y-low)

; ESQUINAS SUPERIORES (parte alta)
; ------------------------------------------------------------------------------

; izquierda:

pxor xmm13, xmm13
punpckhbw xmm13, xmm1
psrlw xmm13, 8        ; 00|p15|00|p14|00|p13|00|p12|00|p11|00|p10|00|p9|00|p8

; derecha:

pxor xmm14, xmm14
punpckhbw xmm14, xmm3
psrlw xmm14, 8

; xmm13 ---------- xmm14

pxor xmm15, xmm15
psubw xmm15, xmm14
psubw xmm15, xmm13 ; operador Y, parte alta

psubw xmm14, xmm13 ; operador X, parte alta

; xmm en uso:
; datos: 2, 4, 6, 7, 8, 9
; resultados: 14|11 (X), 15|12 (Y)

; ARRIBA EN EL MEDIO
; ------------------------------------------------------------------------------

pxor xmm1, xmm1
punpcklbw xmm1, xmm2
psrlw xmm1, 8        ; parte baja

pxor xmm3, xmm3
punpckhbw xmm3, xmm2
psrlw xmm3, 8        ; parte alta

psubw xmm12, xmm1
psubw xmm12, xmm1    ; operador Y, parte baja

psubw xmm15, xmm3
psubw xmm15, xmm3    ; operador Y, parte alta

; xmm en uso:
; datos: 4, 6, 7, 8, 9
; resultados: 14|11 (X), 15|12 (Y)

; ABAJO EN EL MEDIO
; ------------------------------------------------------------------------------

pxor xmm1, xmm1
punpcklbw xmm1, xmm8
psrlw xmm1, 8        ; parte baja

pxor xmm3, xmm3
punpckhbw xmm3, xmm8
psrlw xmm3, 8        ; parte alta

paddw xmm12, xmm1
paddw xmm12, xmm1    ; operador Y, parte baja

paddw xmm15, xmm3
paddw xmm15, xmm3    ; operador Y, parte alta

; xmm en uso:
; datos: 4, 6, 7, 9
; resultados: 14|11 (X), 15|12 (Y)

; A LA DERECHA
; ------------------------------------------------------------------------------

pxor xmm1, xmm1
punpcklbw xmm1, xmm6
psrlw xmm1, 8        ; parte baja

pxor xmm3, xmm3
punpckhbw xmm3, xmm6
psrlw xmm3, 8        ; parte alta

paddw xmm11, xmm1
paddw xmm11, xmm1    ; operador X, parte baja

paddw xmm14, xmm3
paddw xmm14, xmm3    ; operador X, parte alta

; xmm en uso:
; datos: 4, 7, 9
; resultados: 14|11 (X), 15|12 (Y)

; A LA IZQUIERDA
; ------------------------------------------------------------------------------

pxor xmm1, xmm1
punpcklbw xmm1, xmm4
psrlw xmm1, 8        ; parte baja

pxor xmm3, xmm3
punpckhbw xmm3, xmm4
psrlw xmm3, 8        ; parte alta

psubw xmm11, xmm1
psubw xmm11, xmm1    ; operador X, parte baja

psubw xmm14, xmm3
psubw xmm14, xmm3    ; operador X, parte alta

; xmm en uso:
; datos: 7, 9
; resultados: 14|11 (X), 15|12 (Y)

; ESQUINA INFERIOR IZQUIERDA
; ------------------------------------------------------------------------------

pxor xmm1, xmm1
punpcklbw xmm1, xmm7
psrlw xmm1, 8        ; parte baja

pxor xmm3, xmm3
punpckhbw xmm3, xmm7
psrlw xmm3, 8        ; parte alta

psubw xmm11, xmm1    ; operador X, parte baja

psubw xmm14, xmm3    ; operador X, parte alta

paddw xmm12, xmm1    ; operador Y, parte baja

paddw xmm15, xmm3    ; operador Y, parte alta

; xmm en uso:
; datos: 9
; resultados: 14|11 (X), 15|12 (Y)

; ESQUINA INFERIOR DERECHA
; ------------------------------------------------------------------------------

pxor xmm1, xmm1
punpcklbw xmm1, xmm9
psrlw xmm1, 8        ; parte baja

pxor xmm3, xmm3
punpckhbw xmm3, xmm9
psrlw xmm3, 8        ; parte alta

paddw xmm11, xmm1    ; operador X, parte baja

paddw xmm14, xmm3    ; operador X, parte alta

paddw xmm12, xmm1    ; operador Y, parte baja

paddw xmm15, xmm3    ; operador Y, parte alta

; xmm en uso:
; datos: ninguno
; resultados: 14|11 (X), 15|12 (Y)

; MÓDULO DE X
; ------------------------------------------------------------------------------

pcmpeqq xmm0, xmm0                  ; máscara (todos los bit en 1)

; parte baja

pxor xmm1, xmm1
pcmpgtw xmm1, xmm11                 ; 0xFFFF en los negativos
movdqa xmm2, xmm1
pxor xmm2, xmm0                     ; 0xFFFF en los positivos

pxor xmm3, xmm3
psubw xmm3, xmm11
pand xmm3, xmm1                     ; módulo de negativos (0 en los positivos)
pand xmm11, xmm2                    ; solo positivos (0 en los negativos)

por xmm11, xmm3                     ; xmm11 = módulo de X (parte baja)

; parte alta

pxor xmm1, xmm1
pcmpgtw xmm1, xmm14                 ; 0xFFFF en los negativos
movdqa xmm2, xmm1
pxor xmm2, xmm0                     ; 0xFFFF en los positivos

pxor xmm3, xmm3
psubw xmm3, xmm14
pand xmm3, xmm1                     ; módulo de negativos (0 en los positivos)
pand xmm14, xmm2                    ; solo positivos (0 en los negativos)

por xmm14, xmm3                     ; xmm14 = módulo de X (parte alta)

; xmm en uso:
; datos: 0 (la máscara)
; resultados: 14|11 (X), 15|12 (Y)

; MÓDULO DE Y
; ------------------------------------------------------------------------------

; parte baja

pxor xmm1, xmm1
pcmpgtw xmm1, xmm12                 ; 0xFFFF en los negativos
movdqa xmm2, xmm1
pxor xmm2, xmm0                     ; 0xFFFF en los positivos

pxor xmm3, xmm3
psubw xmm3, xmm12
pand xmm3, xmm1                     ; módulo de negativos (0 en los positivos)
pand xmm12, xmm2                    ; solo positivos (0 en los negativos)

por xmm12, xmm3                     ; xmm12 = módulo de Y (parte baja)

; parte alta

pxor xmm1, xmm1
pcmpgtw xmm1, xmm15                 ; 0xFFFF en los negativos
movdqa xmm2, xmm1
pxor xmm2, xmm0                     ; 0xFFFF en los positivos

pxor xmm3, xmm3
psubw xmm3, xmm15
pand xmm3, xmm1                     ; módulo de negativos (0 en los positivos)
pand xmm15, xmm2                    ; solo positivos (0 en los negativos)

por xmm15, xmm3                     ; xmm15 = módulo de Y (parte alta)

; xmm en uso:
; datos: ninguno
; resultados: 14|11 (X), 15|12 (Y)

; CUENTAS FINALES Y ESCRITURA EN DESTINO
; ------------------------------------------------------------------------------

paddw xmm11, xmm12                  ; |X| + |Y| (parte baja)
paddw xmm14, xmm15                  ; |X| + |Y| (parte alta)

; xmm14 = p15|p14|p13|p12|p11|p10|p09|p08 (words)
; xmm11 = p07|p06|p05|p04|p03|p02|p01|p00 (words)

packuswb xmm11, xmm14

; xmm11 = p15|p14|p13|p12|p11|p10|p9|p8|p7|p6|p5|p4|p3|p2|p1|p0 (bytes)

movdqu [rsi + r8 + 1], xmm11        ; dst[i, j] = saturar_byte(|X| + |Y|)

add rdi, 16
add rsi, 16
cmp rdi, rax
jb .ciclo_principal

; PROCESAMIENTO DE LOS ÚLTIMOS 14 PÍXELES
; ------------------------------------------------------------------------------

; rdi y rsi apuntan a la celda de abajo a la izquierda del pixel a procesar

push r10
push rcx

mov ecx, 14
.ciclo_ultimos_pixeles:

xor r9, r9
xor r10, r10
xor rax, rax

; r10w = operador X
; r9w = operador Y

mov al, [rdi + 2*r8 + 2]            ; arriba a la derecha
add r10w, ax
sub r9w, ax

mov al, [rdi + r8 + 2]              ; a la derecha
add r10w, ax
add r10w, ax

mov al, [rdi + 2]                   ; abajo a la derecha
add r10w, ax
add r9w, ax

mov al, [rdi + r8*2]                ; arriba a la izquierda
sub r10w, ax
sub r9w, ax

mov al, [rdi + r8]                  ; a la izquierda
sub r10w, ax
sub r10w, ax

mov al, [rdi]                       ; abajo a la izquierda
sub r10w, ax
add r9w, ax

mov al, [rdi + r8*2 + 1]            ; arriba
sub r9w, ax
sub r9w, ax

mov al, [rdi + 1]                   ; abajo
add r9w, ax
add r9w, ax

cmp r9w, 0                          ; módulo de Y
jg .end_if_0
mov ax, r9w
xor r9w, r9w
sub r9w, ax
.end_if_0:

cmp r10w, 0                         ; módulo de X
jg .end_if_1
mov ax, r10w
xor r10w, r10w
sub r10w, ax
.end_if_1:

add r9w, r10w                       ; saturación a 255
cmp r9w, 255
jb .end_if_2
mov r9w, 255
.end_if_2:

mov [rsi + r8 + 1], r9b

inc rdi
inc rsi

dec ecx
cmp ecx, 0
jne .ciclo_ultimos_pixeles

pop rcx
pop r10

; BORDES VERTICALES EN CERO
; ------------------------------------------------------------------------------

mov rsi, r10

mov ecx, ecx                        ; ecx = height

.ciclo_bordes_verticales:

mov byte [rsi], 0                   ; borde izquierdo
mov byte [rsi + r8 - 1], 0          ; borde derecho

add rsi, r8

loop .ciclo_bordes_verticales

; BORDES HORIZONTALES EN CERO
; ------------------------------------------------------------------------------

mov ecx, r11d
shr ecx, 4                          ; ecx = width/16

pxor xmm0, xmm0

.ciclo_bordes_horizontales:

movdqu [r10], xmm0                  ; primera fila
movdqu [rdx], xmm0                  ; última fila

add r10, 16
add rdx, 16

loop .ciclo_bordes_horizontales

pop rbp

ret
