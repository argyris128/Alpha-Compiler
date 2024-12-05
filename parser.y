/*
 *	CS - 340: Compilers
 *	Project - Phase 3
 *	Intermediate Code
 *
 *	Dialektakis Antonis		A.M. : 2717
 *	Patramanis Argiris		A.M. : 4379
 *	Vlachakis Zaxarias		A.M. : 4602
 *
 *	Deadline : 17/5/2024
 *	
 */

%{
	#include "SymTable.h"
	#include "Quads.h"

	int yylex(void);
	int yyerror(char* yaccProvidedMessage);

	int equalsLibFunc(Symnode_t *symnode);				// checks if symbol is the same with a libfunc
	void checkVar(char* name, enum SymbolType type);	// for variable insertion to symtable
	
	extern int yylineno;
	extern char* yytext;
	extern FILE* yyin;

	HashTable_t *hashHead;
	int currScope = 0;		// current scope
	int currFuncScope = 0;	// current function scope
	int funcName = 0;		// automatic function name in case its empty
	Symnode_t *currSymnode;	// most recent symbol
	int funcRedec = 0;		// becomes 1 if variable with same name as function is found (same scope)
	int returnStmt = 0;		// becomes 1 if return statement is called
	int funcCall = 0;		// becomes 1 if a function is called
	int keywordLocal = 0;	// becomes 1 if there is "local" written before a variable
	int assignExpr = 0;		// becomes 1 if there is x = y;
	int tempVar = 0;		// automatic temp variable name for quads

	int programOffset = 0;
	int funcOffset[100]; int currFuncOffset = 0;
	int formalOffset[100]; int currFormalOffset = 0;

	int funcReturnCount[100];
	int breakCount[100];
	int contCount[100];
	int currLoopScope = 0;

	struct lc_stack_t {
    	struct lc_stack_t* next;
    	unsigned counter;
	} *lcs_top = 0, *lcs_bottom = 0;

	#define loopcounter \
 	(lcs_top->counter)

%}

%start program;

%union{
    int intValue;
    char* stringValue;
	double realValue;
	struct expr *exprValue;
	struct forloop *forValue;
}

%token<intValue> INT
%token<stringValue> ID String
%token<realValue> FLOAT

%token<stringValue> IF ELSE WHILE FOR RETURN FUNCTION TRUE FALSE NIL AND OR local NOT BREAK CONTINUE
%token<stringValue> semicolon equal plus minus mul division mod greater greaterequal less lessequal equalequal notequal 
%token<stringValue> openpar closepar openbracket closebracket plusplus minusminus dot dotdot colon coloncolon
%token<stringValue> comma opencurlybracket closecurlybracket uminus

%type<intValue> stmt stmt_temp primary assignexpr ifstmt whilestmt forstmt returnstmt block funcdef funcdef2 ifprefix elseprefix whilestart whilecond M N
%type<intValue> call objectdef const member elist tmp_elist indexed indexed_tmp indexedelem idlist normcall methodcall callsuffix
%type<exprValue> expr lvalue
%type<forValue> forprefix

%right equal
%left OR
%left AND
%nonassoc equalequal notequal
%nonassoc greater greaterequal less lessequal
%left plus minus
%left mul division mod
%right NOT plusplus minusminus uminus
%left dot dotdot
%left openbracket closebracket
%left openpar closepar

%%

program:	program stmt { printf("program\n"); funcCall = 0; funcRedec = 0; }
			|

stmt:		expr semicolon { printf("expression ;\n"); tempVar = 0; }
			|ifstmt { printf("if statement\n");  tempVar = 0; } 
			|whilestmt { printf("while statement\n"); tempVar = 0; }
			|forstmt { printf("for statement\n"); tempVar = 0;}
			|returnstmt { printf("return statement\n");tempVar = 0; }
			|BREAK semicolon { printf("break\n"); if(loopcounter == 0) yyerror("Break outside a loop"); tempVar = 0;
				emit(Jump, NULL, NULL, NULL, -1, yylineno);
				breakCount[currLoopScope]++;
			} 
			|CONTINUE semicolon { printf("continue\n"); if(loopcounter == 0) yyerror("Continue outside a loop"); tempVar = 0;
				emit(Jump, NULL, NULL, NULL, -2, yylineno); 
				contCount[currLoopScope]++;
			}
			|block { printf("block\n"); tempVar = 0;}
			|funcdef { printf("function\n"); tempVar = 0;}
			|semicolon { printf(";\n"); tempVar = 0;}
			
expr:		assignexpr { printf("assign expression\n"); $<exprValue>$ = $<exprValue>1;}
			|expr plus expr { printf("expression + expression\n"); 
				$<exprValue>$ = newexpr(arithexpr_e);
				$<exprValue>$->sym = newtemp();
				emit(Add, $<exprValue>$, $<exprValue>1, $<exprValue>3, 0, yylineno);
			}
			|expr minus expr { printf("expression - expression\n"); 
				$<exprValue>$ = newexpr(arithexpr_e);
				$<exprValue>$->sym = newtemp();
				emit(Sub, $<exprValue>$, $<exprValue>1, $<exprValue>3, 0, yylineno);
			}
			|expr mul expr { printf("expression * expression\n"); 
				$<exprValue>$ = newexpr(arithexpr_e);
				$<exprValue>$->sym = newtemp();
				emit(Mul, $<exprValue>$, $<exprValue>1, $<exprValue>3, 0, yylineno);
			}
			|expr division expr { printf("expression / expression\n"); 
				$<exprValue>$ = newexpr(arithexpr_e);
				$<exprValue>$->sym = newtemp();
				emit(Div, $<exprValue>$, $<exprValue>1, $<exprValue>3, 0, yylineno);
			}
			|expr mod expr { printf("expression MOD expression\n");  
				$<exprValue>$ = newexpr(arithexpr_e);
				$<exprValue>$->sym = newtemp();
				emit(Mod, $<exprValue>$, $<exprValue>1, $<exprValue>3, 0, yylineno);
			}
			|expr greater expr {	printf("expression > expression\n"); 
									$<exprValue>$ = newexpr(boolexpr_e);
									$<exprValue>$->sym = newtemp();
									emit(If_greater, NULL,  $<exprValue>1,  $<exprValue>3, nextquadlabel()+4, yylineno);
									emit(Assign, $<exprValue>$, newexpr_false(), NULL, 0, yylineno);
									emit(Jump, NULL, NULL, NULL, nextquadlabel()+3, yylineno);
									emit(Assign, $<exprValue>$, newexpr_true(), NULL, 0, yylineno);
								}
			|expr greaterequal expr { 	printf("expression >= expression\n"); 
										$<exprValue>$ = newexpr(boolexpr_e);
										$<exprValue>$->sym = newtemp();
										emit(If_greatereq, NULL,  $<exprValue>1,  $<exprValue>3, nextquadlabel()+4, yylineno);
										emit(Assign, $<exprValue>$, newexpr_false(), NULL, 0, yylineno);
										emit(Jump, NULL, NULL, NULL, nextquadlabel()+3, yylineno);
										emit(Assign, $<exprValue>$, newexpr_true(), NULL, 0, yylineno);
									}
			|expr less expr { 	printf("expression < expression\n");  
								$<exprValue>$ = newexpr(boolexpr_e);
								$<exprValue>$->sym = newtemp();
								emit(If_less, NULL,  $<exprValue>1,  $<exprValue>3, nextquadlabel()+4, yylineno);
								emit(Assign, $<exprValue>$, newexpr_false(), NULL, 0, yylineno);
								emit(Jump, NULL, NULL, NULL, nextquadlabel()+3, yylineno);
								emit(Assign, $<exprValue>$, newexpr_true(), NULL, 0, yylineno);
							}
			|expr lessequal expr {	printf("expression <= expression\n");  
									$<exprValue>$ = newexpr(boolexpr_e);
									$<exprValue>$->sym = newtemp();
									emit(If_lesseq, NULL,  $<exprValue>1,  $<exprValue>3, nextquadlabel()+4, yylineno);
									emit(Assign, $<exprValue>$, newexpr_false(), NULL, 0, yylineno);
									emit(Jump, NULL, NULL, NULL, nextquadlabel()+3, yylineno);
									emit(Assign, $<exprValue>$, newexpr_true(), NULL, 0, yylineno);
								}
			|expr equalequal expr { printf("expression == expression\n"); 
									$<exprValue>$ = newexpr(boolexpr_e);
									$<exprValue>$->sym = newtemp();
									emit(If_eq, NULL,  $<exprValue>1,  $<exprValue>3, nextquadlabel()+4, yylineno);
									emit(Assign, $<exprValue>$, newexpr_false(), NULL, 0, yylineno);
									emit(Jump, NULL, NULL, NULL, nextquadlabel()+3, yylineno);
									emit(Assign, $<exprValue>$, newexpr_true(), NULL, 0, yylineno);
								}
			|expr notequal expr { 	printf("expression != expression\n");  
									$<exprValue>$ = newexpr(boolexpr_e);
									$<exprValue>$->sym = newtemp();
									emit(If_noteq, NULL,  $<exprValue>1,  $<exprValue>3, nextquadlabel()+4, yylineno);
									emit(Assign, $<exprValue>$, newexpr_false(), NULL, 0, yylineno);
									emit(Jump, NULL, NULL, NULL, nextquadlabel()+3, yylineno);
									emit(Assign, $<exprValue>$, newexpr_true(), NULL, 0, yylineno);
								}
			|expr AND expr { 	printf("expression && expression\n");  
								$<exprValue>$ = newexpr(boolexpr_e);
								$<exprValue>$->sym = newtemp();
								emit(And, $<exprValue>$,  $<exprValue>1,  $<exprValue>3, 0, yylineno);
							}
			|expr OR expr { printf("expression || expression\n");  
							$<exprValue>$ = newexpr(boolexpr_e);
							$<exprValue>$->sym = newtemp();
							emit(Or, $<exprValue>$,  $<exprValue>1,  $<exprValue>3, 0, yylineno);
							}
			|term { printf("term\n"); $<exprValue>$ = $<exprValue>1;}
			 

term:		openpar expr closepar { printf("(expression)\n"); $<exprValue>$ = $<exprValue>2; }
			|minus expr %prec uminus { printf("- expression\n"); 
					if(funcRedec == 1 && funcCall == 0) {
						yyerror("Invalid operation on function");
					}
					$<exprValue>$ = newexpr(arithexpr_e);
					$<exprValue>$->sym = newtemp();
					emit(Uminus, $<exprValue>$, $<exprValue>2, NULL, 0, yylineno);
				}
			|NOT expr { printf("! expression\n"); 
					if(funcRedec == 1 && funcCall == 0) {
						yyerror("Invalid operation on function");
					}
					$<exprValue>$ = newexpr(boolexpr_e);
					$<exprValue>$->sym = newtemp();
					emit(Not, $<exprValue>$, $<exprValue>2, NULL, 0, yylineno);
					}
			|plusplus lvalue { printf("++ value\n"); 
					if(funcRedec == 1 && funcCall == 0) {
						yyerror("Invalid operation on function");
					}

					Expr *tmp = newexpr(constint_e);
					tmp->intConst = 1;

					if($<exprValue>2->type == tableitem_e) {
						Expr* val = emit_iftableitem($<exprValue>2);
						emit(Add, val, val, tmp, 0, yylineno);
						emit(Tablesetelem, $<exprValue>2, $<exprValue>2->index, val, 0, yylineno);
						$<exprValue>$ = val;
					} else {
						Expr *tmp2 = newexpr(assignexpr_e);
						tmp2->sym = newtemp();
						emit(Add, $<exprValue>2, $<exprValue>2, tmp, 0, yylineno);
						emit(Assign, tmp2, $<exprValue>2, NULL, 0, yylineno);
						$<exprValue>$ = tmp2;
					}		
					
					}
			|lvalue plusplus { printf("value ++\n"); 
					if(funcRedec == 1 && funcCall == 0) {
						yyerror("Invalid operation on function");
					}

					Expr *tmp = newexpr(constint_e);
					tmp->intConst = 1;
					Expr *tmp2 = newexpr(assignexpr_e);
					tmp2->sym = newtemp();
					

					if($<exprValue>1->type == tableitem_e) {
						Expr* val = emit_iftableitem($<exprValue>1);
						emit(Assign, tmp2, val, NULL, 0, yylineno);					
						emit(Add, val, val, tmp, 0, yylineno);	
						emit(Tablesetelem, $<exprValue>1, $<exprValue>1->index, val, 0, yylineno);
					} else {
						emit(Assign, tmp2, $<exprValue>1, NULL, 0, yylineno);
						emit(Add, $<exprValue>1, $<exprValue>1, tmp, 0, yylineno);	
					}
					$<exprValue>$ = tmp2;
					
					}
			|minusminus lvalue { printf("-- value\n"); 
					if(funcRedec == 1 && funcCall == 0) {
						yyerror("Invalid operation on function");
					}
					
					Expr *tmp = newexpr(constint_e);
					tmp->intConst = 1;

					if($<exprValue>2->type == tableitem_e) {
						Expr* val = emit_iftableitem($<exprValue>2);
						emit(Sub, val, val, tmp, 0, yylineno);
						emit(Tablesetelem, $<exprValue>2, $<exprValue>2->index, val, 0, yylineno);
						$<exprValue>$ = val;
					} else {
						Expr *tmp2 = newexpr(assignexpr_e);
						tmp2->sym = newtemp();
						emit(Sub, $<exprValue>2, $<exprValue>2, tmp, 0, yylineno);
						emit(Assign, tmp2, $<exprValue>2, NULL, 0, yylineno);
						$<exprValue>$ = tmp2;
					}		
					}
			|lvalue minusminus { printf("value --\n"); 
					if(funcRedec == 1 && funcCall == 0) {
						yyerror("Invalid operation on function");
					}
					
					Expr *tmp = newexpr(constint_e);
					tmp->intConst = 1;
					Expr *tmp2 = newexpr(assignexpr_e);
					tmp2->sym = newtemp();

					if($<exprValue>1->type == tableitem_e) {
						Expr* val = emit_iftableitem($<exprValue>1);
						emit(Assign, tmp2, val, NULL, 0, yylineno);		
						emit(Sub, val, val, tmp, 0, yylineno);	
						emit(Tablesetelem, $<exprValue>1, $<exprValue>1->index, val, 0, yylineno);
					} else {
						emit(Assign, tmp2, $<exprValue>1, NULL, 0, yylineno);
						emit(Sub, $<exprValue>1, $<exprValue>1, tmp, 0, yylineno);	
					}
					$<exprValue>$ = tmp2;
					}
			|primary { printf("primary\n"); $<exprValue>$ = $<exprValue>1;}
			

assignexpr:	lvalue {assignExpr = 1;

					Symnode_t *lookup;
					int tempScope = currScope;
					while(tempScope >= 0) {		// search for nearest scope lookup
						lookup = Lookup(currSymnode, hashHead, tempScope);
						if(lookup != NULL)
							break;
						tempScope--;
					}

					if(lookup != NULL && funcCall == 0) {
						if(lookup->type == USERFUNC) {
							if(currSymnode->scope == lookup->scope) {
								yyerror("Function name redeclaration");
							}
						} else if(lookup->type == LIBFUNC) {
							yyerror("Function name redeclaration");
						}
					}

					} equal expr { printf("lvalue = expression\n"); 
								Symnode_t *lookup = Lookup(currSymnode, hashHead, currScope);
								if(lookup != NULL) {
									if(lookup->type == USERFUNC) {
										if(currSymnode->scope == lookup->scope) {
											if(funcCall == 0)
												yyerror("Function name redeclaration");
										}
									}
								}

								assignExpr = 0;

								if($<exprValue>1->type == tableitem_e) {
									emit(Tablesetelem, $<exprValue>1, $<exprValue>1->index, $<exprValue>4, 0, yylineno);
									$<exprValue>$ = emit_iftableitem($<exprValue>1);
									$<exprValue>$->type = assignexpr_e;
								} else {
									emit(Assign, $<exprValue>1, $<exprValue>4, NULL, 0, yylineno);
									$<exprValue>$ = newexpr(assignexpr_e);
									$<exprValue>$->sym = newtemp();
									emit(Assign, $<exprValue>$, $<exprValue>1, NULL, 0, yylineno);
								}
							}


primary:	lvalue { 	printf("lvalue\n"); 
						Symnode_t *lookup;
						int tempScope = currScope;
						while(tempScope >= 0) {		// search for nearest scope lookup
							lookup = Lookup(currSymnode, hashHead, tempScope);
							if(lookup != NULL)
								break;
							tempScope--;
						}

						if(lookup != NULL && returnStmt == 0 && funcCall == 0) {
							if(lookup->type == USERFUNC) {
								if(currSymnode->scope == lookup->scope) {
									yyerror("Function name redeclaration");
								}
							} else if(lookup->type == LIBFUNC) {
								if(assignExpr == 0)
									yyerror("Function name redeclaration");
							}
						}

						$<exprValue>$ = emit_iftableitem($<exprValue>1);
					}
			|call { printf("call\n"); $<exprValue>$ = $<exprValue>1; funcCall = 1;}
			|objectdef { printf("object\n"); $<exprValue>$ = $<exprValue>1;}
			|funcdef2 { printf("(function)\n"); $<exprValue>$ = $<exprValue>1;}
			|const { printf("const\n"); $<exprValue>$ = $<exprValue>1;}

funcdef2:	openpar funcdef closepar { $<exprValue>$ = $<exprValue>2; }	

lvalue:		ID { 	printf("ID\n");
					Symnode_t *lookup;
					if(currScope == 0) {
						checkVar(yylval.stringValue, GLOBAL);
					} else {
						checkVar(yylval.stringValue, LOCAL);
					}

					int tempScope = currScope;
					while(tempScope >= 0) {		// search for nearest scope lookup
						lookup = Lookup(currSymnode, hashHead, tempScope);
						if(lookup != NULL)
							break;
						tempScope--;
					}

					$<exprValue>$ = newexpr(var_e);
					$<exprValue>$->sym = lookup;
						
				}
			|local ID { printf("local ID\n"); 
						keywordLocal = 1;
						checkVar(yylval.stringValue, LOCAL);
						keywordLocal = 0;

						Symnode_t *lookup;

						int tempScope = currScope;
						while(tempScope >= 0) {		// search for nearest scope lookup
							lookup = Lookup(currSymnode, hashHead, tempScope);
							if(lookup != NULL)
								break;
							tempScope--;
						}

						$<exprValue>$ = newexpr(var_e);
						$<exprValue>$->sym = lookup;
					   	}

			|coloncolon ID { 	printf(":: ID\n"); 
								Symnode_t *newsymnode = Createsymnode(yylval.stringValue, GLOBAL, 0, yylineno, 1, 0, currFuncScope);
								Symnode_t *lookup = Lookup(newsymnode, hashHead, 0);
								currSymnode = lookup;
								if(lookup == NULL)
									yyerror("::lookup not found");
							}
			|member { printf("member\n"); $<exprValue>$ = $<exprValue>1; }
			
member:		lvalue dot ID { printf(". ID\n"); $<exprValue>$ = member_item($<exprValue>1, yylval.stringValue); }
			|lvalue openbracket expr closebracket { printf("value [ expr ]\n"); 
													$<exprValue>1 = emit_iftableitem($<exprValue>$);
													$<exprValue>$ = newexpr(tableitem_e);
													$<exprValue>$->sym = $<exprValue>1->sym;
													$<exprValue>$->index = $<exprValue>3;
													}
			|call dot ID { printf("call . ID\n"); $<exprValue>$ = member_item($<exprValue>$, yylval.stringValue);}
			|call openbracket expr closebracket { printf("call [ expr ]\n"); $<exprValue>$ = member_item($<exprValue>$, yylval.stringValue);}
			
call:		call openpar elist closepar { 	printf("call ( elist )\n");
											emitReverse($<exprValue>3);
											emit(Call, NULL, $<exprValue>$, NULL, 0, yylineno);
											Expr *tmp = newexpr(var_e);
											tmp->sym = newtemp();
											emit(Getretval, tmp, NULL, NULL, 0, yylineno);
											$<exprValue>$ = tmp;
										}
			|lvalue callsuffix 	{ 	printf("lvalue callsuffix\n"); 
									$<exprValue>1 = emit_iftableitem($<exprValue>1);
									if($<exprValue>2->strConst != NULL) {
										Expr* tmp = $<exprValue>1;
										$<exprValue>1 = emit_iftableitem(member_item($<exprValue>1, $<exprValue>2->strConst));
										emitReverse($<exprValue>2->index);
										emit(Param, NULL, tmp, NULL, 0, yylineno);
									}
									emit(Call, NULL, $<exprValue>1, NULL, 0, yylineno); 
									Expr *tmp = newexpr(var_e);
									tmp->sym = newtemp();
									emit(Getretval,tmp, NULL, NULL, 0, yylineno);
									$<exprValue>$ = tmp;
								}
			|funcdef2 openpar elist closepar { printf("(funcdef) (elist)\n"); 
				emitReverse($<exprValue>3);
				emit(Call, NULL, $<exprValue>$, NULL, 0, yylineno);
				Expr *tmp = newexpr(var_e);
				tmp->sym = newtemp();
				emit(Getretval, tmp, NULL, NULL, 0, yylineno);
				$<exprValue>$ = tmp;
			}
			
callsuffix:	normcall { printf("normcall\n"); $<exprValue>$ = $<exprValue>1;}
			|methodcall { printf("methodcall\n"); $<exprValue>$ = $<exprValue>1;}
			
normcall:	openpar elist closepar 	{ 	printf("(elist)\n"); 
										funcRedec = 0;
										Symnode_t *lookup;

										int tempScope = currScope;
										while(tempScope >= 0) {		// search for nearest scope lookup
											lookup = Lookup(currSymnode, hashHead, tempScope);
											if(lookup != NULL)
												break;
											tempScope--;
										}

										if(lookup == NULL) {
											Insert_Symnode(hashHead, currSymnode);
										} else if(lookup->type == USERFUNC || lookup->type == LIBFUNC) {	// FUNCTION CALL
											
										}

										if(currSymnode->type == USERFUNC)
											$<exprValue>$ = newexpr(programfunc_e);
										else
											$<exprValue>$ = newexpr(libraryfunc_e);
										$<exprValue>$->sym = currSymnode;

										emitReverse($<exprValue>2);
									}

			
methodcall:	dotdot ID openpar elist closepar { printf(".. ID (elist)\n");
	$<exprValue>$ = newexpr(conststring_e);
	$<exprValue>$->strConst = malloc(sizeof(char)*strlen($<stringValue>2+1));
	strcpy($<exprValue>$->strConst, $<stringValue>2);
	$<exprValue>$->index = $<exprValue>4;
}
			

elist:		expr tmp_elist { printf("expression\n"); $<exprValue>$ = $<exprValue>1; $<exprValue>$->next = $<exprValue>2; }
			| { $<exprValue>$ = NULL; }

tmp_elist:	comma expr tmp_elist { printf("expression , expression\n"); $<exprValue>$ = $<exprValue>2; $<exprValue>$->next = $<exprValue>3; }
			| { $<exprValue>$ = NULL; }
			

/*tablecreateeeeeeeeee*/
objectdef:	openbracket elist closebracket { printf("[elist]\n"); 
					Expr* tmp = newexpr(newtable_e);
					tmp->sym = newtemp();
					emit(Tablecreate, tmp, NULL ,NULL, 0, yylineno);

					int i = 0;
        			while ($<exprValue>2 != NULL) {
						Expr* offset = newexpr(constint_e);
						offset->intConst=i;
						emit(Tablesetelem, tmp, offset, $<exprValue>2, 0, yylineno);
						$<exprValue>2 = $<exprValue>2->next;
						i++;
        			}						
					$<exprValue>$ = tmp;
			}
			|openbracket indexed closebracket { printf("[indexed]\n"); 
					Expr* tmp = newexpr(newtable_e);
					tmp->sym = newtemp();
					emit(Tablecreate, tmp, NULL ,NULL, 0, yylineno);
        			while ($<exprValue>2 != NULL) {
						emit(Tablesetelem, tmp, $<exprValue>2, $<exprValue>2->index, 0, yylineno);
						$<exprValue>2 = $<exprValue>2->next;
        			}		
					$<exprValue>$ = tmp;		
			}

indexed:	indexedelem indexed_tmp{ printf("indexelem\n"); $<exprValue>$ = $<exprValue>1; $<exprValue>$->next = $<exprValue>2; }
			

indexed_tmp:comma indexedelem indexed_tmp { printf("indexelem, indexelem\n"); $<exprValue>$ = $<exprValue>2; $<exprValue>$->next = $<exprValue>3; }
			| { $<exprValue>$ = NULL; }

indexedelem:opencurlybracket expr colon expr closecurlybracket { printf("{expression:expression}\n"); $<exprValue>$ = $<exprValue>2; $<exprValue>$->index = $<exprValue>4; funcCall = 1;}
			

block:		opencurlybracket { currScope++; } stmt_temp closecurlybracket { printf("{statement}\n");  Hide(hashHead, currScope); currScope--; }
			|opencurlybracket closecurlybracket { printf("{ }\n"); }
			

stmt_temp:	stmt_temp stmt {}
			|

funcdef:	FUNCTION ID {	

							Symnode_t *newsymnode, *lookup;
							
							newsymnode = Createsymnode(yylval.stringValue, USERFUNC, currScope, yylineno, 1, 0, currFuncScope);
							lookup = Lookup(newsymnode, hashHead, currScope);

							if(lookup != NULL)
								yyerror("Function name redeclaration");
							
							Insert_Symnode(hashHead, newsymnode);
							lookup = Lookup(newsymnode, hashHead, currScope);

							$<exprValue>$ = newexpr(programfunc_e);
							$<exprValue>$->sym = lookup;

							$<intValue>1 = nextquadlabel();
							emit(Jump, NULL, NULL, NULL, 0, yylineno);
							emit(Funcstart, $<exprValue>$, NULL, NULL, nextquadlabel(), yylineno);

						} openpar { currScope++; currFormalOffset++; formalOffset[currFormalOffset] = 0;} idlist closepar { push_loopcounter(); currScope--; currFuncScope++; currFormalOffset--; currFuncOffset++; funcOffset[currFuncOffset] = 0; funcReturnCount[currFuncOffset] = 0;
																	} block { 	
																		printf("function ID (idlist) { }\n"); 
																		pop_loopcounter();

																		emit(Funcend, $<exprValue>3, NULL, NULL, nextquadlabel(), yylineno);
																		patchreturn(nextquadlabel(), funcReturnCount[currFuncOffset]);
																		patchlabel($<intValue>1, nextquadlabel()+1);

																		currFuncScope--;
																		currFuncOffset--;
																		$<exprValue>$ = $<exprValue>3;
																	}

			|FUNCTION { 

						Symnode_t *newsymnode, *lookup;
						char name[12];
						snprintf(name, 12, "_f%d", funcName++);
						
						newsymnode = Createsymnode(name, USERFUNC, currScope, yylineno, 1, 0, currFuncScope);
						lookup = Lookup(newsymnode, hashHead, currScope);

						if(lookup != NULL)
							yyerror("Function name redeclaration");

						Insert_Symnode(hashHead, newsymnode);
						lookup = Lookup(newsymnode, hashHead, currScope);

						$<exprValue>$ = newexpr(programfunc_e);
						$<exprValue>$->sym = lookup;

						$<intValue>1 = nextquadlabel();
						emit(Jump, NULL, NULL, NULL, 0, yylineno);
						emit(Funcstart, $<exprValue>$, NULL, NULL, nextquadlabel(), yylineno);
						
						}
			openpar {currScope++; currFormalOffset++; formalOffset[currFormalOffset] = 0;} idlist closepar {push_loopcounter(); currScope--; currFuncScope++; currFormalOffset--; currFuncOffset++; funcOffset[currFuncOffset] = 0; funcReturnCount[currFuncOffset] = 0;
															} block {	
																printf("function (idlist) { }\n"); 
																pop_loopcounter();

																emit(Funcend, $<exprValue>2, NULL, NULL, nextquadlabel(), yylineno);
																patchreturn(nextquadlabel(), funcReturnCount[currFuncOffset]);
																patchlabel($<intValue>1, nextquadlabel()+1);

																currFuncScope--;
																currFuncOffset--;
																$<exprValue>$ = $<exprValue>2;
															}
			

idlist:		ID { 	printf("IDlist\n"); 
					checkVar(yylval.stringValue, FORMAL);
				}


			|ID { 
					checkVar(yylval.stringValue, FORMAL);

			}comma idlist { printf("IDlist ,\n"); }
			|
			

const:		INT { printf("int\n"); 
				$<exprValue>$ = newexpr(constint_e);
				$<exprValue>$->intConst = yylval.intValue;
			}
			|FLOAT { printf("float\n"); 
				$<exprValue>$ = newexpr(constreal_e);
				$<exprValue>$->realConst = yylval.realValue;
			}
			|String { printf("string\n"); 
				$<exprValue>$ = newexpr(conststring_e);
				$<exprValue>$->strConst = malloc(sizeof(char)*strlen(yylval.stringValue+1));
				strcpy($<exprValue>$->strConst, yylval.stringValue);
			}
			|NIL { printf("nil\n"); 
				$<exprValue>$ = newexpr_nil();
			}
			|TRUE { printf("true\n"); 
				$<exprValue>$ = newexpr_true();
			}
			|FALSE { printf("false\n"); 
				$<exprValue>$ = newexpr_false();
			}
			

ifprefix: 	IF openpar expr closepar {
										emit(If_eq, NULL, $<exprValue>3, newexpr_true(), nextquadlabel()+3, yylineno);
										emit(Jump, NULL, NULL, NULL, 0, yylineno);
										$<intValue>$ = nextquadlabel();
									}
elseprefix: ELSE {
					emit(Jump, NULL, NULL, NULL, 0, yylineno);
					$<intValue>$ = nextquadlabel();
				}

ifstmt: 	ifprefix stmt { patchlabel($<intValue>$-1, nextquadlabel()+1); }
			|ifprefix stmt elseprefix stmt { 
				patchlabel($<intValue>1-1, $<intValue>3+1);
				patchlabel($<intValue>3-1, nextquadlabel()+1);
			}

whilestart:	WHILE { $<intValue>$ = nextquadlabel(); }

whilecond:	openpar expr closepar { ++loopcounter;
									++currLoopScope;
									breakCount[currLoopScope] = 0;
									contCount[currLoopScope] = 0;
									emit(If_eq, NULL, $<exprValue>2, newexpr_true(), nextquadlabel()+3, yylineno);
									emit(Jump, NULL, NULL, NULL, 0, yylineno);
									$<intValue>$ = nextquadlabel();
								}
			
whilestmt: 	whilestart whilecond stmt { patchbreak(nextquadlabel()+2, breakCount[currLoopScope]);
										patchcont($<intValue>2-1, contCount[currLoopScope]);
										--loopcounter; 
										--currLoopScope;
										emit(Jump, NULL, NULL, NULL, $<intValue>1+1, yylineno);
										patchlabel($<intValue>2-1, nextquadlabel()+1);
										
									}

forprefix:	FOR openpar elist semicolon M expr semicolon { 
	struct forloop *tmp = malloc(sizeof(struct forloop));
	tmp->test = $<intValue>5;
	tmp->enter = nextquadlabel();
	$<forValue>$ = tmp;
	emit(If_eq, NULL, $<exprValue>6, newexpr_true(), 0, yylineno);
}

forstmt:	forprefix N elist closepar { ++loopcounter; ++currLoopScope; breakCount[currLoopScope] = 0; contCount[currLoopScope] = 0;} N stmt N { 
	patchbreak(nextquadlabel()+1, breakCount[currLoopScope]);
	patchcont($<intValue>2+2, contCount[currLoopScope]);
	--loopcounter; 
	--currLoopScope;
	patchlabel($<forValue>1->enter, $<intValue>6+2);
	patchlabel($<intValue>2, nextquadlabel()+1);
	patchlabel($<intValue>6, $<forValue>1->test+1);
	patchlabel(nextquadlabel()-1, $<intValue>2+2);
}
			
N:			{ $<intValue>$ = nextquadlabel(); emit(Jump, NULL, NULL, NULL, 0, yylineno); }

M:			{ $<intValue>$ = nextquadlabel(); }

returnstmt:	RETURN { 	returnStmt = 1; 
						funcReturnCount[currFuncOffset]++;
						if(currFuncScope == 0)
							yyerror("Return outside a function");
							
					} expr { 
						printf("return expression\n"); returnStmt = 0; 
						emit(Ret, $<exprValue>3, NULL, NULL, 0, yylineno);
						emit(Jump, NULL, NULL, NULL, 0, yylineno);
					}
			|RETURN {
				funcReturnCount[currFuncOffset]++;
				if(currFuncScope == 0)
					yyerror("Return outside a function");
				emit(Ret, NULL, NULL, NULL, 0, yylineno);
				emit(Jump, NULL, NULL, NULL, 0, yylineno);
			}
			semicolon { printf("return ;\n"); }
			

%%

int yyerror(char* yaccProvidedMessage) {
	printf("\n\033[0;31m%s in line %d\033[0m\n", yaccProvidedMessage, yylineno);
	exit(1);
}

int equalsLibFunc(Symnode_t *symnode) {
	if(strcmp(symnode->name,"print")==0 )
		return 1;
	if(strcmp(symnode->name,"input")==0)
		return 1;
	if(strcmp(symnode->name,"objectmemberkeys")==0)
		return 1;
	if(strcmp(symnode->name,"objecttotalmembers")==0)
		return 1;
	if(strcmp(symnode->name,"objectcopy")==0)
		return 1;
	if(strcmp(symnode->name,"totalarguments")==0)
		return 1;
	if(strcmp(symnode->name,"argument")==0)
		return 1;
	if(strcmp(symnode->name,"typeof")==0)
		return 1;
	if(strcmp(symnode->name,"strtonum")==0)
		return 1;
	if(strcmp(symnode->name,"sqrt")==0)
		return 1;
	if(strcmp(symnode->name,"cos")==0)
		return 1;
	if(strcmp(symnode->name,"sin")==0)
		return 1;
	return 0;
}

void checkVar(char* name, enum SymbolType type) {
	Symnode_t *newsymnode = Createsymnode(name, type, currScope, yylineno, 1, 0, currFuncScope);
	Symnode_t *lookup, *lookupGlobal;
	currSymnode = newsymnode;

	lookupGlobal = Lookup(newsymnode, hashHead, 0);

	if(currScope == 0) {
		if(type == LOCAL)
			newsymnode->type = GLOBAL;
	}

	int tempScope = currScope;
	while(tempScope >= 0) {		// search for nearest scope lookup
		lookup = Lookup(newsymnode, hashHead, tempScope);
		if(lookup != NULL)
			break;
		tempScope--;
	}

	if(type == FORMAL) {
		if(equalsLibFunc(newsymnode) == 1)
			yyerror("Collision with library function");	

		if(lookup != NULL && lookup->type == FORMAL)
			yyerror("Formal argument redeclaration");
	}

	if(lookup != NULL && (lookup->type == USERFUNC || lookup->type == LIBFUNC))
		funcRedec = 1;

	if(newsymnode->type == FORMAL) {
		newsymnode->space = FORMALS;
		newsymnode->offset = formalOffset[currFormalOffset]++;
		//printf("\t\t%s %d\n", newsymnode->name, newsymnode->offset);
	} else if(newsymnode->type == LOCAL) {
		newsymnode->space = FUNCTIONS;
		newsymnode->offset = funcOffset[currFuncOffset]++;
		//printf("\t\t%s %d\n", newsymnode->name, newsymnode->offset);
	} else if(currFuncScope == 0) {
		newsymnode->space = PROGRAMS;
		newsymnode->offset = programOffset++;
		//printf("\t\t%s %d\n", newsymnode->name, newsymnode->offset);
	} 

	

	if(lookup != NULL && lookup->type != LIBFUNC) {	
		if(lookup->type == USERFUNC) {
			if(newsymnode->scope != lookup->scope)
				Insert_Symnode(hashHead, newsymnode);
		}

		if(newsymnode->type == FORMAL)
			Insert_Symnode(hashHead, newsymnode);

		if(lookup->fscope < currFuncScope && lookup->type != USERFUNC && lookup->fscope > 0) {		
			yyerror("Cannot access variable");
		}

		if(keywordLocal == 1 && lookup->scope < newsymnode->scope)
			Insert_Symnode(hashHead, newsymnode);
	} else {
		if(equalsLibFunc(newsymnode) == 0)
			Insert_Symnode(hashHead, newsymnode);
	}
}

Expr* newexpr(enum expr_t type) {
    Expr *tmp = (Expr*)malloc(sizeof(Expr));
    tmp->type = type;
    return tmp;
}

Expr* newexpr_false() {
    Expr *tmp = newexpr(constbool_e);
	tmp->boolConst = malloc(sizeof(char)*6);
	strcpy(tmp->boolConst, "false");
    return tmp;
}

Expr* newexpr_true() {
    Expr *tmp = newexpr(constbool_e);
	tmp->boolConst = malloc(sizeof(char)*5);
	strcpy(tmp->boolConst, "true");
    return tmp;
}

Expr* newexpr_nil() {
	Expr *tmp = newexpr(nil_e);
	tmp->nilConst = malloc(sizeof(char)*4);
	strcpy(tmp->nilConst, "nil");
	return tmp;
}

Symnode_t *newtemp() {
	Symnode_t *tmp;
    char name[12];
	snprintf(name, 12, "_t%d", tempVar++);

    if(currScope == 0)
        tmp = Createsymnode(name, GLOBAL, currScope, yylineno, 1, 0, currFuncScope);
    else
        tmp = Createsymnode(name, LOCAL, currScope, yylineno, 1, 0, currFuncScope);

	tmp->line = yylineno;
	if(currFuncScope == 0) {
		tmp->space = PROGRAMS;
		tmp->offset = programOffset++;
	} else {
		tmp->space = FUNCTIONS;
		tmp->offset = funcOffset[currFuncOffset]++;
	}

    Symnode_t *lookup = Lookup(tmp, hashHead, currScope);

	if(lookup != NULL) {
		lookup->line = yylineno;
		lookup->space = tmp->space;
		lookup->offset = tmp->offset;
		return lookup;
	} else {
		Insert_Symnode(hashHead, tmp);
		return tmp;
	}
}

void push_loopcounter() {
	struct lc_stack_t *new_element = (struct lc_stack_t *)malloc(sizeof(struct lc_stack_t));
	new_element->counter = 0;
	new_element->next = NULL;

	if (lcs_top == NULL) {
		lcs_top = new_element;
		lcs_bottom = new_element;
	} else {
        new_element->next = lcs_top;
        lcs_top = new_element;
    }
}

void pop_loopcounter() {
	if (lcs_top != NULL) {
		struct lc_stack_t *tmp = lcs_top;
		lcs_top = lcs_top->next;
		free(tmp);
	}
}

Expr* emit_iftableitem(Expr* e) {
    if(e->type != tableitem_e)
        return e;
    else {
        Expr* result = newexpr(var_e);
        result->sym = newtemp();
        emit(Tablegetelem, result, e, e->index, 0, yylineno);
		return result;
    }
}

Expr* member_item (Expr* lv, char* name) {
    lv = emit_iftableitem(lv);
    Expr* ti = newexpr(tableitem_e);
    ti->sym = lv->sym;
    ti->index = newexpr(conststring_e);
    ti->index->strConst = malloc(sizeof(char)*strlen(name));
    strcpy(ti->index->strConst, name);
    return ti;
}

void emitReverse(Expr* expr) {
	if(expr == NULL) return;
	emitReverse(expr->next);
	emit(Param, NULL, expr, NULL, 0, yylineno);
}

int main(int argc, char** argv) {
	hashHead = newHash();
	init(hashHead);
	if (argc > 1) {
		if (!(yyin = fopen(argv[1], "r"))) { 
			fprintf(stderr, "Cannot read file: %s\n", argv[1]);
			return 1;
		}
	} else {
		yyin = stdin;
	}
	push_loopcounter();
	yyparse();
	printf("\n\n");
    printQuads();
	//free_Hash(hashHead);	PROBLEM ME FREE
	return 0;
}