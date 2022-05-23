#!/bin/python3
import serial
import time

f = open("tmp/unified.bin", "rb")

ba = bytearray()
while True:
    b = f.read(1)
    if b == b'':
        break
    ba += b

f.close()
ba = ba[4096:]
size = len(ba)
print(hex(size))
uart = serial.Serial(port="/dev/ttyUSB1", baudrate=128000)

bsize = int.to_bytes(size, 4, byteorder='big')
uart.write(bsize)
i = 0
while i < len(ba):
    if i % 2048 == 0:
        print("Writing " + hex(i) + " bytes...")
        time.sleep(1)
    uart.write(ba[i:i+1])
    i += 1
uart.close()