

SRCFILES = lancelot.asm copyscreenROM.asm game_keys.asm misc_oz.asm printany.asm
OFILES = $(SRCFILES:.asm=.o)

all: lancelot.63

lancelot.bin: $(OFILES)
	z88dk-z80asm -b -o$@ $^

romhdr.bin: romhdr.asm
	z88dk-z80asm -b -o$@ $^

%.o: %.asm
	zcc +z88 -c $^

lancelot.63: util/rompacker lancelot.bin romhdr.bin
	util/rompacker $@ 16384 lancelot.bin:53000 assets/lance_rom.scr:58180 assets/lance_rom.dat:59200 romhdr.bin:65472

util/rompacker:
	$(MAKE) -C util

clean:
	$(RM) -f *.o lancelot.bin romhdr.bin lancelot.63 rompacker lancelot.app
	$(MAKE) -C util clean
	
