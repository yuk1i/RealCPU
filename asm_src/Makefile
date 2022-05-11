CC=mipsel-linux-gnu-gcc
AS=mipsel-linux-gnu-as
LD=mipsel-linux-gnu-ld
OBJCOPY=mipsel-linux-gnu-objcopy
OBJDUMP=mipsel-linux-gnu-objdump

# Configures for bin file

TEXT_START_AT=0x0
DATA_START_AT=0x1000

CC_FLAGS=-mips32r6 -Werror -O0 -fno-pic
AS_FLAGS=--alternate -call_nonpic -mno-ginv -mips32r6 -msoft-float --fatal-warnings -O0
LD_FLAGS=--relax -Ttext $(TEXT_START_AT) -Tdata $(DATA_START_AT) --entry main

objs=

.DEFAULT_GOAL := cputest

%:
	@make objs=$@.o dump --no-print-directory
	@echo "\n[*] Compile and dump successfully\n"

%.o : %.c
	@echo "[CC] compile $<"
	@$(CC) $(CC_FLAGS) -c $< -o tmp/$@

%.o : %.s
	@echo "[AS] assemble $<"
	@$(AS) $(AS_FLAGS) $< -o tmp/$@

link: $(objs)
	@echo "[LD] link"
	@cd tmp && \
	mipsel-linux-gnu-ld $(LD_FLAGS) $(objs) && \
	cd ../

dump: link
	@echo "[*]  dump coe"
	@rm -f *.coe tmp/*.bin
	@$(OBJCOPY) --dump-section .text=tmp/text.bin tmp/a.out
	@$(OBJCOPY) --dump-section .data=tmp/data.bin tmp/a.out 
	@python3 convert.py tmp/text.bin text.coe
	@python3 convert.py tmp/data.bin data.coe $(DATA_START_AT)

objdump:
	@$(OBJDUMP) -d -t tmp/a.out
	@echo "\n\n ==== .data section ===="
	@$(OBJDUMP) -s -j .data tmp/a.out

readelf:
	readelf -a a.out

clean:
	@echo "[*] clean done"
	@rm -f a.out *.o tmp/*.bin *.coe tmp/*.o tmp/a.out
