
// Testar se funciona corretamente o empilhamento de par�metros
// passados por valor ou por refer�ncia.


%{
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include "compilador.h"


unsigned int num_vars;
Tabela *tab_simb;
EnderecoLexico end_lex;
char token_atual[TAM_TOKEN];

%}

%token PROGRAM ABRE_PARENTESES FECHA_PARENTESES 
%token VIRGULA PONTO_E_VIRGULA DOIS_PONTOS PONTO
%token T_BEGIN T_END VAR IDENT ATRIBUICAO
/*** Aula 2  ***/
%token LABEL TYPE ARRAY OF PROCEDURE FUNCTION
%token IF ELSE WHILE DO OR DIV NOT NUMERO
%token ADICAO SUBTRACAO MULTIPLICACAO DIVISAO
%%

programa    :{ 
             geraCodigo (NULL, "INPP"); 
             }
             PROGRAM IDENT 
             ABRE_PARENTESES lista_idents FECHA_PARENTESES PONTO_E_VIRGULA
             bloco PONTO {
             geraCodigo (NULL, "PARA"); 
             }
;

bloco       : 
              parte_declara_vars
              { 
              }

              comando_composto 
;




parte_declara_vars:  var 
;

var         : { } VAR declara_vars
            |
;

declara_vars: declara_vars declara_var 
            | declara_var 
;

declara_var : { } 
              lista_id_var DOIS_PONTOS 
              tipo 
              {              
                 geraCodigo (NULL, "AMEM"); 
              }
              PONTO_E_VIRGULA
;

tipo        : IDENT {
               /* Recebe identificador do tipo em token
                  Percorre a tabela preenchendo as num_vars anteriores */
               define_tipo(tab_simb, token, num_vars);
               num_vars = 0;
            }
;

lista_id_var:  lista_id_var VIRGULA IDENT { 
               /* Insere simbolo (var) na tabela mantendo tipo indefinido */
               strncpy(token_atual, token, TAM_TOKEN);
               insere(tab_simb, cria_simbolo(token_atual, "undefined", end_lex));
               end_lex.deslocamento++;
               num_vars++;
}
            | IDENT {              
               /* Insere simbolo (var) na tabela mantendo tipo indefinido */
               strncpy(token_atual, token, TAM_TOKEN);
               insere(tab_simb, cria_simbolo(token, "undefined", end_lex));
               end_lex.deslocamento++;
               num_vars++;
            }
;

lista_idents: lista_idents VIRGULA IDENT  
            | IDENT 
;

comando_composto: T_BEGIN comandos T_END 

comandos: atribuicao |
;

atribuicao: IDENT {
   if (busca(tab_simb, token) == NULL) {
       char err_atrib[100] = "atribuicao invalida: variavel '";
       strcat(err_atrib, token);
       strcat(err_atrib, "' nao existe");
       imprimeErro(err_atrib);
   }
} ATRIBUICAO lista_atribuicao PONTO_E_VIRGULA 
;

lista_atribuicao: lista_atribuicao operacao const_ou_var | const_ou_var
;

const_ou_var: IDENT {
      if (busca(tab_simb, token) == NULL) {
      char err_atrib[100] = "atribuicao invalida: variavel '";
      strcat(err_atrib, token);
      strcat(err_atrib, "' nao existe");
      imprimeErro(err_atrib);
   } 
} | NUMERO {
   geraCodigo(NULL, "CRCT");
}
;

operacao: 
     ADICAO        { geraCodigo(NULL, "SOMA"); } 
   | SUBTRACAO     { geraCodigo(NULL, "SUBT"); }
   | MULTIPLICACAO { geraCodigo(NULL, "MULT"); } 
   | DIVISAO       { geraCodigo(NULL, "DIVI"); }
;

%%

main (int argc, char** argv) {
   FILE* fp;
   extern FILE* yyin;

   if (argc<2 || argc>2) {
         printf("usage compilador <arq>a %d\n", argc);
         return(-1);
      }

   fp=fopen (argv[1], "r");
   if (fp == NULL) {
      printf("usage compilador <arq>b\n");
      return(-1);
   }


/* -------------------------------------------------------------------
 *  Inicia a Tabela de S�mbolos
 * ------------------------------------------------------------------- */
   tab_simb = cria_tabela();
   num_vars = 0;
   end_lex.nivel = 0;
   end_lex.deslocamento = 0;
   yyin=fp;
   yyparse();
   imprime_tabela(tab_simb);

   return 0;
}

