#ifndef TABELA_SIMBOLOS
#define TABELA_SIMBOLOS

#define TAM_TOKEN 16

typedef struct EnderecoLexico {
    int nivel;
    int deslocamento;
} EnderecoLexico;

typedef struct Simbolo {
    char id[TAM_TOKEN];
    char *categoria;
    char *tipo;
    EnderecoLexico endereco_lexico;
    void *info_categoria;
    struct Simbolo *proximo;
} Simbolo;

typedef struct Tabela {
    struct Simbolo *cabeca;
    int tamanho;
} Tabela;

typedef struct ListaParametros {
    char *tipo;
    char *passagem;
    struct ListaParametros *proximo;
} ListaParametros;

typedef struct Procedimento {
    char *rotulo;
    int num_parametros;
    ListaParametros *lista;
} Procedimento;

typedef struct Parametro {
    char *passagem;
} Parametro;

Tabela *cria_tabela();
Simbolo *cria_simbolo(char *id, char *t, EnderecoLexico e, char *c);
void insere(Tabela *t, Simbolo *s);
void retira(Tabela *t);
Simbolo *busca(Tabela *t, char *id);
void imprime_tabela(Tabela *t);
void define_tipo(Tabela *t, char *tipo, int num_vars);
void define_deslocamento_params(Tabela *t, int num_vars);
Procedimento *cria_procedimento(char *r, int np);
void define_categoria_procedimento(Simbolo *s, char *r, int np);
Simbolo *busca_categoria(Tabela *t, char *categoria);
void remove_procedimentos(Tabela *t, int nivel);
Parametro *cria_parametro(char *passagem);
void define_categoria_parametro(Simbolo *s, char *passagem);
void adiciona_parametro_lista(Procedimento *p, char *tipo, char *passagem);
void imprimeLista(Procedimento *p);
ListaParametros *busca_parametro_lista(Procedimento *p, int indice);

#endif