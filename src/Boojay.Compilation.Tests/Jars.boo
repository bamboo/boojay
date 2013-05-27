namespace Boojay.Compilation.Tests

import java.io
import java.util.zip
import Boo.Adt

data Entry(name as string, content as (byte) = array of byte(0))

def generateTempJar(entries as string*):
	return generateTempJar(readFileEntries(entries))

def generateTempJar(entries as Entry*):
	jar = System.IO.Path.GetTempFileName()
	generateJar jar, entries
	return jar

def generateJar(jar as string, entries as string*):
	generateJar jar, readFileEntries(entries)
	
def generateJar(jar as string, entries as Entry*):  
	zos = ZipOutputStream(fos = FileOutputStream(jar))
	for entry in entries:
		zos.putNextEntry(ZipEntry(entry.name))
		zos.write(entry.content)
		zos.closeEntry()
	zos.close()
	fos.close()
	
def readFileEntries(files as string*):
	for file in files: 
		yield Entry(file, System.IO.File.ReadAllBytes(file))
