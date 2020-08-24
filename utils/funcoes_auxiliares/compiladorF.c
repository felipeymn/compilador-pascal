
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

FILE* fp = NULL;

void geraCodigo(char* rot, char* comando) {
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

int imprimeErro(char* erro) {
    fprintf(stderr, "Erro na linha %d - %s\n", nl, erro);
    exit(-1);
}

int contaDigitos(int valor) {
    int i = 0;
    do {
        valor /= 10;
        ++i;
    } while (valor != 0);
    return i;
}

char* formataInstrucaoComposta(char* instrucao, int complemento) {
    int tamanho = strlen(instrucao) + contaDigitos(complemento) + 2;
    char* instrucao_composta = malloc(tamanho);
    snprintf(instrucao_composta, tamanho, "%s %d", instrucao, complemento);

    return instrucao_composta;
}
