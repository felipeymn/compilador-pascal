#ifndef TABELA_SIMBOLOS
#define TABELA_SIMBOLOS

#define TAM_TOKEN 16

typedef struct EnderecoLexico {
    int nivel;
    int deslocamento;
} EnderecoLexico;

typedef struct Simbolo {
    char id[TAM_TOKEN];
    char *tipo;
    EnderecoLexico endereco_lexico;
    struct Simbolo *next;
} Simbolo;

typedef struct Tabela {
    struct Simbolo *cabeca;
    int tamanho;
} Tabela;

Tabela *cria_tabela();
Simbolo *cria_simbolo(char *id, char *t, EnderecoLexico e);
void insere(Tabela *t, Simbolo *s);
void retira(Tabela *t);
Simbolo *busca(Tabela *t, char *id);
void imprime_tabela(Tabela *t);
void define_tipo(Tabela *t, char *tipo, unsigned int num_vars);

#endif