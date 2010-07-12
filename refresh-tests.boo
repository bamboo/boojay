"""
Finds all test cases under tests/integration and generates runTestCase calls
in IntegrationTest.Generated.boo

First line of test case can specify a nunit attribute to go with it:
	* "// ignore reason" for [Ignore("reason")]
	* "// category name" for [Category("name")] 
"""
import System.IO
import Boo.Lang.PatternMatching

def testCaseName(fname as string):
	return Path.GetFileNameWithoutExtension(fname).Replace("-", "_")
	
def writeTestCases(writer as TextWriter, baseDir as string):
	count = 0
	for fname in Directory.GetFiles(baseDir):
		continue unless fname.EndsWith(".boo")
		++count		
		writeTestCase(writer, fname)
	for subDir in Directory.GetDirectories(baseDir):
		writeTestCases(writer, subDir)
	print("${count} test cases found in ${baseDir}.")
	
def writeTestCase(writer as TextWriter, fname as string):
	writer.Write("""
	${CategoryAttributeFor(fname)}
	[Test] def ${testCaseName(fname)}():
		runTestCase("${fname.Replace('\\', '/')}")
		""")

def CategoryAttributeFor(testFile as string):
"""
If the first line of the test case file starts with // category CategoryName 
then return a suitable [CategoryName()] attribute.
"""
	match FirstLineOf(testFile):
		case /\/\/\s*ignore\s+(?<reason>.*)/:
			return "[Ignore(\"${reason[0].Value.Trim()}\")]"
		case /\/\/\s*category\s+(?<name>.*)/:
			return "[Category(\"${name[0].Value.Trim()}\")]"
		otherwise:
			return ""
	
def FirstLineOf(fname as string):
	using reader=File.OpenText(fname):
		return reader.ReadLine()
		
using writer = StreamWriter("src/Boojay.Compilation.Tests/IntegrationTest.Generated.boo"):
	writer.Write("""
namespace Boojay.Compilation.Tests

import NUnit.Framework

partial class IntegrationTest:
""")

	writeTestCases(writer, "tests/integration") 
