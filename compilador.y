
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
int num_params;
int num_params_tipo;
Tabela *tab_simb;
PilhaRotulos *pilha_rot;
PilhaVariaveis *pilha_var;
PilhaVariaveis *pilha_param;
PilhaVariaveis *primeiro_fator;
PilhaVariaveis *segundo_fator;
char* passagem;
char tipo_operacao; // Pode ser aritmetica ou booleana [A ou B]
EnderecoLexico end_lex;
char instrucao_operador_alta[5];
char instrucao_operador_baixa[5];
char rot_continua[4];
char rot_desvia[4];

Simbolo *variavel_atual;
Simbolo *variavel_atribuicao;
Simbolo *procedimento_atual;
int chamada_funcao;
int parametro_real;
int parametro_real_funcao;

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
         geraCodigo(NULL, formataInstrucaoComposta("DMEM", end_lex.deslocamento + 1));
         for(int i = 0; i < end_lex.deslocamento + 1; i++){ 
            retira(tab_simb);
         }
      }
   }
;

parte_declara_vars: VAR declara_vars {
      /* Gera unica instrucao AMEM para todas as variaveis do nivel lexico atual */
      // geraCodigo (NULL, formataInstrucaoComposta("AMEM", num_vars));
      num_vars = 0;
   }
   |
;

declara_vars: declara_vars declara_var 
            | declara_var 
;

declara_var: lista_id_var {
   geraCodigo (NULL, formataInstrucaoComposta("AMEM", num_vars_tipo));
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
      geraCodigo(rotulo_desvia(pilha_rot), formataInstrucaoComposta("ENPR", end_lex.nivel));
      procedimento_atual = tab_simb->cabeca;
   } parte_declara_procedimento_ou_funcao DOIS_PONTOS IDENT {
      procedimento_atual->tipo = malloc(strlen(token) + 1);
      strcpy(procedimento_atual->tipo, token);
   } PONTO_E_VIRGULA bloco {
      char* instrucao_composta;
      /* Gera instrucoes MEPA para fim do procedimento */
      int tamanho = strlen("RTPR") + contaDigitos(end_lex.nivel) + contaDigitos((*(Procedimento*)procedimento_atual->info_categoria).num_parametros) + 4;
      instrucao_composta = malloc(tamanho);
      snprintf(instrucao_composta, tamanho, "RTPR %d, %d", end_lex.nivel, (*(Procedimento*)procedimento_atual->info_categoria).num_parametros);
      for(int i = 0; i < (*(Procedimento*)procedimento_atual->info_categoria).num_parametros; i++) {
         retira(tab_simb);
      }
      geraCodigo(NULL, instrucao_composta);
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
      geraCodigo(rotulo_desvia(pilha_rot), formataInstrucaoComposta("ENPR", end_lex.nivel));
      procedimento_atual = tab_simb->cabeca;
   } parte_declara_procedimento_ou_funcao PONTO_E_VIRGULA bloco {
      char* instrucao_composta;
      /* Gera instrucoes MEPA para fim do procedimento */
      int tamanho = strlen("RTPR") + contaDigitos(end_lex.nivel) + contaDigitos((*(Procedimento*)procedimento_atual->info_categoria).num_parametros) + 4;
      instrucao_composta = malloc(tamanho);
      snprintf(instrucao_composta, tamanho, "RTPR %d, %d", end_lex.nivel, (*(Procedimento*)procedimento_atual->info_categoria).num_parametros);
      for(int i = 0; i < (*(Procedimento*)procedimento_atual->info_categoria).num_parametros; i++) {
         retira(tab_simb);
      }
      geraCodigo(NULL, instrucao_composta);
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
         char err_atrib[100] = "Atribuicao invalida: variavel '";
         strcat(err_atrib, token);
         strcat(err_atrib, "' nao existe");
         imprimeErro(err_atrib);
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

            int tamanho = strlen("ARMI") + contaDigitos(variavel_atribuicao->endereco_lexico.nivel) + contaDigitos(variavel_atribuicao->endereco_lexico.deslocamento) + 4;
            char* instrucao_composta = malloc(tamanho);
            snprintf(instrucao_composta, tamanho, "%s %d, %d", "ARMI", variavel_atribuicao->endereco_lexico.nivel,variavel_atribuicao->endereco_lexico.deslocamento);
            geraCodigo (NULL, instrucao_composta);
         } else {
            int tamanho = strlen("ARMZ") + contaDigitos(variavel_atribuicao->endereco_lexico.nivel) + contaDigitos(variavel_atribuicao->endereco_lexico.deslocamento) + 4;
            char* instrucao_composta = malloc(tamanho);
            snprintf(instrucao_composta, tamanho, "%s %d, %d", "ARMZ", variavel_atribuicao->endereco_lexico.nivel,variavel_atribuicao->endereco_lexico.deslocamento);
            geraCodigo (NULL, instrucao_composta);
         }
      } else { 
         imprimeErro("Operacao entre variaveis de tipos diferentes");
      }
      desempilha_variavel(pilha_var);
   }
;

chamada_procedimento: {
      parametro_real = 1;
   } parte_chamada_procedimento {
      int tamanho = strlen("CHPR") + contaDigitos(end_lex.nivel) + contaDigitos(end_lex.deslocamento) + 6;
      char* instrucao_composta = malloc(tamanho);
      snprintf(instrucao_composta, tamanho, "%s %s, %d", "CHPR", (*(Procedimento*)procedimento_atual->info_categoria).rotulo, end_lex.nivel);
      geraCodigo (NULL, instrucao_composta);
      printf(">>>>>>>>>>>>>>>>>>>>>>ZERA PARAMETRO REAL: %d\n\n", parametro_real);
      parametro_real = 0;
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
      int tamanho;
      char* instrucao_composta;
      tamanho = strlen("CHPR") + strlen((*(Procedimento*)procedimento_atual->info_categoria).rotulo) + contaDigitos(end_lex.nivel) + 6;
      instrucao_composta = malloc(tamanho);
      snprintf(instrucao_composta, tamanho, "%s %s, %d", "CHPR", (*(Procedimento*)procedimento_atual->info_categoria).rotulo, end_lex.nivel);
      geraCodigo (NULL, instrucao_composta);
      for (int i = 0; i < (*(Procedimento*)procedimento_atual->info_categoria).num_parametros; i++) {
         desempilha_variavel(pilha_param);
      }
   } | {
         int tamanho;
         char* instrucao_composta;
         if (chamada_funcao == 1) {
             tamanho = strlen("CHPR") + strlen((*(Procedimento*)procedimento_atual->info_categoria).rotulo) + contaDigitos(end_lex.nivel) + 6;
            instrucao_composta = malloc(tamanho);
            snprintf(instrucao_composta, tamanho, "%s %s, %d", "CHPR", (*(Procedimento*)procedimento_atual->info_categoria).rotulo, end_lex.nivel);
            geraCodigo (NULL, instrucao_composta);
            chamada_funcao = 0;
         }
    }

;

/* parte_variavel: ABRE_COLCHETES lista_expressoes FECHA_COLCHETES 
              |
; */

lista_expressoes: lista_expressoes VIRGULA {
            empilha_variavel(pilha_param, "VAR");
}expressao {
      desempilha_variavel(pilha_var);
      if (parametro_real >= 1) {
         parametro_real++;
      }
   } | {
      empilha_variavel(pilha_param, "VAR");
   } expressao {
      desempilha_variavel(pilha_var);
   }
;

expressao: sinal_expressao expressao_simples parte_expressao {       
   // desempilha_variavel(pilha_var);
}
;

// TODO: Arrumar funcionamento do sinal
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
      geraCodigo (NULL, formataInstrucaoComposta("CRCT", atoi(token)));
      empilha_variavel(pilha_var, "integer");
   }
   | ABRE_PARENTESES expressao FECHA_PARENTESES
   | NOT fator
;

chamada_funcao_ou_var: IDENT {
      /* Verifica se a variavel foi instanciada anteriormente */
      variavel_atual = busca(tab_simb, token);
      if (variavel_atual == NULL) {
         char err_atrib[100] = "Atribuicao invalida: variavel '";
         strcat(err_atrib, token);
         strcat(err_atrib, "' nao existe");
         imprimeErro(err_atrib);
      }
      EnderecoLexico end_atual = variavel_atual->endereco_lexico;
      int tamanho;
      char* instrucao_composta;
      printf("################################################# %d %s\n", pilha_param->tamanho, variavel_atual->id);
                     imprime_pilha(pilha_param);

      if (strcmp(variavel_atual->categoria, "function") == 0) {
         geraCodigo(NULL, "AMEM 1");
         chamada_funcao = 1;
         empilha_variavel(pilha_var, variavel_atual->tipo);
      } else if (pilha_param->tamanho >= 1) {
         ListaParametros *parametro_formal = busca_parametro_lista(((Procedimento*)procedimento_atual->info_categoria), pilha_param->tamanho);
         if (strcmp(parametro_formal->passagem, "referencia") == 0) {
            if ((strcmp(variavel_atual->categoria, "param") == 0) && (strcmp((*(Parametro*)variavel_atual->info_categoria).passagem, "referencia") == 0)) {
               chamada_funcao = 0;
               tamanho = strlen("CRVL") + contaDigitos(end_atual.nivel) + contaDigitos(end_atual.deslocamento) + 4;
               instrucao_composta = malloc(tamanho);
               snprintf(instrucao_composta, tamanho, "%s %d, %d", "CRVL", end_atual.nivel, end_atual.deslocamento);
               geraCodigo (NULL, instrucao_composta);
               empilha_variavel(pilha_var, variavel_atual->tipo);
               free(instrucao_composta);
            } else {
               chamada_funcao = 0;
               tamanho = strlen("CREN") + contaDigitos(end_atual.nivel) + contaDigitos(end_atual.deslocamento) + 4;
               instrucao_composta = malloc(tamanho);
               snprintf(instrucao_composta, tamanho, "%s %d, %d", "CREN", end_atual.nivel, end_atual.deslocamento);
               geraCodigo (NULL, instrucao_composta);
               empilha_variavel(pilha_var, variavel_atual->tipo);
               free(instrucao_composta);
            }
         } else  {
            if ((strcmp(variavel_atual->categoria, "param") == 0) && (strcmp((*(Parametro*)variavel_atual->info_categoria).passagem, "referencia") == 0)) {
               chamada_funcao = 0;
               tamanho = strlen("CRVI") + contaDigitos(end_atual.nivel) + contaDigitos(end_atual.deslocamento) + 4;
               instrucao_composta = malloc(tamanho);
               snprintf(instrucao_composta, tamanho, "%s %d, %d", "CRVI", end_atual.nivel, end_atual.deslocamento);
               geraCodigo (NULL, instrucao_composta);
               empilha_variavel(pilha_var, variavel_atual->tipo);
               free(instrucao_composta);
            } else {
               chamada_funcao = 0;
               tamanho = strlen("CRVL") + contaDigitos(end_atual.nivel) + contaDigitos(end_atual.deslocamento) + 4;
               instrucao_composta = malloc(tamanho);
               snprintf(instrucao_composta, tamanho, "%s %d, %d", "CRVL", end_atual.nivel, end_atual.deslocamento);
               geraCodigo (NULL, instrucao_composta);
               empilha_variavel(pilha_var, variavel_atual->tipo);
               free(instrucao_composta);
            }
         }
      } else {
         if ((strcmp(variavel_atual->categoria, "param") == 0) && (strcmp((*(Parametro*)variavel_atual->info_categoria).passagem, "referencia") == 0)) {
            chamada_funcao = 0;
            tamanho = strlen("CRVI") + contaDigitos(end_atual.nivel) + contaDigitos(end_atual.deslocamento) + 4;
            instrucao_composta = malloc(tamanho);
            snprintf(instrucao_composta, tamanho, "%s %d, %d", "CRVI", end_atual.nivel, end_atual.deslocamento);
            geraCodigo (NULL, instrucao_composta);
            empilha_variavel(pilha_var, variavel_atual->tipo);
            free(instrucao_composta);
         } else {
            chamada_funcao = 0;
            tamanho = strlen("CRVL") + contaDigitos(end_atual.nivel) + contaDigitos(end_atual.deslocamento) + 4;
            instrucao_composta = malloc(tamanho);
            snprintf(instrucao_composta, tamanho, "%s %d, %d", "CRVL", end_atual.nivel, end_atual.deslocamento);
            geraCodigo (NULL, instrucao_composta);
            empilha_variavel(pilha_var, variavel_atual->tipo);
            free(instrucao_composta);
         }
      }
   } chamada_funcao_ou_var_continua
;

chamada_funcao_ou_var_continua: chamada_funcao
                               
;
relacao: IGUAL {
      empilha_variavel(pilha_var, "CMIG");
      tipo_operacao = 'B';

   } | DESIGUAL {
      empilha_variavel(pilha_var, "CMDG");
      tipo_operacao = 'B';
   } | MENOR {
      empilha_variavel(pilha_var, "CMME");
      tipo_operacao = 'B';
   } | MENOR_IGUAL {
      empilha_variavel(pilha_var, "CMEG");
      tipo_operacao = 'B';
   } | MAIOR {
      empilha_variavel(pilha_var, "CMMA");
      tipo_operacao = 'B';
   } | MAIOR_IGUAL {
      empilha_variavel(pilha_var, "CMAG");
      tipo_operacao = 'B';
   }
;

operador_baixa_precedencia: ADICAO {
      tipo_operacao = 'A';
      empilha_variavel(pilha_var, "SOMA");
   } | SUBTRACAO {
      empilha_variavel(pilha_var, "SUBT");
      tipo_operacao = 'A';
   } | OR {
      empilha_variavel(pilha_var, "DISJ");
      tipo_operacao = 'B';
   }
;

operador_alta_precedencia: MULTIPLICACAO {
      tipo_operacao = 'A';
      empilha_variavel(pilha_var, "MULT");
   } | DIV {
      empilha_variavel(pilha_var, "DIVI");
      tipo_operacao = 'A';
   } | DIVISAO {
      empilha_variavel(pilha_var, "DIVI");
      tipo_operacao = 'A';
   } | AND {
      empilha_variavel(pilha_var, "CONJ");
      tipo_operacao = 'B';
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
      if (tipo_operacao != 'B') {
         imprimeErro("Comando While com expressao não booleana");
      }
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
      int tamanho;
      char* instrucao_composta;
      if (variavel_read == NULL) {
         char err_atrib[100] = "Leitura invalida: variavel '";
         strcat(err_atrib, token);
         strcat(err_atrib, "' nao existe");
         imprimeErro(err_atrib);
      } else if ((strcmp(variavel_read->categoria, "param") == 0) && (strcmp((*(Parametro*)variavel_read->info_categoria).passagem, "referencia") == 0)) {
         geraCodigo(NULL, "LEIT");
         tamanho = strlen("ARMI") + contaDigitos(variavel_read->endereco_lexico.nivel) + contaDigitos(variavel_read->endereco_lexico.deslocamento) + 4;
         instrucao_composta = malloc(tamanho);
         snprintf(instrucao_composta, tamanho, "%s %d, %d", "ARMI", variavel_read->endereco_lexico.nivel,variavel_read->endereco_lexico.deslocamento);
         geraCodigo (NULL, instrucao_composta);
      } else {
         geraCodigo(NULL, "LEIT");
         tamanho = strlen("ARMZ") + contaDigitos(variavel_read->endereco_lexico.nivel) + contaDigitos(variavel_read->endereco_lexico.deslocamento) + 4;
         instrucao_composta = malloc(tamanho);
         snprintf(instrucao_composta, tamanho, "%s %d, %d", "ARMZ", variavel_read->endereco_lexico.nivel,variavel_read->endereco_lexico.deslocamento);
         geraCodigo (NULL, instrucao_composta);
      }
   }
;

parte_write: parte_write VIRGULA conteudo_write
           | conteudo_write
;

conteudo_write: IDENT {
      Simbolo *variavel_write = busca(tab_simb, token);
      char* instrucao_composta;
      int tamanho;
      if (variavel_write == NULL) {
         char err_atrib[100] = "Impressao invalida: variavel '";
         strcat(err_atrib, token);
         strcat(err_atrib, "' nao existe");
         imprimeErro(err_atrib);
      } else if ((strcmp(variavel_write->categoria, "param") == 0) && (strcmp((*(Parametro*)variavel_write->info_categoria).passagem, "referencia") == 0)) {
            tamanho = strlen("CRVI") + contaDigitos(variavel_write->endereco_lexico.nivel) + contaDigitos(variavel_write->endereco_lexico.deslocamento) + 4;
            instrucao_composta = malloc(tamanho);
            snprintf(instrucao_composta, tamanho, "%s %d, %d", "CRVI", variavel_write->endereco_lexico.nivel,variavel_write->endereco_lexico.deslocamento);
            geraCodigo (NULL, instrucao_composta);
      } else {
            tamanho = strlen("CRVL") + contaDigitos(variavel_write->endereco_lexico.nivel) + contaDigitos(variavel_write->endereco_lexico.deslocamento) + 4;
            instrucao_composta = malloc(tamanho);
            snprintf(instrucao_composta, tamanho, "%s %d, %d", "CRVL", variavel_write->endereco_lexico.nivel,variavel_write->endereco_lexico.deslocamento);
            geraCodigo (NULL, instrucao_composta);
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
   parametro_real = 0;
   parametro_real_funcao = 0;

   num_vars = 0;
   num_vars_tipo = 0;
   end_lex.nivel = 0;
   end_lex.deslocamento = -1;
   yyin=fp;
   yyparse();
   imprime_tabela(tab_simb);
   imprime_pilha(pilha_param);
   
   return 0;
}