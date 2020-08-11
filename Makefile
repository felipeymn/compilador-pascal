$DEPURA=1

compilador: lex.yy.c y.tab.c compilador.o compilador.h
	gcc lex.yy.c compilador.tab.c tabela_simbolos/tabela_simbolos.c compilador.o -o compilador -ll -ly -lc -I tabela_simbolos 

lex.yy.c: compilador.l compilador.h
	flex compilador.l

y.tab.c: compilador.y compilador.h
	bison compilador.y -d -v

compilador.o : compilador.h compiladorF.c
	gcc -c compiladorF.c -o compilador.o -I tabela_simbolos

clean : 
	rm -f compilador.tab.* lex.yy.c 
