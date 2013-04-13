"""
a
"""
namespace autocasting

def pchar(c as char):
	print c

def pboxed(o):
	pchar o

pboxed char('a')
