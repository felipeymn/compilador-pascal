$DEPURA=1
PATHAUX=utils/funcoes_auxiliares/
PATHTABELA=utils/tabela_simbolos/

compilador: lex.yy.c y.tab.c compilador.o tabela_simbolos.o compilador.h
	gcc lex.yy.c compilador.tab.c compilador.o tabela_simbolos.o -o compilador -ll -ly -lc -I utils/funcoes_auxiliares

lex.yy.c: compilador.l compilador.h
	flex compilador.l

y.tab.c: compilador.y compilador.h
	bison compilador.y -d -v

compilador.o : compilador.h $(PATHAUX)compiladorF.c $(PATHAUX)compiladorF.h
	gcc -c utils/funcoes_auxiliares/compiladorF.c -o compilador.o 

tabela_simbolos.o : $(PATHTABELA)tabela_simbolos.c $(PATHTABELA)tabela_simbolos.h
	gcc -c utils/tabela_simbolos/tabela_simbolos.c -o tabela_simbolos.o

clean : 
	rm -f compilador.tab.* lex.yy.c

purge:
	rm -f compilador.tab.* lex.yy.c MEPA *.o *.output compilador