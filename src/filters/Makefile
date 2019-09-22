# ************************************************************************* #
# Organizacion del Computador II                                            #
#                                                                           #
#   Trabajo Practico 2                                                      #
#                                                                           #
# ************************************************************************* #
ASM = nasm
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	ASMFLAGS64 = -felf64 -g -F dwarf
endif
ifeq ($(UNAME_S),Darwin)
	ASMFLAGS64 = -fmacho64 -g -DDARWIN
endif

ASMFLAGS = $(ASMFLAGS64)

CFLAGS64 ?=-Wall -Wextra -Wno-unused-parameter -no-pie -pedantic -O0 -ggdb
CFLAGS=$(CFLAGS64)

BUILD_DIR = ../build

FILTROS = edgeSobel tresColores cambiaColor efectoBayer

FILTROS_OBJ = $(addsuffix .o, $(FILTROS)) $(addsuffix _asm.o, $(FILTROS)) $(addsuffix _c.o, $(FILTROS))
FILTROS_OBJ_CON_PATH = $(addprefix  $(BUILD_DIR)/, $(FILTROS_OBJ))

.PHONY: filtros clean

filtros: $(FILTROS_OBJ_CON_PATH)

$(BUILD_DIR)/%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/%.o: %.asm
	$(ASM) $(ASMFLAGS) -o $@ $<

clean:
	rm -f $(FILTROS_OBJ_CON_PATH)
