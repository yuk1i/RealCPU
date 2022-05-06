CC=mipsel-linux-gnu-gcc
AS=mipsel-linux-gnu-as
LD=mipsel-linux-gnu-ld
OBJCOPY=mipsel-linux-gnu-objcopy
OBJDUMP=mipsel-linux-gnu-objdump

# Configures for bin file

TEXT_START_AT=0x0
DATA_START_AT=0x1000

AS_FLAGS=--alternate -call_nonpic -mno-ginv -mips32r6 -msoft-float --fatal-warnings -O0
LD_FLAGS=--relax -Ttext $(TEXT_START_AT) -Tdata $(DATA_START_AT) --entry main

objs=

.DEFAULT_GOAL := cputest

%:
	@make objs=$@.o dump
	@echo "\n[*] Compile and dump successfully\n"

%.o : %.s
	@echo "[#] compiling $<"
	$(AS) $(AS_FLAGS) $< -o $@

link: $(objs)
	mipsel-linux-gnu-ld $(LD_FLAGS) $(objs)

dump: link
	rm -f *.coe tmp/*.bin
	$(OBJCOPY) --dump-section .text=tmp/text.bin a.out
	$(OBJCOPY) --dump-section .data=tmp/data.bin a.out 
	python3 convert.py tmp/text.bin text.coe
	python3 convert.py tmp/data.bin data.coe $(DATA_START_AT)

objdump:
	@$(OBJDUMP) -d -t a.out
	@echo "\n\n ==== .data section ===="
	@$(OBJDUMP) -s -j .data a.out

readelf:
	readelf -a a.out

clean:
	rm -f a.out *.o tmp/*.bin *.coe