#include "SymTable.h"

#ifndef QUADS_H_
#define QUADS_H_

enum iopcode {
    Assign, Add, Sub,
    Mul, Div, Mod,
    Uminus, And, Or,
    Not, If_eq, If_noteq,
    If_lesseq, If_greatereq, If_less,
    If_greater, Jump, Call, Param,
    Ret, Getretval, Funcstart,
    Funcend, Tablecreate,
    Tablegetelem, Tablesetelem
};

enum expr_t {
    var_e,
    tableitem_e,
    programfunc_e,
    libraryfunc_e,
    arithexpr_e,
    boolexpr_e,
    assignexpr_e,
    newtable_e,
    constint_e,
    constreal_e,
    constbool_e,
    conststring_e,
    nil_e
};

typedef struct expr {
    enum expr_t type;
    Symnode_t *sym;
    struct expr *index;
    double realConst;
    int intConst;
    char *strConst;
    char *boolConst;
    char *nilConst;
    struct expr *next;
}Expr;

typedef struct quad {
    enum iopcode op;
    Expr *result;
    Expr *arg1;
    Expr *arg2;
    unsigned label;
    unsigned line;
}Quad;

struct forloop {
    int test, enter;
};

extern void push_loopcounter (void);
extern void pop_loopcounter (void);

void printQuads();
char *printExpr(Expr *expr);

static inline char *opToString(enum iopcode op);
void emit(enum iopcode op, Expr* result, Expr* arg1, Expr* arg2, unsigned label, unsigned line);
Expr* newexpr(enum expr_t);
Symnode_t *newtemp();
unsigned nextquadlabel();
void patchreturn(unsigned label, int count);
Expr* newexpr_false();
Expr* newexpr_true();
Expr* newexpr_nil();
void patchlabel(unsigned quadNo, unsigned label);
void patchbreak(unsigned label, int count);
void patchcont(unsigned label, int count);
Expr* member_item (Expr* lv, char* name);
Expr* emit_iftableitem(Expr* e);
void emitReverse(Expr* expr);

#endif