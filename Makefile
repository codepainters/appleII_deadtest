SOURCE = apple2.asm

MAME = $(HOME)/Downloads/mame0257-arm64/mame
# OUTPUT = 341-0020-00.f8

OUTPUT = apple2.bin

ASSEMBLE_xa = xa -C -M -o
ASSEMBLE_sa = cl65 -t apple2 -C a2_f8rom.cfg -I ./inc -l $(<:%.asm=%.lst)

ASSEMBLE = $(ASSEMBLE_sa)

RAMSIZE = 16K

CHECKSUM = sha1sum --tag

# all: $(OUTPUT)
all: apple2.bin

%.bin: %.asm Makefile
	$(ASSEMBLE) -o $@ $<
	-@$(CHECKSUM) $@

# $(ASSEMBLE) -o $@ $<


apple2.bin: inc/marchu_zpsp.asm inc/marchu.asm inc/a2console.asm inc/a2macros.inc inc/a2constants.inc

# $(OUTPUT): $(SOURCE) Makefile
# 	$(ASSEMBLE) -o $(OUTPUT) $(SOURCE)
# 	-@md5 $(OUTPUT)

debug: $(OUTPUT)
	ln -sf $< 341-0020-00.f8
	$(MAME) apple2p -ramsize $(RAMSIZE) -keepaspect -volume -10 -window -resolution 800x600 -skip_gameinfo -debug -debugger osx

run: $(OUTPUT)
	ln -sf $< 341-0020-00.f8
	$(MAME) apple2p -ramsize $(RAMSIZE) -keepaspect -volume -10 -window -resolution 800x600 -skip_gameinfo -debug -debugger none

.PHONY: all test