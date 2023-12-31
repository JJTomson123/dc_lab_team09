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
        int_list.append(number % 65536 // 256)
        number = number // 65536
    return ilts(int_list)

opcode = {
    "add"  : 0,
    "sub"  : 1,
    "mul"  : 2,
    "load" : 4,
    "store": 5
}

assert len(argv) == 3
s = Serial(
    port=argv[2],
    baudrate=115200,
    bytesize=EIGHTBITS,
    parity=PARITY_NONE,
    stopbits=STOPBITS_ONE,
    xonxoff=False,
    rtscts=False
)

with open(argv[1], 'r') as fp_inst, open('bytecode.bin', 'wb') as fp_o_bc, open('dat.bin', 'wb') as fp_o_data, open('gold.bin', 'wb') as fp_o_gold:

    variable_bytes = [""] * 16
    variables = [0] * 16
    variabe_sizes = [0] * 16
    for inst in fp_inst:
        inst = inst.strip().split(' ')
        if inst[0] == "store":
            index = int(inst[1])
            size = int(inst[2])
            print "store variable",
            print index,
            print "of size",
            print size,
            print "words"
            variabe_sizes[index] = size
            while (True):
                variable_bytes[index] = os.urandom(size * 2)
                if (ord(variable_bytes[index][size * 2 - 1]) != 0): break
            variables[index] = bti(variable_bytes[index])
            inst_bytes = ilts([opcode[inst[0]] * 16 + index, size % 256, size // 256]) + variable_bytes[index]
            fp_o_bc.write(inst_bytes)
            s.write(inst_bytes)
        elif inst[0] == "load":
            index = int(inst[1])
            inst_bytes = ilts([opcode[inst[0]] * 16 + index])
            fp_o_bc.write(inst_bytes)
            s.write(inst_bytes)
            size = s.read(2)
            fp_o_data.write(size)
            size = ord(size[0]) + ord(size[1]) * 256
            print "load variable",
            print index,
            print "of size",
            print size,
            print "words"
            if (size < len(variable_bytes[index]) / 2):
                print "Error! size mismatch!"
            received = s.read(size * 2)
            fp_o_data.write(received)
            for i, (gold_byte, received_byte) in enumerate(zip(variable_bytes[index], received)):
                if (received_byte != gold_byte):
                    print "Error! At byte",
                    print i,
                    print ". Received:",
                    print ord(received_byte),
                    print ", Golden:",
                    print ord(gold_byte)
            size = len(variable_bytes[index]) / 2
            fp_o_gold.write(ilts([size % 256, size // 256]))
            fp_o_gold.write(variable_bytes[index])
        elif inst[0] == "add" or inst[0] == "sub" or inst[0] == "mul":
            x3 = int(inst[1])
            x1 = int(inst[2])
            x2 = int(inst[3])
            print "save variables",
            print x1,
            print inst[0],
            print x2,
            print "to variable",
            print x3
            inst_bytes = ilts([opcode[inst[0]] * 16 + x3, x1 * 16 + x2])
            fp_o_bc.write(inst_bytes)
            s.write(inst_bytes)
            if   inst[0] == "add": variables[x3] = variables[x1] + variables[x2]
            elif inst[0] == "sub": variables[x3] = variables[x1] - variables[x2]
            elif inst[0] == "mul": variables[x3] = variables[x1] * variables[x2]
            variable_bytes[x3] = its(variables[x3])
            # print variables[x3]

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
