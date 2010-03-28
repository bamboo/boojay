namespace Boojay.Compilation.Tests

import java.io
import java.util.zip

def generateJar(jar as string, entries as string*):
	zos = ZipOutputStream(fos = FileOutputStream(jar))
	for entryName in entries:
		zos.putNextEntry(ZipEntry(entryName))
		zos.write(System.IO.File.ReadAllBytes(entryName))
		zos.closeEntry()
	zos.close()
	fos.close()