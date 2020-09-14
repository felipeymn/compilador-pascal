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

Simbolo *cria_simbolo(char id[TAM_TOKEN], char *t, EnderecoLexico e, char *c) {
    Simbolo *s = malloc(sizeof(Simbolo));
    strncpy(s->id, id, TAM_TOKEN);
    if (c != NULL) {
        s->categoria = malloc(strlen(c));
        strncpy(s->categoria, c, strlen(c) + 1);
    }
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
    if (retirado != NULL) {
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
    printf("%16s\t Deslocamento\t Nivel Lexico\t Categoria\t Tipo\t\n",
           "Identificador");
    Simbolo *current = t->cabeca;
    while (current != NULL) {
        printf(" %16s\t %12d\t %12d\t %8s\t %8s\t \n", current->id,
               current->endereco_lexico.deslocamento,
               current->endereco_lexico.nivel, current->categoria,
               current->tipo);

        current = current->proximo;
    }
}

void define_tipo(Tabela *t, char *tipo, int num_vars) {
    Simbolo *atual = t->cabeca;
    for (int i = 0; i < num_vars; i++) {
        if (atual != NULL) {
            atual->tipo = malloc(strlen(tipo));
            strcpy(atual->tipo, tipo);
            atual = atual->proximo;
        } else {
            break;
        }
    }
}

void define_deslocamento_params(Tabela *t, int num_vars) {
    // Deslocamento inicial = -4
    int deslocamento = -4;
    Simbolo *atual = t->cabeca;
    for (int i = 0; i < num_vars; i++) {
        if (atual != NULL) {
            atual->endereco_lexico.deslocamento = deslocamento--;
            atual = atual->proximo;
        } else {
            break;
        }
    }
}

Procedimento *cria_procedimento(char *r, int np) {
    Procedimento *p = malloc(sizeof(Procedimento));
    if (r != NULL) {
        p->rotulo = malloc(strlen(r));
        strncpy(p->rotulo, r, strlen(r) + 1);
    }
    p->num_parametros = np;
    return p;
}

void define_categoria_procedimento(Simbolo *s, char *r, int np) {
    Procedimento *p = cria_procedimento(r, np);
    s->info_categoria = (Procedimento *)p;
}

Simbolo *busca_categoria(Tabela *t, char *categoria) {
    Simbolo *current = t->cabeca;
    while (current != NULL) {
        if (strcmp(current->categoria, categoria) == 0) {
            break;
        }
        current = current->proximo;
    }
    return current;
}

void remove_procedimentos(Tabela *t, int nivel) {
    Simbolo *current = t->cabeca;
    while (current != NULL) {
        if ((strcmp(current->categoria, "procedure") == 0) &&
            (current->endereco_lexico.nivel > nivel)) {
            retira(t);
            current = t->cabeca;
        } else {
            break;
        }
    }
}