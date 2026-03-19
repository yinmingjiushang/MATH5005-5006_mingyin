# ----------------------------
# lapack_build/Makefile
# Build Reference LAPACK from source (static libs).
# Usage:
#   make            # fetch + configure + build
#   make install    # optional, installs into ./install
#   make clean      # clean build tree
#   make distclean  # remove build + install
#   make check      # environment sanity check
# ----------------------------

LAPACK_REPO = https://github.com/Reference-LAPACK/lapack.git
SRC_DIR     = LAPACK_src
BUILD_DIR   = build
INSTALL_DIR = install

# Build configuration
BUILD_TYPE  = Release             # Debug / Release
GENERATOR   = Ninja               # Ninja or "Unix Makefiles"
TOOLCHAIN   = scripts/toolchain.cmake

.PHONY: all fetch configure build install clean distclean info check

all: fetch configure build info

info:
	@echo "---- LAPACK build info ----"
	@echo "SRC_DIR     = $(SRC_DIR)"
	@echo "BUILD_DIR   = $(BUILD_DIR)"
	@echo "INSTALL_DIR = $(INSTALL_DIR)"
	@echo "BUILD_TYPE  = $(BUILD_TYPE)"
	@echo "GENERATOR   = $(GENERATOR)"
	@echo "TOOLCHAIN   = $(TOOLCHAIN)"

# 1) Clone once
fetch:
	@[ -d $(SRC_DIR) ] || git clone --depth=1 $(LAPACK_REPO) $(SRC_DIR)

# 2) Configure (static libs, no tests)
configure: fetch
	@mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && cmake \
		-G $(GENERATOR) \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DCMAKE_TOOLCHAIN_FILE=../$(TOOLCHAIN) \
		-DBUILD_SHARED_LIBS=OFF \
		-DBUILD_TESTING=OFF \
		-DLAPACKE=OFF \
		../$(SRC_DIR)

# 3) Build
build:
	@cmake --build $(BUILD_DIR) --parallel

# 4) Optional install
install:
	@cmake --install $(BUILD_DIR) --prefix $(abspath $(INSTALL_DIR))

clean:
	@cmake --build $(BUILD_DIR) --target clean || true

distclean:
	@rm -rf $(BUILD_DIR) $(INSTALL_DIR)

check:
	@bash scripts/env_check.sh
