#!/bin/python3

from lib2to3.pgen2.token import COMMENT
import sys

from numpy import pad

src = sys.argv[1]
out = sys.argv[2]

# padding: 0x4000
if len(sys.argv) > 3:
    padding = int(sys.argv[3], 16)
else:
    padding = 0

text=open(src, "rb")
memfile = open(out, "w")
cnt = 0
memfile.write("memory_initialization_radix=16;\n")
memfile.write("memory_initialization_vector=\n")
arr = list()

for i in range(0, padding//4):
    arr.append(b"\x00\x00\x00\x00")

while True:
    data = text.read(4)
    if not data:
        break
    arr.append(data[::-1])

for i in range(0, len(arr)):
    memfile.write(arr[i].hex())
    if i != len(arr) -1:
        memfile.write(",\n")
    else:
        memfile.write(";")

text.close()
memfile.close()