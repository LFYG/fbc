#lang "fblite"

type UDT
	as integer a, b
end type

dim x as UDT
dim px as UDT ptr = @x

#print "WITH, 1 warning:"

goto with1:
with *px
	with1:
	print .a, .b '' WITH pointer uninitialized
end with
