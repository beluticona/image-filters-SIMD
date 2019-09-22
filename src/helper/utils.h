#ifndef __UTILS__H__
#define __UTILS__H__

unsigned char sat(int a);

void copiar_bordes (
	unsigned char *src,
	unsigned char *dst,
	int m,
	int n,
	int row_size
);

void voltear_horizontal (
	unsigned char *src,
	unsigned char *dst,
	int m,
	int n,
	int row_size
);

void pintar_bordes_negro(unsigned char *frame, int m, int n);

void guardar_mensaje_en_archivo(configuracion_t *config, unsigned char *mensaje_salida);

const char *basename(const char *path);

#endif /* !__UTILS__H__ */

