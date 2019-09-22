#include <stdio.h>
#include <string.h>

#include "../tp2.h"

void edgeSobel_asm (unsigned char *src, unsigned char *dst, int cols, int filas,
                    int src_row_size, int dst_row_size);

void edgeSobel_c   (unsigned char *src, unsigned char *dst, int cols, int filas,
                    int src_row_size, int dst_row_size);

typedef void (edgeSobel_fn_t) (unsigned char*, unsigned char*, int, int, int, int);


void leer_params_edgeSobel(configuracion_t *config, int argc, char *argv[]) {
    config->bits_src = 8;
    config->bits_dst = 8;
}

void aplicar_edgeSobel(configuracion_t *config)
{
    edgeSobel_fn_t *edgeSobel = SWITCH_C_ASM ( config, edgeSobel_c, edgeSobel_asm ) ;
    buffer_info_t info = config->src;
    edgeSobel(info.bytes, config->dst.bytes, info.width, info.height, info.width_with_padding,
                config->dst.width_with_padding);
}

void ayuda_edgeSobel()
{
    printf ( "       * edgeSobel\n" );
    printf ( "           Parámetros     : \n"
             "                         no tiene\n");
    printf ( "           Ejemplo de uso : \n"
             "                         edgeSobel -i c facil.bmp\n" );
}

DEFINIR_FILTRO(edgeSobel)

