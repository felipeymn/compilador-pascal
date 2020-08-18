%{


#include<stdio.h>
#include<string.h>

#include "compilador.h"
#include "compilador.tab.h"
//#define IMPRIME(STR) {};
#define IMPRIME(STR) printf("%s    # %s \n", STR, token);

int nl = 1;

%}

pulo_linha [\n]

descarte [\t ]+

ident [a-zAZ][a-zAZ1-9]*

numero [0-9]+

comentario "(*".*"*)"

%%

{pulo_linha} {nl++;} 

{descarte}

{comentario}

program { simbolo  = simb_program;  
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME("program ");
          return PROGRAM;
 }

var      { simbolo = simb_var;  
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME("var  ");
          return VAR;
 }

begin { simbolo = simb_begin;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME("begin ");
          return T_BEGIN;
 }

end { simbolo = simb_end;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME("end  ");
          return T_END;
 }

   /*******************************************/
  /* Aula 2: Adicionando simbolos em negrito */
 /*******************************************/

label { simbolo = simb_label;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME("label ");
          return LABEL;
}

type { simbolo = simb_type;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME("type ");
          return TYPE;
}

array { simbolo = simb_array;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME("array ");
          return ARRAY;
}

of { simbolo = simb_of;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME("of ");
          return OF;
}

procedure { simbolo = simb_procedure;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME("procedure ");
          return PROCEDURE;
}

function { simbolo = simb_function;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME("function ");
          return FUNCTION;
}

if { simbolo = simb_if;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME("if ");
          return IF;
}

else { simbolo = simb_else;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME("else ");
          return ELSE;
}

while { simbolo = simb_while;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME("while ");
          return WHILE;
}

do { simbolo = simb_do;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME("do ");
          return DO;
}

or { simbolo = simb_or;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME("or ");
          return OR;
}

div { simbolo = simb_div;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME("div ");
          return DIV;
}

not { simbolo = simb_not;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME("not ");
          return NOT;
}

 /*******************************************/

:= { simbolo = simb_atribuicao;  
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" atribuicao  ");
          return ATRIBUICAO;  
 }

\; { simbolo = simb_ponto_e_virgula;  
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" pt_virgula  ");
          return PONTO_E_VIRGULA;
 }

\: { simbolo = simb_dois_pontos;  
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" dois pontos ");
          return DOIS_PONTOS;
 }

\, { simbolo = simb_virgula;  
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" virgula  ");
          return VIRGULA;
 }


\. { simbolo = simb_ponto;  
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" ponto  ");
          return PONTO; 
    }

\(  { simbolo = simb_abre_parenteses;  
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" abre_parenteses  ");
          return ABRE_PARENTESES;
    }

\)  { simbolo = simb_fecha_parenteses;  
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" fecha_parenteses ");
          return FECHA_PARENTESES;
 }

{ident} { simbolo = simb_identificador; 
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" ident  ");
          return IDENT;
        }

   /*******************************************/
  /*        Simbolos Adicionais              */
 /*******************************************/

{numero} { simbolo = simb_numero; 
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" numero  ");
          return NUMERO;
        }

\+  { simbolo = simb_adicao;  
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" adicao ");
          return ADICAO;
}

\-  { simbolo = simb_subtracao;  
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" subtracao ");
          return SUBTRACAO;
 }

\*  { simbolo = simb_multiplicacao;  
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" multiplicacao ");
          return MULTIPLICACAO;
}

\/  { simbolo = simb_divisao;  
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" divisao ");
          return DIVISAO;
}

\=  { simbolo = simb_igual;  
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" igual ");
          return IGUAL;
}

\<>  { simbolo = simb_desigual;  
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" DESIGUAL ");
          return DESIGUAL;
}

\< { simbolo = simb_menor;  
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" menor ");
          return MENOR;
}

\<= { simbolo = simb_menor_igual;  
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" MENOR IGUAL ");
          return MENOR_IGUAL;
}

\> { simbolo = simb_maior;  
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" MAIOR ");
          return MAIOR;
}

\>= { simbolo = simb_maior_igual;  
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" MAIOR IGUAL ");
          return MAIOR_IGUAL; 
}

\[ { simbolo = simb_abre_colchetes;  
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" ABRE_COLCHETES ");
          return ABRE_COLCHETES;
}

conjuncao { simbolo = simb_conjuncao;  
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" CONJUNCAO ");
          return CONJUNCAO;
}

\] { simbolo = simb_fecha_colchetes;  
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME(" FECHA COLCHETES ");
          return FECHA_COLCHETES;
}



%%

