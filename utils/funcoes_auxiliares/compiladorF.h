#ifndef COMPILADORF
#define COMPILADORF

void geraCodigo(char* rot, char* comando);
int imprimeErro(char* erro);
int contaDigitos(int valor);
char* formataInstrucaoCompostaInt(char* instrucao, int complemento);
char* formataInstrucaoCompostaString(char* instrucao, char* complemento);
char* formataInstrucaoCompostaStringInt(char* instrucao, char* complemento,
                                        int complementoInt);
char* formataInstrucaoCompostaIntInt(char* instrucao, int complementoUm,
                                     int complementoDois);
char* imprimeErroVariavel(char* variavel);

char* removeAspas(char* entrada);

#endif