#include <stdio.h>
#include <math.h>
#include "../tp2.h"
#include "../helper/utils.h"

void tresColores_c(
    unsigned char *src,
    unsigned char *dst,
    int width,
    int height,
    int src_row_size,
    int dst_row_size)
{
    bgra_t (*src_matrix)[(src_row_size+3)/4] = (bgra_t (*)[(src_row_size+3)/4]) src;
    bgra_t (*dst_matrix)[(dst_row_size+3)/4] = (bgra_t (*)[(dst_row_size+3)/4]) dst;

    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            unsigned int s = (src_matrix[i][j].b + src_matrix[i][j].g + src_matrix[i][j].r)/3;
            int r = 0, g = 0, b = 0;
            if (s < 85) {
                // ROJO
                r = 244;
                g = 88;
                b = 65;
            }
            else if (s < 170) {
                // VERDE
                r = 0;
                g = 112;
                b = 110;
            }
            else
            {
                // CREMA
                r = 236;
                g = 233;
                b = 214;
            }
            dst_matrix[i][j].b = ( b * 3 + s ) /4;
            dst_matrix[i][j].g = ( g * 3 + s ) /4;
            dst_matrix[i][j].r = ( r * 3 + s ) /4;
            dst_matrix[i][j].a = 255;
        }
    }
}
