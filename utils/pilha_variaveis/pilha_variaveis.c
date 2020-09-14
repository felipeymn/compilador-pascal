/*
   Projeto Compilador Pascal
   CI211 - Construcao de Compiladores (Periodo Especial 2020)
   Felipe Yudi Miyoshi Nakamoto - GRR20171585

   pilha_variaveis.c:
    Arquivo com a implementação da API da pilha de variáveis
    Utilizada pelo compilador para verificar o tipo (integer, boolean, etc)
    dos fatores em uma expressao
*/

#include "pilha_variaveis.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

PilhaVariaveis *cria_pilha_variaveis() {
    PilhaVariaveis *v = malloc(sizeof(PilhaVariaveis));
    PilhaVariaveis *p = malloc(sizeof(PilhaVariaveis));
    p->cabeca = NULL;
    p->tamanho = 0;
    return p;
}

void empilha_variavel(PilhaVariaveis *p, char *tipo) {
    PilhaVariaveis *v = malloc(sizeof(PilhaVariaveis));
    v->tipo = tipo;
    v->proximo = p->cabeca;
    p->cabeca = v;
    p->tamanho++;
}

PilhaVariaveis *desempilha_variavel(PilhaVariaveis *p) {
    PilhaVariaveis *desempilhado = p->cabeca;
    if (desempilhado != NULL) {
        p->cabeca = p->cabeca->proximo;
        p->tamanho--;
        return desempilhado;
    }
    return NULL;
}

void imprime_pilha(PilhaVariaveis *p) {
    printf("===============================\n\n");
    printf("\nPilha:\n\n");
    PilhaVariaveis *desempilhado = p->cabeca;
    while (desempilhado != NULL) {
        printf("Tipo: %s\n", desempilhado->tipo);
        desempilhado = desempilhado->proximo;
    }
    printf("===============================\n\n");
}