#!/bin/python3

import sys

src = sys.argv[1]
out = sys.argv[2]

# padding: 0x4000
if len(sys.argv) > 3:
    padding = int(sys.argv[3], 16)
else:
    padding = 0

if len(sys.argv) > 4:
    size = int(sys.argv[4])
else:
    size = 4

text=open(src, "rb")
memfile = open(out, "w")
cnt = 0
memfile.write("memory_initialization_radix=16;\n")
memfile.write("memory_initialization_vector=\n")
arr = list()

for i in range(0, padding//size):
    arr.append(b"\x00" * size)

while True:
    data = text.read(size)
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