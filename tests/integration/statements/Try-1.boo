"""
caught!
should have passed here first!
should end up here!

"""
import java.lang
	
try:
	raise RuntimeException("caught!")
	print "should not get here!"
except x:
	print x.getMessage()
ensure:
	print "should have passed here first!"
print "should end up here!"