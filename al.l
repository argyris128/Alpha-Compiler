/*
 *	CS - 340: Compilers
 *	Project - Phase 2
 *	Lexical Analysis - al.l FILE
 *
 *	Dialektakis Antonis		A.M. : 2717
 *	Patramanis Argiris		A.M. : 4379
 *	Vlachakis Zaxarias		A.M. : 4602
 *
 *	Deadline : 28/3/2024
 */
/*	USER CODE -- KODIKAS XRISTI	*/

%{

#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include "parser.h"

#define COLOR_RED "\x1b[31m"
#define COLOR_RESET "\x1b[0m"

char* buffer;
char* temp;
int CountToken = 0;

/*
 *	otan exoume enter mesa sto string tote apothikeuete lathos to lineno tou string
 *	sto telos kai gia auto kratame se alli metavliti to yylineno gia strings
 */
int yylineno_str = 0; 

int* comment_array_open_LINE;
int* comment_array_close_LINE;

int comment_count = 0;

struct a_token{
	unsigned int numLine;
	unsigned int numToken;
	char *name;
	char *content;
	char *type;
	struct a_token *next;
};

struct a_token *head;

int alpha_yylex(void* yylval);
void print(struct a_token *);
struct a_token *initToken(unsigned int, unsigned int, char *, char *, char *);

//STRING		"\"."
//STRING		\"(([.]|[^\"])|(\n)|(\t)|(\\\"))*\"

%}

/*	Flex options	*/
%option noyywrap
%option yylineno

/*	Flex macros	*/

ID			[a-zA-Z][a-zA-Z_0-9]*
INTEGER		[0-9]+
FLOAT		[0-9]+"."[0-9]+
COMMENT_1	"//".*
NEWLINE		[\n]
SPACE		[ \t]+

%x COMMENT_2
%x STRING
%x SPECIAL_CHAR

%%

<INITIAL>"\"" {
	yylineno_str = yylineno;
	buffer = calloc(1, sizeof(char));
	temp = calloc(2, sizeof(char));
	BEGIN(STRING);	
}

<INITIAL>"/*" {
	comment_count++;  // htan 0 egine 1
	comment_array_open_LINE = malloc(sizeof(int));
	comment_array_close_LINE = malloc(sizeof(int));	
	comment_array_open_LINE[comment_count - 1] = yylineno; 
	BEGIN(COMMENT_2);
}

<STRING>"\n" { // OTAN EXOUME ENTER APO PLIKTROLOGIO MESA STO STRING XORIS NA EINAI \n
	//printf("ENGAGED ENTER WITHOUT IN SPECIAL CHAR STATE !!!\n");
	temp[0] = '\n';	
	buffer = realloc(buffer, (strlen(buffer)+2) * sizeof(char));
	strcat(buffer, temp);
}

<STRING>"\\" {
	BEGIN(SPECIAL_CHAR);
}

<STRING>"\"" { //TELOS STRINGAKI	
	//initToken(yylineno_str, ++CountToken, buffer, "string", "char *");	
	yylval.stringValue = strdup(buffer);
	free(buffer);
	free(temp);	
	BEGIN(INITIAL);
	return String;
}

<STRING>. {
	buffer = realloc(buffer, (strlen(buffer)+2) * sizeof(char));
	//printf("\ncounter test is = %d\n", counter_test++);
	strcat(buffer, yytext);
}

<STRING><<EOF>> {
	printf("%sERROR: EOF but there are open string %s at line: %d%s\n", COLOR_RED, yytext, yylineno, COLOR_RESET);
	free(buffer);
	free(temp);
	exit(-1);
}

<SPECIAL_CHAR>"a" {
	//printf("ENGAGED ALERT !!!\n");
	temp[0] = '\a';
	buffer = realloc(buffer, (strlen(buffer)+2) * sizeof(char));
	strcat(buffer, temp);
	BEGIN(STRING);
}

<SPECIAL_CHAR>"b" {
	//printf("ENGAGED BACKSPACE !!!\n");
	temp[0] = '\b';
	buffer = realloc(buffer, (strlen(buffer)+2) * sizeof(char));
	strcat(buffer, temp);
	BEGIN(STRING);	
}

<SPECIAL_CHAR>"f" {
	//printf("ENGAGED FORM FEED !!!\n");
	temp[0] = '\f';
	buffer = realloc(buffer, (strlen(buffer)+2) * sizeof(char));
	strcat(buffer, temp);
	BEGIN(STRING);	
}

<SPECIAL_CHAR>"n" {
	//printf("ENGAGED ENTER !!!\n");
	temp[0] = '\n';
	buffer = realloc(buffer, (strlen(buffer)+2) * sizeof(char));
	strcat(buffer, temp);	
	BEGIN(STRING);	
}

<SPECIAL_CHAR>"r" {
	//printf("ENGAGED CARRIAGE RETURN !!!\n");
	temp[0] = '\r';
	buffer = realloc(buffer, (strlen(buffer)+2) * sizeof(char));
	strcat(buffer, temp);
	BEGIN(STRING);
}

<SPECIAL_CHAR>"t" {
	//printf("ENGAGED TAB !!!\n");
	temp[0] = '\t';
	buffer = realloc(buffer, (strlen(buffer)+2) * sizeof(char));
	strcat(buffer, temp);
	BEGIN(STRING);
}

<SPECIAL_CHAR>"v" {
	//printf("ENGAGED VERTICAL TAB !!!\n");
	temp[0] = '\v';
	buffer = realloc(buffer, (strlen(buffer)+2) * sizeof(char));
	strcat(buffer, temp);
	BEGIN(STRING);	
}

<SPECIAL_CHAR>"\'" {
	//printf("ENGAGED SINGLE AUTAKI !!!\n");
	temp[0] = '\'';
	buffer = realloc(buffer, (strlen(buffer)+2) * sizeof(char));
	strcat(buffer, temp);
	BEGIN(STRING);	
}

<SPECIAL_CHAR>"\"" {
	//printf("ENGAGED DIPLO AUTAKI !!!\n");
	temp[0] = '\"';
	buffer = realloc(buffer, (strlen(buffer)+2) * sizeof(char));
	strcat(buffer, temp);
	BEGIN(STRING);	
}

<SPECIAL_CHAR>"\?" {
	//printf("ENGAGED EROTIMATIKO !!!\n");
	temp[0] = '\?';
	buffer = realloc(buffer, (strlen(buffer)+2) * sizeof(char));
	strcat(buffer, temp);
	BEGIN(STRING);	
}

<SPECIAL_CHAR>"\\" {
	//printf("ENGAGED BACKSLASH !!!\n");
	temp[0] = '\\';
	buffer = realloc(buffer, (strlen(buffer)+2) * sizeof(char));
	strcat(buffer, temp);
	BEGIN(STRING);	
}

<SPECIAL_CHAR><<EOF>> {
	printf("%sERROR: EOF but there are open string %s at line: %d%s", COLOR_RED, yytext, yylineno, COLOR_RESET);
	free(buffer);
	free(temp);
	exit(-1);
}

<SPECIAL_CHAR>. {
	printf("%sERROR: Undefined Escape Character %s at line: %d\n%s", COLOR_RED, yytext, yylineno, COLOR_RESET);
	//free(buffer);
	//free(temp);
	//BEGIN(INITIAL);
	//exit(-1);
	BEGIN(STRING);
}

<COMMENT_2>"/*" {
	comment_count++; // eimaste se nested comment
	comment_array_open_LINE = realloc(comment_array_open_LINE, (comment_count) * sizeof(int));
	comment_array_close_LINE = realloc(comment_array_close_LINE, (comment_count) * sizeof(int));
	//prosoxi h mnimi einai panta -1 apo to comment_count
	comment_array_open_LINE[comment_count - 1] = yylineno;
}

<COMMENT_2>"*"+ {;}
<COMMENT_2>[^/*\n]+ {;}
<COMMENT_2>[/] {;}
<COMMENT_2>\n {;}

<COMMENT_2>"*"+"/" {
	comment_array_close_LINE[comment_count - 1] = yylineno;
	char* temp_str;
	temp_str = calloc(100, sizeof(char));
	
	if(comment_count == 1){ // protos sxolio - kleinei teleutaio
		//tsekaro an open_line and close_line einai idia an einai idia tote one-line comment
		if(comment_array_open_LINE[comment_count - 1] == comment_array_close_LINE[comment_count - 1]){
			sprintf(temp_str, "One-line comment on line %d", comment_array_open_LINE[comment_count - 1] );			
			//initToken(comment_array_open_LINE[comment_count - 1], ++CountToken, "", temp_str, "char*");
		} else{
			sprintf(temp_str, "Multi-line comment on lines %d - %d", comment_array_open_LINE[comment_count - 1], comment_array_close_LINE[comment_count - 1] );
			//initToken(comment_array_open_LINE[comment_count - 1], ++CountToken, "", temp_str, "char*");
		}
		BEGIN(INITIAL);
		
	} else { // an mpei edo exoume emfoleumena sxolia		
		//tsekaro an open_line and close_line einai idia an einai idia tote one-line comment
		if(comment_array_open_LINE[comment_count - 1] == comment_array_close_LINE[comment_count - 1]){
			sprintf(temp_str, "One-line nested comment on line %d", comment_array_open_LINE[comment_count - 1] );			
			//initToken(comment_array_open_LINE[comment_count - 1], ++CountToken, "", temp_str, "char*");
		} else{
			sprintf(temp_str, "Multi-line nested comment on lines %d - %d", comment_array_open_LINE[comment_count - 1], comment_array_close_LINE[comment_count - 1] );
			//initToken(comment_array_open_LINE[comment_count - 1], ++CountToken, "", temp_str, "char*");
		}
		//BEGIN(COMMENT_2);
	}
	comment_count--;
	comment_array_open_LINE = realloc(comment_array_open_LINE, (comment_count) * sizeof(int));
	comment_array_close_LINE = realloc(comment_array_close_LINE, (comment_count) * sizeof(int));
	free(temp_str);
}

<COMMENT_2><<EOF>> {
	printf("%sERROR: EOF but there are open comments\n%s", COLOR_RED, COLOR_RESET);
	while (comment_count!=0) {
		if(comment_count ==1){		
			printf("Closing comments expected, opened at line: %d\n",comment_array_open_LINE[comment_count - 1]);
		} else{
			printf("Closing nested comments expected, opened at line: %d\n",comment_array_open_LINE[comment_count - 1]); 
		}
		comment_count--;
	}
	exit(-1);
	//BEGIN(INITIAL);
}


if			{ return IF; }//initToken(yylineno, ++CountToken, yytext, "KEYWORD IF", "enumerated"); }
else		{ return ELSE; }//initToken(yylineno, ++CountToken, yytext, "KEYWORD ELSE", "enumerated"); }
while		{ return WHILE; }//initToken(yylineno, ++CountToken, yytext, "KEYWORD WHILE", "enumerated"); }
for			{ return FOR; }//initToken(yylineno, ++CountToken, yytext, "KEYWORD FOR", "enumerated"); }
function	{ return FUNCTION; }//initToken(yylineno, ++CountToken, yytext, "KEYWORD FUNCTION", "enumerated"); }
return		{ return RETURN; }//initToken(yylineno, ++CountToken, yytext, "KEYWORD RETURN", "enumerated"); }
break		{ return BREAK; }//initToken(yylineno, ++CountToken, yytext, "KEYWORD BREAK", "enumerated"); }
continue	{ return CONTINUE; }//initToken(yylineno, ++CountToken, yytext, "KEYWORD CONTINUE","enumerated"); }
and			{ return AND; }//initToken(yylineno, ++CountToken, yytext, "KEYWORD AND", "enumerated"); }
not			{ return NOT; }//initToken(yylineno, ++CountToken, yytext, "KEYWORD NOT", "enumerated"); }
or			{ return OR; }//initToken(yylineno, ++CountToken, yytext, "KEYWORD OR", "enumerated"); }
local		{ return local; }//initToken(yylineno, ++CountToken, yytext, "KEYWORD LOCAL", "enumerated"); }
true		{ return TRUE; }//initToken(yylineno, ++CountToken, yytext, "KEYWORD TRUE", "enumerated"); }
false		{ return FALSE; }//initToken(yylineno, ++CountToken, yytext, "KEYWORD FALSE", "enumerated"); }
nil			{ return NIL; }//initToken(yylineno, ++CountToken, yytext, "KEYWORD NIL", "enumerated"); }


"="			{ return equal; }//initToken(yylineno, ++CountToken, yytext, "OPERATOR ASSIGN", "enumerated"); }
"+"			{ return plus; }//initToken(yylineno, ++CountToken, yytext, "OPERATOR PLUS", "enumerated"); }
"-"			{ return minus; }//initToken(yylineno, ++CountToken, yytext, "OPERATOR MINUS", "enumerated"); }
"*"			{ return mul; }//initToken(yylineno, ++CountToken, yytext, "OPERATOR MULTIPLICATION", "enumerated"); }
"/"			{ return division; }//initToken(yylineno, ++CountToken, yytext, "OPERATOR DIVISION", "enumerated"); }
"%"			{ return mod; }//initToken(yylineno, ++CountToken, yytext, "OPERATOR MODULO", "enumerated"); }
"=="		{ return equalequal; }//initToken(yylineno, ++CountToken, yytext, "OPERATOR EQUAL", "enumerated"); }
"!="		{ return notequal; }//initToken(yylineno, ++CountToken, yytext, "OPERATOR NOT_EQUAL", "enumerated"); }
"++"		{ return plusplus; }//initToken(yylineno, ++CountToken, yytext, "OPERATOR PLUS_PLUS", "enumerated"); }
"--"		{ return minusminus; }//initToken(yylineno, ++CountToken, yytext, "OPERATOR MINUS_MINUS", "enumerated"); }
">"			{ return greater; }//initToken(yylineno, ++CountToken, yytext, "OPERATOR GREATER", "enumerated"); }
"<"			{ return less; }//initToken(yylineno, ++CountToken, yytext, "OPERATOR LOWER", "enumerated"); }
">="		{ return greaterequal; }//initToken(yylineno, ++CountToken, yytext, "OPERATOR GREATER_EQUAL", "enumerated"); }
"<="		{ return lessequal; }//initToken(yylineno, ++CountToken, yytext, "OPERATOR LOWER_EQUAL", "enumerated"); }


"{"			{ return opencurlybracket; }//initToken(yylineno, ++CountToken, yytext, "PUNCTUATION LEFT_CURLY_BRACKET", "enumerated"); }
"}"			{ return closecurlybracket; }//initToken(yylineno, ++CountToken, yytext, "PUNCTUATION RIGHT_CURLY_BRACKET", "enumerated"); }
"["			{ return openbracket; }//initToken(yylineno, ++CountToken, yytext, "PUNCTUATION LEFT_BRACKET", "enumerated"); }
"]"			{ return closebracket; }//initToken(yylineno, ++CountToken, yytext, "PUNCTUATION RIGHT_BRACKET", "enumerated"); }
"."			{ return dot; }//initToken(yylineno, ++CountToken, yytext, "PUNCTUATION DOT", "enumerated"); }
".."		{ return dotdot; }//initToken(yylineno, ++CountToken, yytext, "PUNCTUATION DOUBLE_DOT", "enumerated"); }
"("			{ return openpar; }//initToken(yylineno, ++CountToken, yytext, "PUNCTUATION LEFT_PARENTHESIS", "enumerated"); }
")"			{ return closepar; }//initToken(yylineno, ++CountToken, yytext, "PUNCTUATION RIGHT_PARENTHESIS", "enumerated"); }
";"			{ return semicolon; }//initToken(yylineno, ++CountToken, yytext, "PUNCTUATION SEMICOLON", "enumerated"); }
","			{ return comma; }//initToken(yylineno, ++CountToken, yytext, "PUNCTUATION COMA", "enumerated"); }
":"			{ return colon; }//initToken(yylineno, ++CountToken, yytext, "PUNCTUATION COLON", "enumerated"); }
"::"		{ return coloncolon; }//initToken(yylineno, ++CountToken, yytext, "PUNCTUATION DOUBLE_COLON", "enumerated"); }


{ID}		{ yylval.stringValue = strdup(yytext); return ID; }//initToken(yylineno, ++CountToken, yytext, "ID", "enumerated"); }

{INTEGER}	{ yylval.intValue = atoi(yytext); return INT; }//initToken(yylineno, ++CountToken, yytext, "INTCONST", "integer"); }

{NEWLINE}	{ ; }
	
{SPACE}		{ ; }

{FLOAT}		{ yylval.realValue = atof(yytext); return FLOAT; }//initToken(yylineno, ++CountToken, yytext, "REALCONST", "float"); }

{COMMENT_1}		{ ;
			/*
			char* temp_str;
			temp_str = calloc(100, sizeof(char));
			sprintf(temp_str, "One-line comment on line %d", yylineno);	
			initToken(yylineno, ++CountToken, "", temp_str, "char*"); 
			free(temp_str);	
			*/
		}

.		{
			printf("%sERROR: Undefined %s at line: %d\n%s", COLOR_RED, yytext,yylineno, COLOR_RESET);
			BEGIN(INITIAL);
			//exit(-1);
		}
%%
/*
int main (int argc, char** argv) {
	head=(struct a_token *)malloc(sizeof(struct a_token));
	head->next=(struct a_token *)malloc(sizeof(struct a_token));
	head->next=NULL;
	if (argc > 1) {
		if (!(yyin = fopen(argv[1], "r"))) { 
			fprintf(stderr, "Cannot read file: %s\n", argv[1]);
			return 1;
		}
	} else {
		yyin = stdin;
	}
	yylex();
	print(head);
	return 0;
}

int alpha_yylex(void *yylval){
	struct a_token *tmp=head;
	while(tmp->next!=NULL){
		tmp=tmp->next;
	}
	tmp->next=yylval;
	return 0;
}
	sinartisi ektiposis	

void print(struct a_token *head){
	
	printf("\t\t\t----------------	Lexical Analysis	----------------\n");
	printf("LineNumber\tTokenNumer\tContent\t\tName\t\t\t\tType\n");
	struct a_token *tmp = head->next;
	while(tmp!=NULL){
		printf("%d:\t\t#%d\t\t\"%s\"\t\t%s\t\t<--%s\n",tmp->numLine,tmp->numToken,tmp->content,tmp->name,tmp->type);		
		
		//printf("%d:\t\t#%d\t\t%s\t\t%s\t\t-->%s\n",tmp->numLine,tmp->numToken,tmp->type, tmp->name, tmp->content);
		tmp=tmp->next;
	}
	
}

 *	numLine == arithmos grammis
 *	numToken == arithmos token
 *	content == periexomena token px :: , :
 *	name == onoma token px PUNCTUATION DOUBLE_COLON , PUNCTUATION COLON
 *	type == typos token px enumerated, char *

struct a_token *initToken(unsigned int numLine, unsigned int numToken, char *content, char *name, char *type) {

	struct a_token *tmp = malloc(sizeof(struct a_token));
	tmp->next = (struct a_token *)malloc(sizeof(struct a_token));
	
	tmp->numLine = numLine;
	tmp->numToken = numToken;
	tmp->content = strdup(content);
	tmp->name = strdup(name);
	tmp->type = strdup(type);	
	tmp->next=NULL;
	alpha_yylex(tmp);
	return tmp;
}
 */