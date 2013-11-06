"""
loop 0
0
>0<
loop 1
0
1
>1<
loop 2
0
1
2
>2<
"""
namespace statements

def foo(steps as int):
	print "0"
	if steps < 1:
		return ">0<"
	print "1"
	if steps < 2:
		return ">1<"
	print "2"
	return ">2<"
	
for i in range(3):
	print "loop", i
	print foo(i)