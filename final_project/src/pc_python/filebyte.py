
newFile = open("./final_project/src/pc_python/golden/tb_1.bin","wb")
newFileBytes = bytes.fromhex("50 02 00 5a47 44ff 40")

newFileByteArray = bytearray(newFileBytes)


newFile.write(newFileByteArray)
print(newFileByteArray)