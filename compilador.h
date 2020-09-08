/* -------------------------------------------------------------------
 *            Arquivo: compilador.h
 * -------------------------------------------------------------------
 *              Autor: Bruno Muller Junior
 *               Data: 08/2007
 *      Atualizado em: [15/03/2012, 08h:22m]
 *
 * -------------------------------------------------------------------
 *
 * Tipos, prot�tipos e vai�veis globais do compilador
 *
 * ------------------------------------------------------------------- */
#include "utils/pilha_rotulos/pilha_rotulos.h"
#include "utils/pilha_variaveis/pilha_variaveis.h"
#include "utils/tabela_simbolos/tabela_simbolos.h"

typedef enum simbolos {
    simb_program,
    simb_var,
    simb_begin,
    simb_end,
    simb_identificador,
    simb_numero,
    simb_ponto,
    simb_virgula,
    simb_ponto_e_virgula,
    simb_dois_pontos,
    simb_atribuicao,
    simb_abre_parenteses,
    simb_fecha_parenteses,
    /*** Aula 2  ***/
    simb_label,
    simb_type,
    simb_array,
    simb_of,
    simb_procedure,
    simb_function,
    simb_if,
    simb_else,
    simb_then,
    simb_while,
    simb_do,
    simb_or,
    simb_div,
    simb_not,
    simb_adicao,
    simb_subtracao,
    simb_multiplicacao,
    simb_divisao,
    simb_igual,
    simb_desigual,
    simb_menor,
    simb_menor_igual,
    simb_maior,
    simb_maior_igual,
    simb_abre_colchetes,
    simb_fecha_colchetes,
    simb_and,
    simb_read,
    simb_write,
    simb_string
} simbolos;

/* -------------------------------------------------------------------
 * variaveis globais
 * ------------------------------------------------------------------- */
extern simbolos simbolo, relacao;
extern char token[TAM_TOKEN];
extern int nivel_lexico;
extern int desloc;
extern int nl;

simbolos simbolo, relacao;
char token[TAM_TOKEN];
