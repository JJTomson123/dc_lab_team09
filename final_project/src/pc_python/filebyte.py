import os

def its(array):
    return "".join(chr(i) for i in array)

def bti(string):
    return sum(ord(byte) * 16**i for i, byte in enumerate(string))

newFile = open("./final_project/src/pc_python/golden/tb_1.bin","wb")
n1 = 4
n2 = 3
x1_bytes = os.urandom(n1 * 2)
x1 = bti(x1_bytes)
x2_bytes = os.urandom(n2 * 2)
x2 = bti(x2_bytes)
newFileBytes = its([0x50, n1 % 256, n1 // 256]) + x1_bytes + its([0x51, n2 % 256, n2 // 256]) + x2_bytes + its([0x41, 0x40])

newFileByteArray = bytearray(newFileBytes)


newFile.write(newFileByteArray)