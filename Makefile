NAME = template

LDCFG = linker.cfg

CAFLAGS = -g -t nes $(EXTRA_CAFLAGS)
LDFLAGS = -C $(LDCFG)

CHRUTIL = ../go-nes/chrutil

.PHONY: all env clean distclean

all: build/$(NAME).nes

env: $(CHRUTIL) | build/

clean:
	$(if $(wildcard build/*),-,@echo )rm build/*

distclean:
	-[ ! -d build ] || rm -r build/

build/main.o: *.asm *.inc
#build/main.o: build/font.chr

$(addprefix build/$(NAME).,nes dbg map)&: build/main.o $(LDCFG) | build/
	ld65 -o $(basename $@).nes.tmp $(LDFLAGS) \
		--dbgfile $(basename $@).dbg -m $(basename $@).map \
		$(filter-out $(LDCFG),$^)
	mv $(basename $@).nes.tmp $(basename $@).nes

build/%.o: %.asm | build/
	ca65 $(CAFLAGS) -o $@ $<

build/%.chr: images/%.bmp $(CHRUTIL) | build/
	$(CHRUTIL) $(CHRFLAGS) -o $@ $<

# Do not treat any files as intermediate; they should not be deleted.
.NOTINTERMEDIATE:
# Do not (try to) delete the created dir on error or if intermediate.
.PRECIOUS: %/
%/:
	mkdir -p $@
