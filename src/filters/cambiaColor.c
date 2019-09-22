#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "../tp2.h"

void cambiaColor_asm (unsigned char *src, unsigned char *dst, int cols, int filas,
                      int src_row_size, int dst_row_size,
                      unsigned char Nr, unsigned char Ng, unsigned char Nb,
                      unsigned char Or, unsigned char Og, unsigned char Ob, int lim);

void cambiaColor_c   (unsigned char *src, unsigned char *dst, int cols, int filas,
                      int src_row_size, int dst_row_size,
                      unsigned char Nr, unsigned char Ng, unsigned char Nb,
                      unsigned char Or, unsigned char Og, unsigned char Ob, int lim);

typedef void (cambiaColor_fn_t) (unsigned char*, unsigned char*, int, int, int, int,
                                 unsigned char, unsigned char, unsigned char,
                                 unsigned char, unsigned char, unsigned char, int);

unsigned char Nr;
unsigned char Ng;
unsigned char Nb;
unsigned char Or;
unsigned char Og;
unsigned char Ob;
int lim;

void leer_params_cambiaColor(configuracion_t *config, int argc, char *argv[]) {

    Nr = atoi(argv[argc - 7]);
    Ng = atoi(argv[argc - 6]);
    Nb = atoi(argv[argc - 5]);
    Or = atoi(argv[argc - 4]);
    Og = atoi(argv[argc - 3]);
    Ob = atoi(argv[argc - 2]);
    lim = atoi(argv[argc - 1]);
}

void aplicar_cambiaColor(configuracion_t *config)
{
    cambiaColor_fn_t *cambiaColor = SWITCH_C_ASM ( config, cambiaColor_c, cambiaColor_asm ) ;
    buffer_info_t info = config->src;
    cambiaColor(info.bytes, config->dst.bytes, info.width, info.height, info.width_with_padding,
                config->dst.width_with_padding, Nr, Ng, Nb, Or, Og, Ob, lim);
}

void ayuda_cambiaColor()
{
    printf ( "       * cambiaColor\n" );
    printf ( "           Parámetros     : \n"
             "                         Nr Ng Nb Or Og Ob lim\n"
             "                         N: componentes del nuevo color\n"
             "                         O: componentes del color a cambiar\n"
             "                         lim: diferencia color máxima\n");
    printf ( "           Ejemplo de uso : \n"
             "                         cambiaColor -i c facil.bmp 0 0 0 255 255 255 100\n" );
}

DEFINIR_FILTRO(cambiaColor)

