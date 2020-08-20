#include "tabela_simbolos.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*---
      API da Tabela de Simbolos
                                ---*/

Tabela *cria_tabela() {
    Tabela *t = malloc(sizeof(Tabela));
    t->cabeca = NULL;
    t->tamanho = 0;
    return t;
}

Simbolo *cria_simbolo(char id[TAM_TOKEN], char *t, EnderecoLexico e) {
    Simbolo *s = malloc(sizeof(Simbolo));
    strncpy(s->id, id, TAM_TOKEN);
    s->tipo = t;
    s->endereco_lexico = e;
    s->proximo = NULL;
    return s;
}

void insere(Tabela *t, Simbolo *s) {
    s->proximo = t->cabeca;
    t->cabeca = s;
    t->tamanho++;
}

void retira(Tabela *t) {
    Simbolo *retirado = t->cabeca;
    while (retirado != NULL) {
        t->cabeca = t->cabeca->proximo;
        t->tamanho--;
        free(retirado);
    }
}

Simbolo *busca(Tabela *t, char *id) {
    Simbolo *current = t->cabeca;
    while (current != NULL) {
        if (strcmp(current->id, id) == 0) {
            break;
        }
        current = current->proximo;
    }
    return current;
}

void imprime_tabela(Tabela *t) {
    printf("\nTabela de Simbolos:\n\n");
    printf("%16s\t Deslocamento\t Nivel Lexico\t Tipo\n", "Identificador");
    Simbolo *current = t->cabeca;
    while (current != NULL) {
        printf(" %16s\t %12d\t %12d\t %s\t \n", current->id,
               current->endereco_lexico.deslocamento,
               current->endereco_lexico.nivel, current->tipo);

        current = current->proximo;
    }
}

void define_tipo(Tabela *t, char *tipo, int num_vars) {
    Simbolo *atual = t->cabeca;
    for (int i = 0; i < num_vars; i++) {
        if (atual != NULL) {
            atual->tipo = malloc(sizeof(tipo));
            strcpy(atual->tipo, tipo);
            atual = atual->proximo;
        } else {
            break;
        }
    }
}
