"""
foo bar
baz gazonk
"""
a = ("foo", "bar")
print a[-2], a[-1]
a[-1] = "gazonk"
a[-2] = "baz"
print a[-2], a[-1]