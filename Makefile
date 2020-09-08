$DEPURA=1
PATHAUX=utils/funcoes_auxiliares/
PATHTABELA=utils/tabela_simbolos/
PATHPILHAVARIAVEL=utils/pilha_variaveis/
PATHPILHAROTULO=utils/pilha_rotulos/


compilador: lex.yy.c y.tab.c compilador.o tabela_simbolos.o pilha_variaveis.o pilha_rotulos.o compilador.h
	gcc lex.yy.c compilador.tab.c compilador.o tabela_simbolos.o pilha_variaveis.o pilha_rotulos.o -o compilador -ll -ly -lc -I utils/funcoes_auxiliares

lex.yy.c: compilador.l compilador.h
	flex compilador.l

y.tab.c: compilador.y compilador.h
	bison compilador.y -d -v

compilador.o : compilador.h $(PATHAUX)compiladorF.c $(PATHAUX)compiladorF.h
	gcc -c utils/funcoes_auxiliares/compiladorF.c -o compilador.o 

tabela_simbolos.o : $(PATHTABELA)tabela_simbolos.c $(PATHTABELA)tabela_simbolos.h
	gcc -c utils/tabela_simbolos/tabela_simbolos.c -o tabela_simbolos.o

pilha_variaveis.o : $(PATHPILHAVARIAVEL)pilha_variaveis.c $(PATHPILHAVARIAVEL)pilha_variaveis.h
	gcc -c utils/pilha_variaveis/pilha_variaveis.c -o pilha_variaveis.o

pilha_rotulos.o : $(PATHPILHAROTULO)pilha_rotulos.c $(PATHPILHAROTULO)pilha_rotulos.h
	gcc -c utils/pilha_rotulos/pilha_rotulos.c -o pilha_rotulos.o

clean : 
	rm -f compilador.tab.* lex.yy.c

purge:
	rm -f compilador.tab.* lex.yy.c MEPA *.o *.output compilador