#include <stdio.h>
#include <string.h>

#include "../tp2.h"

void tresColores_asm (unsigned char *src, unsigned char *dst, int width, int height,
                      int src_row_size, int dst_row_size);

void tresColores_c   (unsigned char *src, unsigned char *dst, int width, int height,
                      int src_row_size, int dst_row_size);

typedef void (tresColores_fn_t) (unsigned char*, unsigned char*, int, int, int, int);


void leer_params_tresColores(configuracion_t *config, int argc, char *argv[]) {

}

void aplicar_tresColores(configuracion_t *config)
{
    tresColores_fn_t *tresColores = SWITCH_C_ASM( config, tresColores_c, tresColores_asm );
    buffer_info_t info = config->src;
    tresColores(info.bytes, config->dst.bytes, info.width, info.height, 
            info.width_with_padding, config->dst.width_with_padding);
}

void ayuda_tresColores()
{
    printf ( "       * tresColores\n" );
    printf ( "           Parámetros     : \n"
             "                         no tiene\n");
    printf ( "           Ejemplo de uso : \n"
             "                         tresColores -i c facil.bmp\n" );
}

DEFINIR_FILTRO(tresColores)


