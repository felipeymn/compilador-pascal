/*
   Projeto Compilador Pascal
   CI211 - Construcao de Compiladores (Periodo Especial 2020)
   Felipe Yudi Miyoshi Nakamoto - GRR20171585

   pilha_variaveis.c:
    Arquivo com a implementação da API da pilha de rotulos
    Utilizada pelo compilador para armazenar os rotulos de comandos aninhados
    dos fatores em uma expressao
*/

#include "pilha_rotulos.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

PilhaRotulos *cria_pilha_rotulos() {
    PilhaRotulos *v = malloc(sizeof(PilhaRotulos));
    PilhaRotulos *p = malloc(sizeof(PilhaRotulos));
    v->proximo = NULL;
    v->rotulo = "base";
    p->cabeca = v;
    p->tamanho = 0;
    return p;
}

void empilha_rotulo(PilhaRotulos *p, char *rotulo) {
    PilhaRotulos *r = malloc(sizeof(PilhaRotulos));
    char *rt;
    r->rotulo = malloc(sizeof(rotulo));
    strncpy(r->rotulo, rotulo, sizeof(rotulo));
    r->proximo = p->cabeca;
    p->cabeca = r;
    p->tamanho++;
}

PilhaRotulos *desempilha_rotulo(PilhaRotulos *p) {
    PilhaRotulos *desempilhado = p->cabeca;
    if (desempilhado != NULL) {
        p->cabeca = p->cabeca->proximo;
        p->tamanho--;
        return desempilhado;
    }
    return NULL;
}

void gera_rotulo(PilhaRotulos *p, char *rotulo) {
    snprintf(rotulo, 4, "R%02d", p->tamanho);
}

char *rotulo_continua(PilhaRotulos *p) { return p->cabeca->proximo->rotulo; }

char *rotulo_desvia(PilhaRotulos *p) { return p->cabeca->rotulo; }

void imprime_pilha_rotulos(PilhaRotulos *p) {
    printf("\nPilha:\n\n");
    PilhaRotulos *desempilhado = p->cabeca;
    while (desempilhado != NULL) {
        printf("Tipo: %s\n", desempilhado->rotulo);
        desempilhado = desempilhado->proximo;
    }
}
