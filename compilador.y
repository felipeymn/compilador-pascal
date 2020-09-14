
// Testar se funciona corretamente o empilhamento de par�metros
// passados por valor ou por refer�ncia.


%{
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include "compilador.h"
#include "utils/funcoes_auxiliares/compiladorF.h"

Tabela *tab_simb;
PilhaRotulos *pilha_rot;
PilhaVariaveis *pilha_var;
PilhaVariaveis *pilha_param;
PilhaVariaveis *primeiro_fator;
PilhaVariaveis *segundo_fator;
Simbolo *variavel_atual;
Simbolo *variavel_atribuicao;
Simbolo *procedimento_atual;
EnderecoLexico end_lex;

int chamada_funcao;
int num_vars;
int num_vars_tipo;
char rot_continua[4];
char rot_desvia[4];
char* passagem;

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
%token IGUAL DESIGUAL MENOR MENOR_IGUAL MAIOR MAIOR_IGUAL
%token AND READ WRITE STRING

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE
%%

programa: { 
      geraCodigo (NULL, "INPP");
   }
   PROGRAM IDENT 
   ABRE_PARENTESES lista_idents {
      define_deslocamento_params(tab_simb, num_vars);
      num_vars = 0;
      num_vars_tipo = 0;
   } FECHA_PARENTESES PONTO_E_VIRGULA
   bloco PONTO {
      geraCodigo (NULL, "PARA"); 
   }
;

bloco: parte_declara_vars {
      gera_rotulo(pilha_rot, rot_desvia);
      empilha_rotulo(pilha_rot, rot_desvia);
      geraCodigo(NULL, formataInstrucaoCompostaString("DSVS", rotulo_desvia(pilha_rot)));

   } parte_declara_subrotina {
      geraCodigo(rotulo_desvia(pilha_rot), "NADA");
   } comando_composto {
      /* Desaloca memoria das variaveis locais */
      remove_procedimentos(tab_simb, end_lex.nivel);
      Simbolo *dmem = busca_categoria(tab_simb, "var");
      end_lex.deslocamento = dmem->endereco_lexico.deslocamento;
      if(end_lex.deslocamento >= 0) {
         geraCodigo(NULL, formataInstrucaoCompostaInt("DMEM", end_lex.deslocamento + 1));
         for(int i = 0; i < end_lex.deslocamento + 1; i++){ 
            retira(tab_simb);
         }
      }
   }
;

parte_declara_vars: VAR declara_vars {
      /* Gera unica instrucao AMEM para todas as variaveis do nivel lexico atual */
      // geraCodigo (NULL, formataInstrucaoCompostaInt("AMEM", num_vars));
      num_vars = 0;
   }
   |
;

declara_vars: declara_vars declara_var 
            | declara_var 
;

declara_var: lista_id_var {
   geraCodigo (NULL, formataInstrucaoCompostaInt("AMEM", num_vars_tipo));
   }  DOIS_PONTOS tipo PONTO_E_VIRGULA
;

lista_id_var: lista_id_var VIRGULA idents_var
   | idents_var 
;

idents_var: IDENT {
      /* Insere simbolo (var) na tabela mantendo tipo indefinido */
      end_lex.deslocamento++;
      insere(tab_simb, cria_simbolo(token, "undefined", end_lex, "var"));
      num_vars++;
      num_vars_tipo++;
   }
;

tipo: IDENT {
      /* Define tipo das variaveis com base no acumulador num_vars_tipo */
      define_tipo(tab_simb, token, num_vars_tipo);
      num_vars_tipo = 0;
   }
;

parte_declara_subrotina: parte_declara_subrotina  procedimento_ou_funcao
                       | 
;

procedimento_ou_funcao: declara_procedimento PONTO_E_VIRGULA
                      | declara_funcao PONTO_E_VIRGULA
;

declara_funcao: FUNCTION IDENT {
      /* Incrementa nivel lexico na entrada do procedimento */
      end_lex.nivel++;
      end_lex.deslocamento = -1;
      /* Cria e empilha rotulos para controle do procedimento */
      gera_rotulo(pilha_rot, rot_continua);
      empilha_rotulo(pilha_rot, rot_continua);
      /* Adiciona identificador do procedimento na tabela de simbolos */
      insere(tab_simb, cria_simbolo(token, "?", end_lex, "function"));
      define_categoria_procedimento(tab_simb->cabeca, rot_continua, 0);
      /* Gera instrucoes MEPA para inicio do procedimento */
      geraCodigo(rotulo_desvia(pilha_rot), formataInstrucaoCompostaInt("ENPR", end_lex.nivel));
      procedimento_atual = tab_simb->cabeca;
   } parte_declara_procedimento_ou_funcao DOIS_PONTOS IDENT {
      procedimento_atual->tipo = malloc(strlen(token) + 1);
      strcpy(procedimento_atual->tipo, token);
   } PONTO_E_VIRGULA bloco {
      for(int i = 0; i < (*(Procedimento*)procedimento_atual->info_categoria).num_parametros; i++) {
         retira(tab_simb);
      }
      /* Gera instrucoes MEPA para fim do procedimento */
      geraCodigo (NULL, formataInstrucaoCompostaIntInt("RTPR", end_lex.nivel, (*(Procedimento*)procedimento_atual->info_categoria).num_parametros));
      desempilha_rotulo(pilha_rot);
      desempilha_rotulo(pilha_rot);
      /* Decrementa nivel lexico na saida do procedimento */
      end_lex.nivel--;
   }
;

declara_procedimento: PROCEDURE IDENT {
      /* Incrementa nivel lexico na entrada do procedimento */
      end_lex.nivel++;
      end_lex.deslocamento = -1;
      /* Cria e empilha rotulos para controle do procedimento */
      gera_rotulo(pilha_rot, rot_continua);
      empilha_rotulo(pilha_rot, rot_continua);

      /* Adiciona identificador do procedimento na tabela de simbolos */
      insere(tab_simb, cria_simbolo(token, "?", end_lex, "procedure"));
      define_categoria_procedimento(tab_simb->cabeca, rot_continua, 0);
      /* Gera instrucoes MEPA para inicio do procedimento */
      geraCodigo(rotulo_desvia(pilha_rot), formataInstrucaoCompostaInt("ENPR", end_lex.nivel));
      procedimento_atual = tab_simb->cabeca;
   } parte_declara_procedimento_ou_funcao PONTO_E_VIRGULA bloco {
      for(int i = 0; i < (*(Procedimento*)procedimento_atual->info_categoria).num_parametros; i++) {
         retira(tab_simb);
      }
      /* Gera instrucoes MEPA para fim do procedimento */
      geraCodigo(NULL, formataInstrucaoCompostaIntInt("RTPR", end_lex.nivel, (*(Procedimento*)procedimento_atual->info_categoria).num_parametros));
      desempilha_rotulo(pilha_rot);
      desempilha_rotulo(pilha_rot);
      /* Decrementa nivel lexico na saida do procedimento */
      end_lex.nivel--;
   }
;

parte_declara_procedimento_ou_funcao: parametros_formais
                                    |
;

parametros_formais: ABRE_PARENTESES parte_parametros_formais {
      define_deslocamento_params(tab_simb, num_vars);
      (*(Procedimento*)procedimento_atual->info_categoria).num_parametros = num_vars;
      procedimento_atual->endereco_lexico.deslocamento = - 4 -  num_vars;

      num_vars = 0;
      num_vars_tipo = 0;
   } FECHA_PARENTESES
;

parte_parametros_formais: parte_parametros_formais PONTO_E_VIRGULA secao_parametros_formais
                        | secao_parametros_formais 
;

secao_parametros_formais: parte_secao_parametros_formais lista_idents DOIS_PONTOS tipo_parametros_formais
;

tipo_parametros_formais: IDENT {
      /* Define tipo das variaveis com base no acumulador num_vars_tipo */
      define_tipo(tab_simb, token, num_vars_tipo);
      for (int i = 0; i < num_vars_tipo; i++) {
         adiciona_parametro_lista(((Procedimento*)procedimento_atual->info_categoria), token, passagem);
      }
      num_vars_tipo = 0;
   }
;

parte_secao_parametros_formais: VAR {
      passagem = "referencia";
   } | {
      passagem = "valor";
   }
;

lista_idents: lista_idents VIRGULA idents_param  
            | idents_param 
;

idents_param: IDENT {
      insere(tab_simb, cria_simbolo(token, "undefined", end_lex, "param"));
      if (passagem != NULL) {
         define_categoria_parametro(tab_simb->cabeca, passagem);
      }

      num_vars++;
      num_vars_tipo++;
   }
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

comando_sem_rotulo: atribuicao_ou_chamada_procedimento
                  | read
                  | write
                  | comando_composto
                  | comando_condicional
                  | comando_repetitivo
;

atribuicao_ou_chamada_procedimento: IDENT {
      /* Verifica se a identificador foi instanciado anteriormente */
      variavel_atual = busca(tab_simb, token);
      if (variavel_atual == NULL) {
         imprimeErroVariavel(token);
      } else if ((strcmp(variavel_atual->categoria, "procedure") == 0) || (strcmp(variavel_atual->categoria, "function") == 0) ) {
         procedimento_atual = variavel_atual;
      }
   } atribuicao_ou_chamada_procedimento_continua
;

atribuicao_ou_chamada_procedimento_continua: atribuicao
                                           | chamada_procedimento
;

atribuicao: {
      empilha_variavel(pilha_var, variavel_atual->tipo);
      variavel_atribuicao = variavel_atual;
   }
   ATRIBUICAO expressao {
      primeiro_fator = desempilha_variavel(pilha_var);
      segundo_fator = desempilha_variavel(pilha_var);
      if (strcmp(primeiro_fator->tipo, segundo_fator->tipo) == 0) {
         if ((strcmp(variavel_atribuicao->categoria, "param") == 0) && (strcmp((*(Parametro*)variavel_atribuicao->info_categoria).passagem, "referencia") == 0)) {
            geraCodigo(NULL, formataInstrucaoCompostaIntInt("ARMI", variavel_atribuicao->endereco_lexico.nivel, variavel_atribuicao->endereco_lexico.deslocamento));

         } else {
            geraCodigo(NULL, formataInstrucaoCompostaIntInt("ARMZ", variavel_atribuicao->endereco_lexico.nivel, variavel_atribuicao->endereco_lexico.deslocamento));
         }
      } else { 
         imprimeErro("Operacao entre variaveis de tipos diferentes");
      }
      desempilha_variavel(pilha_var);
   }
;

chamada_procedimento: {
   } parte_chamada_procedimento {
      geraCodigo (NULL, formataInstrucaoCompostaStringInt("CHPR", (*(Procedimento*)procedimento_atual->info_categoria).rotulo, end_lex.nivel));
      for (int i = 0; i < (*(Procedimento*)procedimento_atual->info_categoria).num_parametros; i++) {
         desempilha_variavel(pilha_param);
      }
   }
;

parte_chamada_procedimento: ABRE_PARENTESES lista_expressoes FECHA_PARENTESES
                          |
;

chamada_funcao: parte_chamada_funcao{

   }
;

parte_chamada_funcao: ABRE_PARENTESES lista_expressoes FECHA_PARENTESES {
      geraCodigo (NULL, formataInstrucaoCompostaStringInt("CHPR", (*(Procedimento*)procedimento_atual->info_categoria).rotulo, end_lex.nivel));
      for (int i = 0; i < (*(Procedimento*)procedimento_atual->info_categoria).num_parametros; i++) {
         desempilha_variavel(pilha_param);
      }
   } | {
         if (chamada_funcao == 1) {
            geraCodigo (NULL, formataInstrucaoCompostaStringInt("CHPR", (*(Procedimento*)procedimento_atual->info_categoria).rotulo, end_lex.nivel));
            chamada_funcao = 0;
         }
    }

;

lista_expressoes: lista_expressoes VIRGULA {
      empilha_variavel(pilha_param, "VAR");
   } expressao {
      desempilha_variavel(pilha_var);
   } | {
      empilha_variavel(pilha_param, "VAR");
   } expressao {
      desempilha_variavel(pilha_var);
   }
;

expressao: sinal_expressao expressao_simples parte_expressao
;

sinal_expressao: ADICAO 
               | SUBTRACAO 
               |
;

parte_expressao: relacao expressao_simples {
      desempilha_variavel(pilha_var);
      PilhaVariaveis *operacao = desempilha_variavel(pilha_var);
      desempilha_variavel(pilha_var);
      geraCodigo(NULL, operacao->tipo);
      empilha_variavel(pilha_var, "boolean");
   }
               |
;

expressao_simples: expressao_simples operador_baixa_precedencia termo {
      primeiro_fator = desempilha_variavel(pilha_var);
      PilhaVariaveis *operacao = desempilha_variavel(pilha_var);
      segundo_fator = desempilha_variavel(pilha_var);
      char* tipo;
      if ((strcmp(operacao->tipo, "SOMA") == 0) || (strcmp(operacao->tipo, "SUBT") == 0)) {
            tipo = "integer";
      } else if (strcmp(operacao->tipo, "DISJ")) {
            tipo = "boolean";
      }

      if ((strcmp(primeiro_fator->tipo, tipo) == 0) && (strcmp(primeiro_fator->tipo, segundo_fator->tipo) == 0)) {
         geraCodigo(NULL, operacao->tipo);
         empilha_variavel(pilha_var, tipo);
      } else {
         imprimeErro("Operacao entre variaveis de tipos diferentes");
      }
      free(primeiro_fator);
      free(segundo_fator);

   }
   | termo    
;

termo: termo operador_alta_precedencia fator {
      primeiro_fator = desempilha_variavel(pilha_var);
      PilhaVariaveis *operacao = desempilha_variavel(pilha_var);
      segundo_fator = desempilha_variavel(pilha_var);

      char *tipo;
      if ((strcmp(operacao->tipo, "MULT") == 0) || (strcmp(operacao->tipo, "DIVI") == 0)) {
            tipo = "integer";
      } else if (strcmp(operacao->tipo, "CONJ")) {
            tipo = "boolean";
      }
      if ((strcmp(primeiro_fator->tipo, tipo) == 0) && (strcmp(primeiro_fator->tipo, segundo_fator->tipo) == 0)) {
         geraCodigo(NULL, operacao->tipo);
         empilha_variavel(pilha_var, tipo);
      } else {
         imprimeErro("Operacao entre variaveis de tipos diferentes");
      }
      free(primeiro_fator);
      free(segundo_fator);
   }
     | fator
;

fator: chamada_funcao_ou_var
   | NUMERO {
      geraCodigo (NULL, formataInstrucaoCompostaInt("CRCT", atoi(token)));
      empilha_variavel(pilha_var, "integer");
   }
   | ABRE_PARENTESES expressao FECHA_PARENTESES
   | NOT fator
;

chamada_funcao_ou_var: IDENT {
      /* Verifica se a variavel foi instanciada anteriormente */
      variavel_atual = busca(tab_simb, token);
      if (variavel_atual == NULL) {
         imprimeErroVariavel(token);
      }
      EnderecoLexico end_atual = variavel_atual->endereco_lexico;
      if (strcmp(variavel_atual->categoria, "function") == 0) {
         geraCodigo(NULL, "AMEM 1");
         chamada_funcao = 1;
      } else if (pilha_param->tamanho >= 1) {
         chamada_funcao = 0;
         ListaParametros *parametro_formal = busca_parametro_lista(((Procedimento*)procedimento_atual->info_categoria), pilha_param->tamanho);
         if (strcmp(parametro_formal->passagem, "referencia") == 0) {
            if ((strcmp(variavel_atual->categoria, "param") == 0) && (strcmp((*(Parametro*)variavel_atual->info_categoria).passagem, "referencia") == 0)) {
               geraCodigo(NULL, formataInstrucaoCompostaIntInt("CRVL", end_atual.nivel, end_atual.deslocamento));
            } else {
               geraCodigo(NULL, formataInstrucaoCompostaIntInt("CREN", end_atual.nivel, end_atual.deslocamento));
            }
         } else  {
            if ((strcmp(variavel_atual->categoria, "param") == 0) && (strcmp((*(Parametro*)variavel_atual->info_categoria).passagem, "referencia") == 0)) {
               geraCodigo(NULL, formataInstrucaoCompostaIntInt("CRVI", end_atual.nivel, end_atual.deslocamento));
            } else {
               geraCodigo(NULL, formataInstrucaoCompostaIntInt("CRVL", end_atual.nivel, end_atual.deslocamento));
            }
         }
      } else {
         chamada_funcao = 0;
         if ((strcmp(variavel_atual->categoria, "param") == 0) && (strcmp((*(Parametro*)variavel_atual->info_categoria).passagem, "referencia") == 0)) {
            geraCodigo(NULL, formataInstrucaoCompostaIntInt("CRVI", end_atual.nivel, end_atual.deslocamento));
         } else {
            geraCodigo(NULL, formataInstrucaoCompostaIntInt("CRVL", end_atual.nivel, end_atual.deslocamento));
         }
      }
      empilha_variavel(pilha_var, variavel_atual->tipo);

   } chamada_funcao_ou_var_continua
;

chamada_funcao_ou_var_continua: chamada_funcao
                               
;
relacao: IGUAL {
      empilha_variavel(pilha_var, "CMIG");
   } | DESIGUAL {
      empilha_variavel(pilha_var, "CMDG");
   } | MENOR {
      empilha_variavel(pilha_var, "CMME");
   } | MENOR_IGUAL {
      empilha_variavel(pilha_var, "CMEG");
   } | MAIOR {
      empilha_variavel(pilha_var, "CMMA");
   } | MAIOR_IGUAL {
      empilha_variavel(pilha_var, "CMAG");
   }
;

operador_baixa_precedencia: ADICAO {
      empilha_variavel(pilha_var, "SOMA");
   } | SUBTRACAO {
      empilha_variavel(pilha_var, "SUBT");
   } | OR {
      empilha_variavel(pilha_var, "DISJ");
   }
;

operador_alta_precedencia: MULTIPLICACAO {
      empilha_variavel(pilha_var, "MULT");
   } | DIV {
      empilha_variavel(pilha_var, "DIVI");
   } | DIVISAO {
      empilha_variavel(pilha_var, "DIVI");
   } | AND {
      empilha_variavel(pilha_var, "CONJ");
   }
;

comando_repetitivo: WHILE {
      gera_rotulo(pilha_rot, rot_continua);
      empilha_rotulo(pilha_rot, rot_continua);
      gera_rotulo(pilha_rot, rot_desvia);
      empilha_rotulo(pilha_rot, rot_desvia);
      geraCodigo(rotulo_continua(pilha_rot), "NADA");
   }
   expressao {
      PilhaVariaveis *resultado = desempilha_variavel(pilha_var);
      if (strcmp(resultado->tipo, "boolean") != 0) {
         imprimeErro("Comando If com expressao não booleana");
      }
      free(resultado);
      geraCodigo(NULL, formataInstrucaoCompostaString("DSVF", rotulo_desvia(pilha_rot)));

   } DO comando_sem_rotulo {
      geraCodigo(NULL, formataInstrucaoCompostaString("DSVS", rotulo_continua(pilha_rot)));
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
   }  expressao {
      PilhaVariaveis *resultado = desempilha_variavel(pilha_var);
      if (strcmp(resultado->tipo, "boolean") != 0) {
         imprimeErro("Comando If com expressao não booleana");
      }
      free(resultado);
      geraCodigo(NULL, formataInstrucaoCompostaString("DSVF", rotulo_desvia(pilha_rot)));
   }  THEN comando_sem_rotulo  {
      geraCodigo(NULL, formataInstrucaoCompostaString("DSVS", rotulo_continua(pilha_rot)));
      geraCodigo(rotulo_desvia(pilha_rot), "NADA"); 
   }  parte_comando_condicional  {
       geraCodigo(rotulo_continua(pilha_rot), "NADA");
       desempilha_rotulo(pilha_rot);
       desempilha_rotulo(pilha_rot);
   }
;

parte_comando_condicional: ELSE comando_sem_rotulo 
                         | %prec LOWER_THAN_ELSE
;

read: READ ABRE_PARENTESES parte_read FECHA_PARENTESES 
;
write: WRITE ABRE_PARENTESES parte_write FECHA_PARENTESES 
;

parte_read: parte_read VIRGULA conteudo_read
          | conteudo_read
;

conteudo_read: IDENT {
      Simbolo *variavel_read = busca(tab_simb, token);
      if (variavel_read == NULL) {
         imprimeErroVariavel(token);
      } else if ((strcmp(variavel_read->categoria, "param") == 0) && (strcmp((*(Parametro*)variavel_read->info_categoria).passagem, "referencia") == 0)) {
         geraCodigo(NULL, "LEIT");
         geraCodigo (NULL, formataInstrucaoCompostaIntInt("ARMI", variavel_read->endereco_lexico.nivel, variavel_read->endereco_lexico.deslocamento));
      } else {
         geraCodigo(NULL, "LEIT");
         geraCodigo (NULL, formataInstrucaoCompostaIntInt("ARMZ", variavel_read->endereco_lexico.nivel, variavel_read->endereco_lexico.deslocamento));
      }
   }
;

parte_write: parte_write VIRGULA conteudo_write
           | conteudo_write
;

conteudo_write: IDENT {
      Simbolo *variavel_write = busca(tab_simb, token);
      if (variavel_write == NULL) {
         imprimeErroVariavel(token);
      } else if ((strcmp(variavel_write->categoria, "param") == 0) && (strcmp((*(Parametro*)variavel_write->info_categoria).passagem, "referencia") == 0)) {
            geraCodigo (NULL, formataInstrucaoCompostaIntInt("CRVI", variavel_write->endereco_lexico.nivel, variavel_write->endereco_lexico.deslocamento));
      } else {
            geraCodigo (NULL, formataInstrucaoCompostaIntInt("CRVL", variavel_write->endereco_lexico.nivel, variavel_write->endereco_lexico.deslocamento));
      }
         geraCodigo(NULL, "IMPR");
   }
   | STRING {
      char* string = removeAspas(token);
      geraCodigo(NULL, formataInstrucaoCompostaString("CRCT", string));
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
   pilha_param = cria_pilha_variaveis();
   chamada_funcao = 0;
   num_vars = 0;
   num_vars_tipo = 0;
   end_lex.nivel = 0;
   end_lex.deslocamento = -1;
   yyin=fp;
   yyparse();
   return 0;
}