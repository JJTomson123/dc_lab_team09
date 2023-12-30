#!/usr/bin/env python
from serial import Serial, EIGHTBITS, PARITY_NONE, STOPBITS_ONE
from sys import argv
import os

def ilts(array):
    return "".join(chr(i) for i in array)

def bti(string):
    return sum(ord(byte) * 256**i for i, byte in enumerate(string))

def its(number):
    int_list = []
    while (number != 0): 
        int_list.append(number % 256)
        number = number // 256
    return ilts(int_list)

opcode = {
    "add"  : 0,
    "sub"  : 1,
    "mul"  : 2,
    "load" : 4,
    "store": 5
}

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

with open('tb_2.txt', 'r') as fp_inst, open('bytecode_2.bin', 'wb') as fp_o_bc, open('dat2.bin', 'wb') as fp_o_data, open('gold2.bin', 'wb') as fp_o_gold:

    variable_bytes = [""] * 16
    variables = [0] * 16
    variabe_sizes = [0] * 16
    for inst in fp_inst:
        inst = inst.strip().split(' ')
        if inst[0] == "store":
            index = int(inst[1])
            size = int(inst[2])
            variabe_sizes[index] = size
            variable_bytes[index] = os.urandom(size * 2)
            variables[index] = bti(variable_bytes[index])
            inst_bytes = ilts([opcode[inst[0]] * 16 + index, size % 256, size // 256]) + variable_bytes[index]
            # for byte in inst_bytes: print ord(byte),
            # print variables[index]
            fp_o_bc.write(inst_bytes)
            s.write(inst_bytes)
        elif inst[0] == "load":
            index = int(inst[1])
            inst_bytes = ilts([opcode[inst[0]] * 16 + index])
            # for byte in inst_bytes: print ord(byte),
            # print
            fp_o_bc.write(inst_bytes)
            s.write(inst_bytes)
            size = s.read(2)
            fp_o_data.write(size)
            size = ord(size[0]) + ord(size[1]) * 256
            variable_bytes[index] = s.read(size * 2)
            fp_o_data.write(variable_bytes[index])
        elif inst[0] == "add" or inst[0] == "sub" or inst[0] == "mul":
            x3 = int(inst[1])
            x1 = int(inst[2])
            x2 = int(inst[3])
            inst_bytes = ilts([opcode[inst[0]] * 16 + x3, x1 * 16 + x2])
            fp_o_bc.write(inst_bytes)
            s.write(inst_bytes)
            if inst[0] == "add": fp_o_gold.write(its(variables[x1] + variables[x2]))
            elif inst[0] == "sub": fp_o_gold.write(its(variables[x1] - variables[x2]))
            elif inst[0] == "mul": fp_o_gold.write(its(variables[x1] * variables[x2]))

    # s.write(i_data)
    # print("Instructions written")
    # dec = s.read(2)
    # print("Variable size received, size = ")
    # fp_o_data.write(dec)
    # dec = [ord(byte) for byte in dec]
    # print(dec)
    # var_size = dec[0] + dec[1] * 256
    # print(var_size)
    # dec = s.read(var_size * 2)
    # print("Result received")
    # fp_o_data.write(dec)

    # fp_i_data.close()
    # fp_o_data.close()
