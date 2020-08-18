
// Testar se funciona corretamente o empilhamento de par�metros
// passados por valor ou por refer�ncia.


%{
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include "compilador.h"
#include "utils/funcoes_auxiliares/compiladorF.h"


int num_vars;
int num_vars_tipo;
Tabela *tab_simb;
EnderecoLexico end_lex;
char token_atual[TAM_TOKEN];
char instrucao_operador_a[5];
char instrucao_operador_b[5];

Simbolo *variavel;

int yylex();
void yyerror(const char *s);

%}

%token PROGRAM ABRE_PARENTESES FECHA_PARENTESES 
%token VIRGULA PONTO_E_VIRGULA DOIS_PONTOS PONTO
%token T_BEGIN T_END VAR IDENT ATRIBUICAO
/*** Aula 2  ***/
%token LABEL TYPE ARRAY OF PROCEDURE FUNCTION
%token IF ELSE WHILE DO OR DIV NOT NUMERO
%token ADICAO SUBTRACAO MULTIPLICACAO DIVISAO
%token IGUAL DESIGUAL MENOR MENOR_IGUAL MAIOR MAIOR_IGUAL ABRE_COLCHETES FECHA_COLCHETES
%token CONJUNCAO
%%

programa: { 
      geraCodigo (NULL, "INPP");
   }
   PROGRAM IDENT 
   ABRE_PARENTESES lista_idents FECHA_PARENTESES PONTO_E_VIRGULA
   bloco PONTO {
      geraCodigo (NULL, "PARA"); 
   }
;

bloco: parte_declara_vars comando_composto 
;

parte_declara_vars:  VAR declara_vars {
      /* Gera unica instrucao AMEM para todas as variaveis do nivel lexico atual */
      geraCodigo (NULL, formataInstrucaoComposta("AMEM", num_vars));
      num_vars = 0;
   }
   |
;

declara_vars: declara_vars declara_var 
            | declara_var 
;

declara_var: lista_id_var DOIS_PONTOS tipo PONTO_E_VIRGULA
;

tipo: IDENT {
      /* Define tipo das variaveis com base no acumulador num_vars_tipo */
      define_tipo(tab_simb, token, num_vars_tipo);
      num_vars_tipo = 0;
   }
;

lista_id_var: lista_id_var VIRGULA IDENT { 
      /* Insere simbolo (var) na tabela mantendo tipo indefinido */
      strncpy(token_atual, token, TAM_TOKEN);
      insere(tab_simb, cria_simbolo(token_atual, "undefined", end_lex));
      end_lex.deslocamento++;
      num_vars++;
      num_vars_tipo++;
   }
   | IDENT {              
      /* Insere simbolo (var) na tabela mantendo tipo indefinido */
      strncpy(token_atual, token, TAM_TOKEN);
      insere(tab_simb, cria_simbolo(token, "undefined", end_lex));
      end_lex.deslocamento++;
      num_vars++;
      num_vars_tipo++;
   }
;

lista_idents: lista_idents VIRGULA IDENT  
            | IDENT 
;

comando_composto: T_BEGIN comandos T_END 
;

comandos: atribuicao 
        |
;

atribuicao: variavel ATRIBUICAO expressao PONTO_E_VIRGULA
;

variavel: IDENT {      
      /* Verifica se a variavel foi instanciada anteriormente */
      variavel = busca(tab_simb, token);
      if (variavel == NULL) {
         char err_atrib[100] = "atribuicao invalida: variavel '";
         strcat(err_atrib, token);
         strcat(err_atrib, "' nao existe");
         imprimeErro(err_atrib);
      }
   } 
   parte_variavel
;

parte_variavel: ABRE_COLCHETES lista_expressoes FECHA_COLCHETES |
;

lista_expressoes: lista_expressoes VIRGULA expressao 
                | expressao
;




expressao: sinal_expressao expressao_simples parte_expressao
;

sinal_expressao: ADICAO | SUBTRACAO |
;

parte_expressao: relacao expressao_simples 
               |
;

expressao_simples: expressao_simples operador_baixa_precedencia termo {
      geraCodigo(NULL, instrucao_operador_b);
   }
   | termo    

;

termo: termo operador_alta_precedencia fator{

      geraCodigo(NULL, instrucao_operador_a);
}

     | fator
;

fator: variavel {
      EnderecoLexico end_atual = variavel->endereco_lexico;
      int tamanho = strlen("CRVL") + contaDigitos(end_atual.nivel) + contaDigitos(end_atual.deslocamento) + 5;
      char* instrucao_composta = malloc(tamanho);
      snprintf(instrucao_composta, tamanho, "%s %d, %d", "CRVL", end_atual.nivel, end_atual.deslocamento);
      geraCodigo (NULL, instrucao_composta);
   } 
   | NUMERO {
      geraCodigo (NULL, formataInstrucaoComposta("CRCT", atoi(token)));
   }
;

relacao: IGUAL | DESIGUAL | MENOR | MENOR_IGUAL | MAIOR | MAIOR_IGUAL
;

operador_baixa_precedencia: ADICAO {
      strcpy(instrucao_operador_b, "SOMA");
   }| SUBTRACAO {
      strcpy(instrucao_operador_b, "SUBT");
   }| OR
;

operador_alta_precedencia: MULTIPLICACAO {
      strcpy(instrucao_operador_a, "MULT");
   }
   | DIV | DIVISAO {
      strcpy(instrucao_operador_a, "DIVI");

   }| CONJUNCAO
;

%%

int main (int argc, char** argv) {
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
   num_vars_tipo = 0;
   end_lex.nivel = 0;
   end_lex.deslocamento = 0;
   yyin=fp;
   yyparse();
   imprime_tabela(tab_simb);
   
   return 0;
}

