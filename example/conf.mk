TARGET=example

# Find .c files in src/
# These are the default values, but are included for completeness
SRC=src
EXT=.c

# Link with the math library for sqrt
LINK=m

# Heavily optimize when not in debug mode
FLAGS_NDBG=-o3

# Enable lots of warnings, and treat warnings as errors
WARN=all pedantic extra error

# If we compile with `make ARM=1`, cross compile for arm64.
# This is usually not necessary unless you specifically want to support
# cross compiling for ARM out of the box.
ifeq ($(ARM),1)
  TOOLCHAIN=aarch64-linux-gnu-
  CC=gcc
endif
