#ifndef COMPILADORF
#define COMPILADORF

void geraCodigo(char* rot, char* comando);
int imprimeErro(char* erro);
int contaDigitos(int valor);
char* formataInstrucaoComposta(char* instrucao, int complemento);
char* formataInstrucaoCompostaString(char* instrucao, char* complemento);

char* removeAspas(char* entrada);

#endif