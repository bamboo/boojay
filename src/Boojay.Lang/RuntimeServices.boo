namespace Boojay.Lang

import java.lang

static class RuntimeServices:
	
	def ToBool(o) as bool:
		if o is null:
			return false
		boolean = o as Boolean
		if boolean is not null:
			return boolean.booleanValue()
		s = o as string
		if s is not null:
			return len(s) != 0
		return true
	
	def UnboxChar(o):
		return cast(Character, o).charValue()
		
	def BoxChar(ch as char):
		return Character(ch)
		
	def UnboxInt32(o):
		return cast(Number, o).intValue()
	
	def EqualityOperator(x, y):
		if x is y: return true
		if x is null: return false
		return x.Equals(y)
		
	def GetEnumerable(source) as System.Collections.IEnumerable:
		if source isa Enumerable: # Enumerable is the java representation of IEnumerable
			return source
		if source isa Iterable:
			return enumerableForIterable(source)
		if source isa string:
			return enumerableForString(source)
		if source isa (int):
			return enumerableForIntArray(source)
		raise IllegalArgumentException("source")
		
	def enumerableForIntArray(a as (int)):
		for i in a:
			yield i
			
	def enumerableForString(s as string):
		i = 0
		while i < len(s):
			yield s[i]
			++i
			
	def enumerableForIterable(iterable as Iterable):
		iterator = iterable.iterator()
		while iterator.hasNext():
			yield iterator.next()