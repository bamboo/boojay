"""
1 <= 2
2 > 1
1 <= 1
2 <= 2
"""
def test(x as int, y as int):
	if x <= y:
		print "$x <= $y" 
	else:
		print "$x > $y"
	
test 1, 2
test 2, 1
test 1, 1
test 2, 2