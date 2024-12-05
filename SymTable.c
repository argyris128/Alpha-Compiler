#include "SymTable.h"
#define SIZE 65521
#define HASH_MULTIPLIER 65599


unsigned int Hash(char *name) {
    int i;
    unsigned int uiHash = 0U;
    for (i = 0; name[i] != '\0'; i++)
        uiHash = uiHash * HASH_MULTIPLIER + name[i];
    return (uiHash % SIZE);
}

HashTable_t *newHash() {
    HashTable_t *newHash = malloc(sizeof(HashTable_t));
    if (newHash == NULL) {
        printf("Could not allocate new HashTable\n");
        exit(EXIT_FAILURE);   
    }
    newHash->count = 0;
    newHash->head_scope=NULL;
    for (int i = 0; i < SIZE; i++) {
        newHash->hashTable[i] = NULL;
    }
    return newHash;
}
	
Symnode_t *Createsymnode(char *name, enum SymbolType type, int scope, int line, int active, int local, int fscope) {
    Symnode_t *newsymnode;
    newsymnode = (Symnode_t *) malloc(sizeof(Symnode_t));
    if (newsymnode == NULL) {
        printf("Could not allocate new Symnode\n");
        exit(EXIT_FAILURE);
    }
	newsymnode->name = strdup(name);
	newsymnode->type = type;
	newsymnode->scope = scope;
	newsymnode->line = line;
	newsymnode->active = active;
    newsymnode->local = local;
	newsymnode->fscope = fscope;
    newsymnode->next = NULL;
	newsymnode->next_same_scope = NULL;
	newsymnode->next_scope = NULL;
    return newsymnode;
}



void Insert_Symnode(HashTable_t *HashHead, Symnode_t *symnode) {
    unsigned int index = Hash(symnode->name);

    Symnode_t *currentNode = HashHead->hashTable[index];
    if (currentNode == NULL) {
        HashHead->hashTable[index] = symnode;
    } else {
        symnode->next = currentNode;
        HashHead->hashTable[index] = symnode;
    }
    // Sindesi sto head_scope //DOULEVEI TELEIA TO DOKIMASA
	if (HashHead->head_scope == NULL){ // ean to head_scope einai adeio
        HashHead->head_scope = symnode;
	} else if (symnode->scope < HashHead->head_scope->scope){ // to head_scope eina megalitero
		symnode->next_scope = HashHead->head_scope;
        HashHead->head_scope = symnode;
	} else {
		Symnode_t *current = HashHead->head_scope;
		// diatrexoume mexri to epomeno na einai iso h megalitero
		while (current->next_scope != NULL && current->next_scope->scope <= symnode->scope) {
            current = current->next_scope; 
            
        }
		//ean eimaste hdh sto iparxon scope tote to vazoume sto telos
		if(current != NULL && current->scope == symnode->scope){ 
			while(current->next_same_scope != NULL){
				current = current-> next_same_scope;
                
			}
			current-> next_same_scope= symnode;
            symnode->next_same_scope = NULL;
		//to scope poy anazitame den iparxei kai to epomeno einai NULL
		} else if(current->next_scope == NULL){
			current->next_scope = symnode;
            symnode->next_scope = NULL;
		} else {
		//to scope poy anazitame den iparxei alla iparxei megalitero ara to vazoume sth mesi
		symnode->next_scope = current->next_scope;
		current->next_scope = symnode;
		}
	}
}

	
void init(HashTable_t *HashHead) {
    Insert_Symnode(HashHead, Createsymnode("print", LIBFUNC, 0, 0, 1, 0, 0));
    Insert_Symnode(HashHead, Createsymnode("input", LIBFUNC, 0, 0, 1, 0, 0));
    Insert_Symnode(HashHead, Createsymnode("objectmemberkeys", LIBFUNC, 0, 0, 1, 0, 0));
    Insert_Symnode(HashHead, Createsymnode("objecttotalmembers", LIBFUNC, 0, 0, 1, 0, 0));
    Insert_Symnode(HashHead, Createsymnode("objectcopy", LIBFUNC, 0, 0, 1, 0, 0));
    Insert_Symnode(HashHead, Createsymnode("totalarguments", LIBFUNC, 0, 0, 1, 0, 0));
    Insert_Symnode(HashHead, Createsymnode("argument", LIBFUNC, 0, 0, 1, 0, 0));
    Insert_Symnode(HashHead, Createsymnode("typeof", LIBFUNC, 0, 0, 1, 0, 0));
    Insert_Symnode(HashHead, Createsymnode("strtonum", LIBFUNC, 0, 0, 1, 0, 0));
    Insert_Symnode(HashHead, Createsymnode("sqrt", LIBFUNC, 0, 0, 1, 0, 0));
    Insert_Symnode(HashHead, Createsymnode("cos", LIBFUNC, 0, 0, 1, 0, 0));
    Insert_Symnode(HashHead, Createsymnode("sin", LIBFUNC, 0, 0, 1, 0, 0));
    
    return;
}


char *GetSymbolType(Symnode_t *symnode) {
    if (symnode == NULL) {
        printf("Symnode is NULL\n");
        exit(EXIT_FAILURE);
    }
    if (symnode->type == LIBFUNC) {
        return "library function";
    } else if (symnode->type == USERFUNC) {
        return "user function";
    } else if (symnode->type == FORMAL) {
        return "formal argument";
    } else if (symnode->type == GLOBAL) {
        return "global variable";
    } else {
        return "local variable";
    }
    return "UNKNOWN VARIABLE-FUNCTION";
}


void printScopes(HashTable_t *HashHead) {
    Symnode_t *curr = HashHead->head_scope;
    while (curr != NULL) {
        printf("------------     Scope #%d     ------------\n", curr->scope);
        Symnode_t *temp = curr;
        while (temp != NULL && temp->scope == curr->scope) {
            printf("\"%s\" [%s] (line %d) (scope %d)\n", temp->name, GetSymbolType(temp), temp->line, temp->scope);
            temp = temp->next_same_scope;
        }
        printf("\n");
        curr = curr->next_scope;
    }
}


void Hide(HashTable_t *HashHead, int scope){
    Symnode_t *curr;
    curr = HashHead->head_scope;  
    while(curr != NULL){
        if (curr->scope == (unsigned int)scope) {
            while(curr != NULL) {
                curr->active = 0;  
                curr = curr->next_same_scope;
                
            }
            return;
        }
        curr = curr->next_scope;

    }
    return;
}


void free_Hash(HashTable_t *HashHead) {
    for (int i = 0; i < SIZE; i++) {
        Symnode_t *current = HashHead->hashTable[i];
        while (current != NULL) {
            Symnode_t *temp = current;
            current = current->next;
            free(temp); 
        }
    }
    free(HashHead);
}

Symnode_t *Lookup(Symnode_t *symnode, HashTable_t *HashHead, int scope) {
    Symnode_t *curr;
    curr = HashHead->head_scope;
    while(curr != NULL){
        if (curr->scope == (unsigned int)scope) {
            //vrikame to scope
            break;
        }
        curr = curr->next_scope;
       
    }

    while(curr != NULL){
        if(strcmp(curr->name,symnode->name)==0 && curr->active == 1) {
            //vrikame idio simvolo, to epistrefoume
            return curr;
        }
        curr = curr->next_same_scope;
        
    }

    //epistrefoume NULL an den vroume tipota
    return NULL;
}


/*
void printScopes(HashTable_t *HashHead) {
    Symnode_t *curr;

    curr = HashHead->head_scope;
    while (curr != NULL) {
        printf("---------     Scope #%d     ---------\n", curr->value.varVal->scope);
        while (curr != NULL && curr->value.varVal->scope == curr->value.varVal->scope) {
            if (curr->type == GLOBAL || curr->type == LOCAL || curr->type == FORMAL) {
                printf("%s [%s] (line %d) (scope %d)\n", curr->value.varVal->name, SymbolType(curr->type), curr->value.varVal->line, curr->value.varVal->scope);
            } else if (curr->type == USERFUNC || curr->type == LIBFUNC) {
                printf("%s [%s] (line %d) (scope %d)\n", curr->value.funcVal->name, SymbolType(curr->type), curr->value.funcVal->line, curr->value.funcVal->scope);
            }
            curr = curr->next_scope;
        }
    }
}*/
			//printf(" "%s" [%s] (line %d) (scope %d)\n", strdup(curr2 ->name), strdup(curr2 -> type), curr2 ->line, curr2->scope);
