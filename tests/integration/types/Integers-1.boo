"""
-42
-1
0
42
128
255
256
true
false
true
42
"""
import java.lang

class I:
	public value as int

def sysout(i as int):
	System.out.println(i)

sysout -42
sysout -1
sysout 0
sysout 42
sysout 128
sysout 255
sysout 256

print 42 == (21*2)
print 41 == (21*2)
print 41 != (21*2)
print I(value: 42).value