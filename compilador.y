
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
PilhaRotulos *pilha_rot;
PilhaVariaveis *pilha_var;
PilhaVariaveis *primeiro_fator;
PilhaVariaveis *segundo_fator;
char tipo_operacao; // Pode ser aritmetica ou booleana [A ou B]
EnderecoLexico end_lex;
char instrucao_operador_alta[5];
char instrucao_operador_baixa[5];
char instrucao_relacao[5];
char token_atual[TAM_TOKEN];
char rot_continua[4];
char rot_desvia[4];


Simbolo *variavel_atual;
Simbolo *variavel_atribuicao;

int yylex();
void yyerror(const char *s);

%}

%token PROGRAM ABRE_PARENTESES FECHA_PARENTESES 
%token VIRGULA PONTO_E_VIRGULA DOIS_PONTOS PONTO
%token T_BEGIN T_END VAR IDENT ATRIBUICAO
/*** Aula 2  ***/
%token LABEL TYPE ARRAY OF PROCEDURE FUNCTION
%token IF THEN ELSE WHILE DO OR DIV NOT NUMERO
%token ADICAO SUBTRACAO MULTIPLICACAO DIVISAO
%token IGUAL DESIGUAL MENOR MENOR_IGUAL MAIOR MAIOR_IGUAL ABRE_COLCHETES FECHA_COLCHETES
%token AND READ WRITE STRING

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE
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

comando_composto: T_BEGIN parte_comando_composto T_END
;

parte_comando_composto: parte_comando_composto PONTO_E_VIRGULA comando 
                      | comando
;
comando: parte_comando comando_sem_rotulo
;

parte_comando: NUMERO DOIS_PONTOS 
             |
;

comando_sem_rotulo: read
                  | write
                  | atribuicao
                  | comando_repetitivo
                  | comando_condicional
                  | comando_composto
                  |
;

atribuicao: variavel {
      empilha_variavel(pilha_var, variavel_atual->tipo);
      variavel_atribuicao = variavel_atual;
   } 
   ATRIBUICAO expressao {
      primeiro_fator = desempilha_variavel(pilha_var);
      segundo_fator = desempilha_variavel(pilha_var);
      if (strcmp(primeiro_fator->tipo, segundo_fator->tipo) == 0) {
         int tamanho = strlen("ARMZ") + contaDigitos(variavel_atribuicao->endereco_lexico.nivel) + contaDigitos(variavel_atribuicao->endereco_lexico.deslocamento) + 3;
         char* instrucao_composta = malloc(tamanho);
         snprintf(instrucao_composta, tamanho, "%s %d,%d", "ARMZ", variavel_atribuicao->endereco_lexico.nivel,variavel_atribuicao->endereco_lexico.deslocamento);
         geraCodigo (NULL, instrucao_composta);
      } else { 
         imprimeErro("3 -Operacao entre variaveis de tipos diferentes");
      }

   }
;

variavel: IDENT {      
      /* Verifica se a variavel foi instanciada anteriormente */
      variavel_atual = busca(tab_simb, token);
      if (variavel_atual == NULL) {
         char err_atrib[100] = "Atribuicao invalida: variavel '";
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

// TODO: Arrumar funcionamento do sinal
sinal_expressao: ADICAO | SUBTRACAO |
;

parte_expressao: relacao expressao_simples {
      desempilha_variavel(pilha_var);
      desempilha_variavel(pilha_var);
      geraCodigo(NULL, instrucao_relacao);
      empilha_variavel(pilha_var, "boolean");
   }
               |
;

expressao_simples: expressao_simples operador_baixa_precedencia termo {
      primeiro_fator = desempilha_variavel(pilha_var);
      segundo_fator = desempilha_variavel(pilha_var);

      char *tipo;
      switch (tipo_operacao) {
         case 'A':
            tipo = "integer";
            break;
         case 'B':
            tipo = "boolean";
            break;
      }

      if ((strcmp(primeiro_fator->tipo, tipo) == 0) && (strcmp(primeiro_fator->tipo, segundo_fator->tipo) == 0)) {
         geraCodigo(NULL, instrucao_operador_baixa);
         empilha_variavel(pilha_var, tipo);
      } else {
         imprimeErro("1 -Operacao entre variaveis de tipos diferentes");
      }
      free(primeiro_fator);
      free(segundo_fator);

   }
   | termo    
;

termo: termo operador_alta_precedencia fator {
      primeiro_fator = desempilha_variavel(pilha_var);
      segundo_fator = desempilha_variavel(pilha_var);

      char *tipo;
      switch (tipo_operacao) {
         case 'A':
            tipo = "integer";
            break;
         case 'B':
            tipo = "boolean";
            break;
      }
      if ((strcmp(primeiro_fator->tipo, tipo) == 0) && (strcmp(primeiro_fator->tipo, segundo_fator->tipo) == 0)) {
         geraCodigo(NULL, instrucao_operador_alta);
         empilha_variavel(pilha_var, tipo);
      } else {
         imprimeErro("2 -Operacao entre variaveis de tipos diferentes");
      }
      free(primeiro_fator);
      free(segundo_fator);
}
     | fator
;

fator: variavel {
      EnderecoLexico end_atual = variavel_atual->endereco_lexico;
      int tamanho = strlen("CRVL") + contaDigitos(end_atual.nivel) + contaDigitos(end_atual.deslocamento) + 3;
      char* instrucao_composta = malloc(tamanho);
      snprintf(instrucao_composta, tamanho, "%s %d,%d", "CRVL", end_atual.nivel, end_atual.deslocamento);
      geraCodigo (NULL, instrucao_composta);
      empilha_variavel(pilha_var, variavel_atual->tipo);
      free(instrucao_composta);
   } 
   | NUMERO {
      geraCodigo (NULL, formataInstrucaoComposta("CRCT", atoi(token)));
      empilha_variavel(pilha_var, "integer");
   }
   | ABRE_PARENTESES expressao FECHA_PARENTESES
   | NOT fator
   // TODO: IMPLEMENTAR CHAMADA DE FUNCAO
;

relacao: IGUAL {
      strcpy(instrucao_relacao, "CMIG");
      tipo_operacao = 'B';
   } | DESIGUAL {
      strcpy(instrucao_relacao, "CMDG");
      tipo_operacao = 'B';
   } | MENOR {
      strcpy(instrucao_relacao, "CMME");
      tipo_operacao = 'B';
   } | MENOR_IGUAL {
      strcpy(instrucao_relacao, "CMEG");
      tipo_operacao = 'B';
   } | MAIOR {
      strcpy(instrucao_relacao, "CMMA");
      tipo_operacao = 'B';
   } | MAIOR_IGUAL {
      strcpy(instrucao_relacao, "CMAG");
      tipo_operacao = 'B';
   }
;

operador_baixa_precedencia: ADICAO {
      strcpy(instrucao_operador_baixa, "SOMA");
      tipo_operacao = 'A';
   } | SUBTRACAO {
      strcpy(instrucao_operador_baixa, "SUBT");
      tipo_operacao = 'A';
   } | OR {
      strcpy(instrucao_operador_alta, "DISJ");
      tipo_operacao = 'B';
   }
;

operador_alta_precedencia: MULTIPLICACAO {
      strcpy(instrucao_operador_alta, "MULT");
      tipo_operacao = 'A';
   } | DIV {
      strcpy(instrucao_operador_alta, "DIVI");
      tipo_operacao = 'A';
   } | DIVISAO {
      strcpy(instrucao_operador_alta, "DIVI");
      tipo_operacao = 'A';
   } | AND {
      strcpy(instrucao_operador_alta, "CONJ");
      tipo_operacao = 'B';
   }
;

comando_repetitivo: WHILE {
      gera_rotulo(pilha_rot, rot_continua);
      empilha_rotulo(pilha_rot, rot_continua);
      gera_rotulo(pilha_rot, rot_desvia);
      empilha_rotulo(pilha_rot, rot_desvia);
      geraCodigo(rotulo_continua(pilha_rot), "NADA");
      imprime_pilha_rotulos(pilha_rot);
   }
   expressao {
      int tamanho = strlen("DSVF") + strlen(rotulo_desvia(pilha_rot)) + 5;
      char* instrucao_composta = malloc(tamanho);
      snprintf(instrucao_composta, tamanho, "DSVF %s", rotulo_desvia(pilha_rot));
      geraCodigo(NULL, instrucao_composta);
   } DO comando_sem_rotulo {
      int tamanho = strlen("DSVF") + strlen(rotulo_desvia(pilha_rot)) + 5;
      char* instrucao_composta = malloc(tamanho);
      snprintf(instrucao_composta, tamanho, "DSVS %s", rotulo_continua(pilha_rot));
      geraCodigo(NULL, instrucao_composta);
      geraCodigo(rotulo_desvia(pilha_rot), "NADA");
      desempilha_rotulo(pilha_rot);
      desempilha_rotulo(pilha_rot);
   }
;

comando_condicional: IF {
      gera_rotulo(pilha_rot, rot_continua);
      empilha_rotulo(pilha_rot, rot_continua);
      gera_rotulo(pilha_rot, rot_desvia);
      empilha_rotulo(pilha_rot, rot_desvia);
      imprime_pilha_rotulos(pilha_rot);
   }
   expressao {
      int tamanho = strlen("DSVF") + strlen(rotulo_desvia(pilha_rot)) + 5;
      char* instrucao_composta = malloc(tamanho);
      snprintf(instrucao_composta, tamanho, "DSVF %s", rotulo_continua(pilha_rot));
      geraCodigo(NULL, instrucao_composta);
   }  THEN comando_sem_rotulo {
      int tamanho = strlen("DSVF") + strlen(rotulo_desvia(pilha_rot)) + 5;
      char* instrucao_composta = malloc(tamanho);
      snprintf(instrucao_composta, tamanho, "DSVF %s", rotulo_desvia(pilha_rot));
      geraCodigo(NULL, instrucao_composta);
      geraCodigo(rotulo_continua(pilha_rot), "NADA");
   } parte_comando_condicional {
      geraCodigo(rotulo_desvia(pilha_rot), "NADA");
      desempilha_rotulo(pilha_rot);
      desempilha_rotulo(pilha_rot);
   }
;

parte_comando_condicional: ELSE comando_sem_rotulo 
                         | %prec LOWER_THAN_ELSE
;

read: READ ABRE_PARENTESES IDENT {
      Simbolo *variavel_read = busca(tab_simb, token);
      if (variavel_read == NULL) {
         char err_atrib[100] = "Leitura invalida: variavel '";
         strcat(err_atrib, token);
         strcat(err_atrib, "' nao existe");
         imprimeErro(err_atrib);
      } else {
         geraCodigo(NULL, "LEIT");
         int tamanho = strlen("ARMZ") + contaDigitos(variavel_read->endereco_lexico.nivel) + contaDigitos(variavel_read->endereco_lexico.deslocamento) + 3;
         char* instrucao_composta = malloc(tamanho);
         snprintf(instrucao_composta, tamanho, "%s %d,%d", "ARMZ", variavel_read->endereco_lexico.nivel,variavel_read->endereco_lexico.deslocamento);
         geraCodigo (NULL, instrucao_composta);
      }
   } FECHA_PARENTESES 
;
write: WRITE ABRE_PARENTESES conteudo {

   } FECHA_PARENTESES 
;

conteudo: IDENT {
         Simbolo *variavel_write = busca(tab_simb, token);
      if (variavel_write == NULL) {
         char err_atrib[100] = "Impressao invalida: variavel '";
         strcat(err_atrib, token);
         strcat(err_atrib, "' nao existe");
         imprimeErro(err_atrib);
      } else {
         int tamanho = strlen("CRVL") + contaDigitos(variavel_write->endereco_lexico.nivel) + contaDigitos(variavel_write->endereco_lexico.deslocamento) + 3;
         char* instrucao_composta = malloc(tamanho);
         snprintf(instrucao_composta, tamanho, "%s %d,%d", "CRVL", variavel_write->endereco_lexico.nivel,variavel_write->endereco_lexico.deslocamento);
         geraCodigo (NULL, instrucao_composta);
         geraCodigo(NULL, "IMPR");
      }
   }
   | STRING {
      char* string = removeAspas(token);
      int tamanho = strlen("CRCT") + strlen(string) + 2;
      char* instrucao_composta = malloc(tamanho);
      snprintf(instrucao_composta, tamanho, "%s %s", "CRCT", string);
      geraCodigo (NULL, instrucao_composta);
      geraCodigo(NULL, "IMPR");
   }
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
   pilha_rot = cria_pilha_rotulos();
   pilha_var = cria_pilha_variaveis();
   num_vars = 0;
   num_vars_tipo = 0;
   end_lex.nivel = 0;
   end_lex.deslocamento = 0;
   yyin=fp;
   yyparse();
   imprime_tabela(tab_simb);
   
   return 0;
}

