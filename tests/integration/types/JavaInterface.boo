"""
running
"""
import java.lang(Runnable)

class R(Runnable):
	def run():
		print 'running'
		
def run(runnable as Runnable):
	runnable.run()
	
run R()