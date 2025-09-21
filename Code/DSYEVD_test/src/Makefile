# Adjust LAPACK_DIR relative to this folder
LAPACK_DIR = ../../LAPACK_build/build/lib
LAPACK_LIB = $(LAPACK_DIR)/liblapack.a
BLAS_LIB   = $(LAPACK_DIR)/libblas.a

CC     = clang
FC     = gfortran
CFLAGS = -O0 -g -fno-omit-frame-pointer -fno-inline-functions

TARGET = dsyevd_ref
OUTPUT_DIR = ../output

.PHONY: all clean disasm disasm_sym

all: $(TARGET)

$(TARGET): dsyevd_driver.o $(LAPACK_LIB) $(BLAS_LIB)
	$(FC) $^ -o $@

dsyevd_driver.o: dsyevd.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(TARGET) dsyevd_driver.o
	rm -rf $(OUTPUT_DIR)

# Batch disassembly into ./output
disasm:
	mkdir -p $(OUTPUT_DIR)
	LAPACK_LIB=$(LAPACK_LIB) OBJDUMP=llvm-objdump OBJDUMP_OPTS= \
		./disassemble.sh
	@echo "Artifacts in $(OUTPUT_DIR)/"

# Optional: also export symbol tables
disasm_sym:
	mkdir -p $(OUTPUT_DIR)
	LAPACK_LIB=$(LAPACK_LIB) ./disassemble_symbols.sh
	@echo "Symbols in $(OUTPUT_DIR)/"
