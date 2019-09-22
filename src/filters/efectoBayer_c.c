#include <stdio.h>
#include <math.h>
#include "../tp2.h"
#include "../helper/utils.h"

void efectoBayer_c(
    unsigned char *src,
    unsigned char *dst,
    int width,
    int height,
    int src_row_size,
    int dst_row_size)
{
    bgra_t (*src_matrix)[(src_row_size+3)/4] = (bgra_t (*)[(src_row_size+3)/4]) src;
    bgra_t (*dst_matrix)[(dst_row_size+3)/4] = (bgra_t (*)[(dst_row_size+3)/4]) dst;

    for (int i = 0; i < height/8; i++) {
        for (int j = 0; j < width/8; j++) {

            for (int ii = 0; ii < 4; ii++) {
                for (int jj = 0; jj < 4; jj++) {
                    dst_matrix[i*8+ii][j*8+jj].b = 0;
                    dst_matrix[i*8+ii][j*8+jj].g = src_matrix[i*8+ii][j*8+jj].g;
                    dst_matrix[i*8+ii][j*8+jj].r = 0;
                    dst_matrix[i*8+ii][j*8+jj].a = 255;
                }
            }

            for (int ii = 0; ii < 4; ii++) {
                for (int jj = 0; jj < 4; jj++) {
                    dst_matrix[i*8+ii+4][j*8+jj+4].b = 0;
                    dst_matrix[i*8+ii+4][j*8+jj+4].g = src_matrix[i*8+ii+4][j*8+jj+4].g;
                    dst_matrix[i*8+ii+4][j*8+jj+4].r = 0;
                    dst_matrix[i*8+ii+4][j*8+jj+4].a = 255;
                }
            }

            for (int ii = 0; ii < 4; ii++) {
                for (int jj = 0; jj < 4; jj++) {
                    dst_matrix[i*8+ii+4][j*8+jj].b = 0;
                    dst_matrix[i*8+ii+4][j*8+jj].g = 0;
                    dst_matrix[i*8+ii+4][j*8+jj].r = src_matrix[i*8+ii+4][j*8+jj].r;
                    dst_matrix[i*8+ii+4][j*8+jj].a = 255;
                }
            }

            for (int ii = 0; ii < 4; ii++) {
                for (int jj = 0; jj < 4; jj++) {
                    dst_matrix[i*8+ii][j*8+jj+4].b = src_matrix[i*8+ii][j*8+jj+4].b;
                    dst_matrix[i*8+ii][j*8+jj+4].g = 0;
                    dst_matrix[i*8+ii][j*8+jj+4].r = 0;
                    dst_matrix[i*8+ii][j*8+jj+4].a = 255;
                }
            }
        }
    }
}
