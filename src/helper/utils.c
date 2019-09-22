#include <stdio.h>
#include <string.h>

unsigned char sat(int a) {
    if(a > 255) {
        return 255;
    } else {
        if(a < 0 ) {
            return 0;
        } else {
            return a;
        }
    }
}

void copiar_bordes (
	unsigned char *src,
	unsigned char *dst,
	int m,
	int n,
	int row_size
) {
	for(int j = 0; j<n; j++) {
		// superior
		dst[0*row_size+j] = src[0*row_size+j];
		// inferior
		dst[(m-1)*row_size+j] = src[(m-1)*row_size+j];
	}

	for(int i = 0; i<m; i++) {
		// izquierdo
		dst[i*row_size+0] = src[i*row_size+0];
		// derecho
		dst[i*row_size+(n-1)] = src[i*row_size+(n-1)];
	}
}

void voltear_horizontal (
	unsigned char *src,
	unsigned char *dst,
	int m,
	int n,
	int row_size
) {
	unsigned char (*src_matrix)[row_size] = (unsigned char (*)[row_size]) src;
	unsigned char (*dst_matrix)[row_size] = (unsigned char (*)[row_size]) dst;

	for (int i = 0; i<m; i+=1) {
		for (int j = 0; j<n; j+=1) {
			dst_matrix[i][n-j-1] = src_matrix[i][j];
		}
	}
}

void pintar_bordes_negro(unsigned char *frame, int m, int n) {

    for (int i = 0; i < n * 3; i+=1) {
        frame[i] = 0;
        frame[n * 3 + i] = 0;
        frame[n * 6 + i] = 0;
    }

    for (int i = 0; i < m - 3; i+= 1) {
        for (int k = 0; k < 3 * 3; k++) {
             frame[k] = 0;
             frame[n * 3 - 1 - k] = 0;
        }
        frame += n * 3;
    }

    for (int i = 0; i < n * 3; i+=1) {
        frame[i] = 0;
        frame[n * 3 + i] = 0;
        frame[n * 6 + i] = 0;
    }
}


// void guardar_mensaje_en_archivo(configuracion_t *config, unsigned char *mensaje_salida)
// {
// 	char filename[255];
        
//     sprintf(filename,"%s.mensaje.%s.txt",config->archivo_entrada, SWITCH_C_ASM(config, "C", "ASM") );
//     FILE* decoded_txt = fopen(filename,"w");

//     fprintf(decoded_txt,"%s", mensaje_salida);
//     fclose(decoded_txt);
// 	printf ( "  Salida en          : %s\n", filename);
// }

const char *basename(const char *path)
{
    const char *res = strrchr(path, '/');
    if (res != NULL) {
        return res + 1;
    }
    return path;
}

