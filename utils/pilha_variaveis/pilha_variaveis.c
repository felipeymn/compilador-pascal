#include "pilha_variaveis.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

PilhaVariaveis *cria_pilha_variaveis() {
    PilhaVariaveis *v = malloc(sizeof(PilhaVariaveis));
    PilhaVariaveis *p = malloc(sizeof(PilhaVariaveis));
    v->proximo = NULL;
    v->tipo = "undefined";
    p->cabeca = v;
    return p;
}


void empilha_variavel(PilhaVariaveis *p, PilhaVariaveis *v) {
    v->proximo = p->cabeca;
    p->cabeca = v;
}

void desempilha_variavel(PilhaVariaveis *p) {
    PilhaVariaveis *desempilhado = p->cabeca;
    if (desempilhado != NULL) {
        p->cabeca = p->cabeca->proximo;
        free(desempilhado);
    }
}