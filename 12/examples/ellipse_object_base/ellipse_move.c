/*
Модуль для отображения эллипса.

Маткин Илья Александрович	27.11.2024
*/


#include "ellipse_move.h"

#include <windows.h>


//----------------------------------------


struct _EllipseMoveContext {

	unsigned int leftOffset;
	unsigned int bottomOffset;
	unsigned int a;
	unsigned int b;
	HWND hwnd;
    EllipseCoordinateType t;
};


//----------------------------------------

#define UNUSES_VALUE	0xFFFFFFFF



void MoveEllipseToNextPoint (EllipseMoveContext* ctx) {

    EllipseCoordinateType x;
	EllipseCoordinateType y;
	ctx->t = GetNextEllipsePoints (ctx->a, ctx->b, &x, &y, ctx->t);

    x += ctx->a;
    y += ctx->b;

    MoveWindow (ctx->hwnd, x, y, 10, 10, TRUE);

	return;
}


EllipseMoveContext* CreateEllipseContext (unsigned int leftOffset, unsigned int bottomOffset, unsigned int width, unsigned int hight, HWND hwnd) {

    EllipseMoveContext *ret = (EllipseMoveContext*) malloc (sizeof(EllipseMoveContext));
    if (!ret) {
        return NULL;
        }

    ret->leftOffset = leftOffset;
    ret->bottomOffset = bottomOffset;
    ret->a = width / 2;
    ret->b = hight / 2;
    ret->hwnd = hwnd;
    ret->t = EllipsePointStartValue;

    return ret;
}
