#ifndef PILHA_VARIAVEIS
#define PILHA_VARIAVEIS

typedef struct PilhaVariaveis {
    int tamanho;
    struct PilhaVariaveis *cabeca;
    char *tipo;
    struct PilhaVariaveis *proximo;
} PilhaVariaveis;

PilhaVariaveis *cria_pilha_variaveis();
void empilha_variavel(PilhaVariaveis *p, char *tipo);
PilhaVariaveis *desempilha_variavel(PilhaVariaveis *p);
void imprime_pilha(PilhaVariaveis *p);

#endif