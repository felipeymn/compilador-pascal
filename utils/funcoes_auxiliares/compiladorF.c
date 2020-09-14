
/* -------------------------------------------------------------------
 *            Aquivo: compilador.c
 * -------------------------------------------------------------------
 *              Autor: Bruno Muller Junior
 *               Data: 08/2007
 *      Atualizado em: [15/03/2012, 08h:22m]
 *
 * -------------------------------------------------------------------
 *
 * Fun��es auxiliares ao compilador
 *
 * ------------------------------------------------------------------- */

#include "compiladorF.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../../compilador.h"
/* -------------------------------------------------------------------
 *  vari�veis globais
 * ------------------------------------------------------------------- */

FILE *fp = NULL;

void geraCodigo(char *rot, char *comando) {
    if (fp == NULL) {
        fp = fopen("MEPA", "w");
    }

    if (rot == NULL) {
        fprintf(fp, "     %s\n", comando);
        fflush(fp);
    } else {
        fprintf(fp, "%s: %s \n", rot, comando);
        fflush(fp);
    }
}

int imprimeErro(char *erro) {
    fprintf(stderr, "Erro na linha %d - %s\n", nl, erro);
    exit(-1);
}

int contaDigitos(int valor) {
    int i = 0;
    if (valor < 0) {
        i++;
    }
    do {
        valor /= 10;
        ++i;
    } while (valor != 0);
    return i;
}

char *formataInstrucaoCompostaInt(char *instrucao, int complemento) {
    int tamanho = strlen(instrucao) + contaDigitos(complemento) + 2;
    char *instrucao_composta = malloc(tamanho);
    snprintf(instrucao_composta, tamanho, "%s %d", instrucao, complemento);

    return instrucao_composta;
}

char *removeAspas(char *entrada) {
    int i;
    char *saida;
    printf("%s\n", entrada);
    saida = malloc(strlen(entrada) - 1);
    for (i = 1; i < strlen(entrada) - 1; i++) {
        saida[i - 1] = entrada[i];
    }
    saida[i] = 0;
    printf("%s\n", saida);
    return saida;
}

char *formataInstrucaoCompostaString(char *instrucao, char *complemento) {
    int tamanho = strlen(instrucao) + strlen(complemento) + 2;
    char *instrucao_composta = malloc(tamanho);
    snprintf(instrucao_composta, tamanho, "%s %s", instrucao, complemento);
    return instrucao_composta;
}

char *formataInstrucaoCompostaStringInt(char *instrucao, char *complemento,
                                        int complementoInt) {
    int tamanho = strlen(instrucao) + strlen(complemento) +
                  contaDigitos(complementoInt) + 6;
    char *instrucao_composta = malloc(tamanho);
    snprintf(instrucao_composta, tamanho, "%s %s, %d", instrucao, complemento,
             complementoInt);
    return instrucao_composta;
}

char *formataInstrucaoCompostaIntInt(char *instrucao, int complementoUm,
                                     int complementoDois) {
    int tamanho = strlen(instrucao) + contaDigitos(complementoUm) +
                  contaDigitos(complementoDois) + 6;
    char *instrucao_composta = malloc(tamanho);
    snprintf(instrucao_composta, tamanho, "%s %d, %d", instrucao, complementoUm,
             complementoDois);
    return instrucao_composta;
}

char *imprimeErroVariavel(char *variavel) {
    char *msg_erro;
    int tamanho = 43 + strlen(variavel);
    msg_erro = malloc(tamanho);
    snprintf(msg_erro, tamanho, "Atribuicao invalida: variavel %s nao existe",
             variavel);
    imprimeErro(msg_erro);
}
