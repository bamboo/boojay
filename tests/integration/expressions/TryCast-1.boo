"""
foo
foo
null
"""
def sysout(o):
	if o is null:
		print "null"
	if o is not null:
		print o

o as object = "foo"
s as string = o
sysout s
sysout o as string

i = o as java.lang.Integer
sysout i
