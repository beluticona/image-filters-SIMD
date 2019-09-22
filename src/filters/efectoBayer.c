#include <stdio.h>
#include <string.h>

#include "../tp2.h"

void efectoBayer_asm (unsigned char *src, unsigned char *dst, int cols, int filas,
                      int src_row_size, int dst_row_size);

void efectoBayer_c   (unsigned char *src, unsigned char *dst, int cols, int filas,
                      int src_row_size, int dst_row_size);

typedef void (efectoBayer_fn_t) (unsigned char*, unsigned char*, int, int, int, int);


void leer_params_efectoBayer(configuracion_t *config, int argc, char *argv[]) {
    
}

void aplicar_efectoBayer(configuracion_t *config)
{
    efectoBayer_fn_t *efectoBayer = SWITCH_C_ASM ( config, efectoBayer_c, efectoBayer_asm ) ;
    buffer_info_t info = config->src;
    efectoBayer(info.bytes, config->dst.bytes, info.width, info.height, info.width_with_padding,
                config->dst.width_with_padding);
}

void ayuda_efectoBayer()
{
    printf ( "       * efectoBayer\n" );
    printf ( "           Parámetros     : \n"
             "                         no tiene\n");
    printf ( "           Ejemplo de uso : \n"
             "                         efectoBayer -i c facil.bmp\n" );
}

DEFINIR_FILTRO(efectoBayer)

