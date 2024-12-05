#include "SymTable.h"
#include "Quads.h"

Quad* quads = NULL;
unsigned total = 0;
unsigned int currQuad = 0;

#define EXPAND_SIZE 1024
#define CURR_SIZE (total*sizeof(Quad))
#define NEW_SIZE (EXPAND_SIZE*sizeof(Quad)+CURR_SIZE)

static inline char *opToString(enum iopcode op) {
    static char *strings[] = {  "assign", "add", "sub",
                                "mul", "div", "mod",
                                "uminus", "and", "or",
                                "not", "if_eq", "if_noteq",
                                "if_lesseq", "if_greatereq", "if_less",
                                "if_greater", "jump", "call", "param",
                                "return", "getretval", "funcstart",
                                "funcend", "tablecreate",
                                "tablegetelem", "tablesetelem"
                            };
    return strings[op];
}

void printQuads() {
    Quad *q = quads;
    int i = 0;

    printf("quad#\topcode\t\tresult\t\targ1\t\targ2\t\tlabel\n");
    printf("------------------------------------------------------------------------------\n");

   for(i = 0; i < currQuad; i++) {
        switch(q[i].op) {
            case 0: case 1: case 2: case 3: case 4: case 5: case 6: case 7: case 8: case 9: case 17: case 18: case 19: case 22:
                printf("%d:\t%s\t\t%s\t\t%s\t\t%s\t\t%s\n", i+1, opToString(q[i].op), printExpr(q[i].result), printExpr(q[i].arg1), printExpr(q[i].arg2), " ");
                break;
            case 10: case 14: case 16:           
                printf("%d:\t%s\t\t%s\t\t%s\t\t%s\t\t%d\n", i+1, opToString(q[i].op), printExpr(q[i].result), printExpr(q[i].arg1), printExpr(q[i].arg2), q[i].label);
                break;
            case 11: case 12: case 13: case 15:
                printf("%d:\t%s\t%s\t\t%s\t\t%s\t\t%d\n", i+1, opToString(q[i].op), printExpr(q[i].result), printExpr(q[i].arg1), printExpr(q[i].arg2), q[i].label);
                break;
            case 20: case 21: case 23: case 24: case 25:
                printf("%d:\t%s\t%s\t\t%s\t\t%s\t\t%s\n", i+1, opToString(q[i].op), printExpr(q[i].result), printExpr(q[i].arg1), printExpr(q[i].arg2), " ");
                break;
        }
    }

    printf("\n------------------------------------------------------------------------------\n");
}

void emit(enum iopcode op, Expr* result, Expr* arg1, Expr* arg2, unsigned label, unsigned line) {
    if(currQuad == total) {
        Quad *tmp = (Quad*)malloc(NEW_SIZE);
        memcpy(tmp, quads, CURR_SIZE);
        quads = tmp;
        total += EXPAND_SIZE;
    }

    Quad *q = quads + currQuad;

    q->op = op;
    q->result = result;
    q->arg1 = arg1;
    q->arg2 = arg2;
    q->label = label;
    q->line = line;

    currQuad++;
}

unsigned nextquadlabel() {
    return currQuad;
}

void patchreturn(unsigned label, int count) {
    Quad q = quads[currQuad];
    int i;

    for(i = currQuad-1; i >= 0; i--) {
        if(quads[i].op == Ret && quads[i+1].label == 0 && count > 0) {
            quads[i+1].label = label;
            count--;
            if(count == 0)
                return;
        }
    }
}

char *printExpr(Expr *expr) {
    enum expr_t type;
    char *tmp = malloc(sizeof(char)*100);
    if(expr == NULL)
        return " ";
    type = expr->type;
    if (type == var_e || type == assignexpr_e || type == arithexpr_e || type == boolexpr_e || type == programfunc_e || type == libraryfunc_e || type == tableitem_e || type == newtable_e)
        return expr->sym->name;
    if (type == constint_e) {
        sprintf(tmp, "%d", expr->intConst);
        return tmp;
    }
    if (type == constreal_e) {
        sprintf(tmp, "%g", expr->realConst);
        return tmp;
    }
    if (type == constbool_e) {
        if(strcmp(expr->boolConst, "true") == 0) return "\'true\'";
        else return "\'false\'";
    }
    if (type == conststring_e) {
        sprintf(tmp, "\"%s\"", expr->strConst);
        return tmp;
    }
    if (type == nil_e)
        return "nil";
}

void patchlabel(unsigned quadNo, unsigned label) {
    printf("\t%d %d\n", quadNo, label);
    quads[quadNo].label = label;
}

void patchbreak(unsigned label, int count) {
    Quad q = quads[currQuad];
    int i;

    for(i = currQuad; i >= 0; i--) {
        if(quads[i].label == -1 && count > 0) {
            quads[i].label = label;
            count--;
            if(count == 0)
                return;
        }
    }
}

void patchcont(unsigned label, int count) {
    Quad q = quads[currQuad];
    int i;

    for(i = currQuad; i >= 0; i--) {
        if(quads[i].label == -2 && count > 0) {
            quads[i].label = label;
            count--;
            if(count == 0)
                return;
        }
    }
}