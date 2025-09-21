# Adjust OpenBLAS_DIR relative to this folder
OPENBLAS_DIR = ../../openblas/lib
OPENBLAS_LIB = $(OPENBLAS_DIR)/libopenblas.a

CC     = clang
FC     = gfortran
CFLAGS = -O0 -g -fno-omit-frame-pointer -fno-inline-functions

TARGET = dsyevd_openblas
OUTPUT_DIR = ../output

# Default OBJDUMP (can be overridden via environment)
OBJDUMP ?= /opt/homebrew/opt/llvm/bin/llvm-objdump
OBJDUMP_OPTS =

.PHONY: all clean disasm disasm_sym

all: $(TARGET)

# Link with OpenBLAS (contains both BLAS and LAPACK)
$(TARGET): dsyevd_driver.o $(OPENBLAS_LIB)
	$(FC) $^ -lm -o $@

dsyevd_driver.o: dsyevd.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(TARGET) dsyevd_driver.o
	rm -rf $(OUTPUT_DIR)

# Batch disassembly into ./output (switch to OpenBLAS)
disasm:
	mkdir -p $(OUTPUT_DIR)
	OPENBLAS_LIB=$(OPENBLAS_LIB) OBJDUMP=$(OBJDUMP) OBJDUMP_OPTS=$(OBJDUMP_OPTS) \
		./disassemble_openblas.sh
	@echo "Artifacts in $(OUTPUT_DIR)/"

## Optional: also export symbol tables
#disasm_sym:
#	mkdir -p $(OUTPUT_DIR)
#	OPENBLAS_LIB=$(OPENBLAS_LIB) OBJDUMP=$(OBJDUMP) \
#		./disassemble_symbols_openblas.sh
#	@echo "Symbols in $(OUTPUT_DIR)/"
