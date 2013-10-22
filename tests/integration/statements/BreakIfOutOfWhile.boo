"""
0
1
0
0
1
0
1
2
0
1
"""
i = 0
while i < 3:
	print i
	break if i > 0
	++i
	
i = 0
while i < 3:
	print i
	j = 0
	while j < i + 1:
		print j
		break if j > 0
		++j
	++i