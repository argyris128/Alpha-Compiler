all:
	bison --yacc --defines --output=parser.c parser.y
	flex --outfile=scanner.c al.l
	gcc -o calc scanner.c parser.c SymTable.c Quads.c

clean:
	rm parser.c
	rm scanner.c
	rm parser.h
	rm calc