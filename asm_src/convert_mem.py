#!/bin/python3

TOTAL = 4096

text=open("text.bin", "rb")
memfile = open("text.mem", "w")
cnt = 0
arr = list()
while True:
    data = text.read(1)
    if not data:
        break
    memfile.write(data.hex())
    memfile.write(" ")
    cnt = cnt + 1
    if cnt % 4 == 0:
        memfile.write("\n")
while cnt < TOTAL:
    memfile.write("00 ")
    cnt = cnt + 1
    if cnt % 4 == 0:
        memfile.write("\n")
text.close()
memfile.close()