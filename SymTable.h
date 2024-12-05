#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#ifndef SYMTABLE_H_
#define SYMTABLE_H_

#define SIZE 65521

enum SymbolType {
	GLOBAL, LOCAL, FORMAL, USERFUNC, LIBFUNC
};

enum ScopeSpace {
	PROGRAMS, FUNCTIONS, FORMALS
};

typedef struct Symnode {
	char *name;
	enum SymbolType type;
	int scope;	
	int line;
	int active;
	int local;
	int fscope;
	//struct Symnode *arguments;
	struct Symnode *next; // epomeno sto idio hash
	struct Symnode *next_same_scope; // epomeno sto idio scope
	struct Symnode *next_scope; // epomeno scope

	enum ScopeSpace space; // scope space
	int offset; // offset in scope space

	//struct Symnode *next_scope;
} Symnode_t;

typedef struct HashTable{
    int count;
	Symnode_t *head_scope;
    Symnode_t *hashTable[SIZE];
} HashTable_t;

//Symnode_t *head_scope;
//Symnode_t *hashTable[SIZE];

HashTable_t *newHash(); /*me thn klhsh aftou tha orisoume to head allou */

unsigned int Hash(char *name); /*idia*/

Symnode_t *Createsymnode(char *name, enum SymbolType type, int scope, int line, int active, int local, int fscope);

/*me param to head ?!? to psaxnw akoma*/
void Insert_Symnode(HashTable_t *HashHead, Symnode_t *symnode); /*param tha pairnei kati pouy eftiakse to create*/

void init(HashTable_t *HashHead);

void printScopes(HashTable_t *HashHead);
Symnode_t *Findscope(HashTable_t *HashHead,int scope);
void Hide(HashTable_t *HashHead, int scope);

void free_Hash(HashTable_t *HashHead);

Symnode_t *Lookup(Symnode_t *symnode, HashTable_t *HashHead, int scope);

/*
int hasaccess(Symnode *new_symnode, Symnode *existing_symnode, char *option);


*/

#endif
