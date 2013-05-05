"""
1
2
3
"""
namespace arrays

class E:
	public value as int
	
a = array of E(3)
for i in range(len(a)):
	assert a[i] is null
	a[i] = E(value: i + 1)
	print a[i].value