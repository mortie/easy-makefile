# Variables from config.mk:
# TARGET: compilation target
#
# TOOLCHAIN: prefix for toolchain: TOOLCHAIN=aarch64-linux-gnu-
# COMPILER: what compiler to use
#     default: $(CC) for EXT=.c, $(CXX) for EXT=.cc
#
# FILES: list of input files
#     default: all files with extension $(EXT) in $(SRC)
# EXT: file extension
#     default: .c
# SRC: directory with source files (only applies if you don't specify FILES)
#     default: src
#
# FLAGS: general flags
# FLAGS_DBG: flags included only when running $(TARGET)-debug
#     default: -g -o0 -DDEBUG
# FLAGS_NDBG: flags included only when not running $(TARGET)-debug
#
# WARN: warning flags
#     default: all pedantic
# LINK: libraries to dynamically link with
# INCLUDE: include directories
# LIBS: libraries to statically link with: libfoo.a
#
# DEPS: additional targets to run before the $(TARGET) step
# JUNK: additional files to be cleaned by the clean target

include config.mk

#
# Defaults
#
ifeq ($(WARN),)
  WARN=all pedantic
endif
ifeq ($(FLAGS_DBG),)
  FLAGS_DBG=-g -o0 -DDEBUG
endif
ifeq ($(EXT),)
  EXT=.c
endif
ifeq ($(SRC),)
  SRC=src
endif
ifeq ($(FILES),)
  FILES=$(shell find $(SRC) -name '*$(EXT)' | sed 's/^.\///')
endif
ifeq ($(COMPILER),)
  ifeq ($(EXT),.cc)
    COMPILER=$(CXX)
  else
    COMPILER=$(CC)
  endif
endif
COMPILER:=$(TOOLCHAIN)$(COMPILER)

#
# Find .o and .d files
#
OFILES=$(patsubst %$(EXT),obj/$(TARGET)/%.o,$(FILES))
DFILES=$(patsubst %$(EXT),dep/$(TARGET)/%.d,$(FILES))

#
# Create FLAGS based on a bunch of variables
#
FLAGS:=$(FLAGS) \
	$(patsubst %,-W%,$(WARN)) \
	$(patsubst %,-I%,$(INCLUDE))
ifeq ($(EXT),.cc)
  FLAGS:=$(FLAGS) $(CXXFLAGS)
else
  FLAGS:=$(FLAGS) $(CFLAGS)
endif
ifeq ($(DEBUG),1)
  FLAGS:=$(FLAGS) $(FLAGS_DBG)
else
  FLAGS:=$(FLAGS) $(FLAGS_NDBG)
endif
FLAGS:=$(strip $(FLAGS))

LINK:=$(patsubst %,-l%,$(LINK))

#
# Compile the binary
#
$(TARGET): $(LIBS) $(OFILES) $(DEPS)
	$(COMPILER) -o $(TARGET) $(OFILES) $(LIBS) $(FLAGS) $(LINK)

#
# Cleanup
#
clean:
	rm -rf obj dep
	rm -f $(TARGET) $(JUNK)

#
# Create .d files
#
dep/$(TARGET)/%.d: %$(EXT)
	@mkdir -p $(@D)
	@printf $(dir obj/$*) > $@
	@$(COMPILER) $(FLAGS) -MM $< -o -  >> $@

#
# Create .o files
#
obj/$(TARGET)/%.o: %$(EXT)
	@mkdir -p $(@D)
	$(COMPILER) $(FLAGS) -o $@ -c $<

#
# Include .d files if we're not in make clean
# We're not using a single make.dep file, because we only know the
# source files, not the headers.
#
ifneq ($(MAKECMDGOALS),clean)
  -include $(DFILES)
endif

.PHONY: clean
