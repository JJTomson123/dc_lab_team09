#!/usr/bin/env python
from serial import Serial, EIGHTBITS, PARITY_NONE, STOPBITS_ONE
from sys import argv
import os

def its(array):
    return "".join(chr(i) for i in array)

def bti(string):
    return sum(ord(byte) * 16**i for i, byte in enumerate(string))


assert len(argv) == 2
s = Serial(
    port=argv[1],
    baudrate=115200,
    bytesize=EIGHTBITS,
    parity=PARITY_NONE,
    stopbits=STOPBITS_ONE,
    xonxoff=False,
    rtscts=False
)

fp_i_data = open('golden/tb_1.bin', 'rb')
fp_o_data = open('dec1.bin', 'wb')
assert fp_i_data and fp_o_data

i_data = fp_i_data.read()
assert len(i_data) % 2 == 0
int_list = []


s.write(i_data)
print("Instructions written")
dec = s.read(2)
print("Variable size received, size = ")
fp_o_data.write(dec)
dec = [ord(byte) for byte in dec]
print(dec)
var_size = dec[0] + dec[1] * 256
print(var_size)
dec = s.read(var_size * 2)
print("Result received")
fp_o_data.write(dec)

fp_i_data.close()
fp_o_data.close()
