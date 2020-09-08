#ifndef PILHA_ROTULOS
#define PILHA_ROTULOS

typedef struct PilhaRotulos {
    struct PilhaRotulos *cabeca;
    char *rotulo;
    struct PilhaRotulos *proximo;
    int tamanho;
} PilhaRotulos;

PilhaRotulos *cria_pilha_rotulos();
void empilha_rotulo(PilhaRotulos *p, char *rotulo);
PilhaRotulos *desempilha_rotulo(PilhaRotulos *p);
void gera_rotulo(PilhaRotulos *p, char *rotulo);
char *rotulo_continua(PilhaRotulos *p);
char *rotulo_desvia(PilhaRotulos *p);
void imprime_pilha_rotulos(PilhaRotulos *p);

#endif