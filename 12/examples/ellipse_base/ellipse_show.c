/*
Модуль для отображения эллипса.

Маткин Илья Александрович	27.11.2023
*/


#include "ellipse_show.h"

#include <windows.h>


//----------------------------------------


typedef struct _DrawEllipseContext {

	unsigned int leftOffset;
	unsigned int bottomOffset;
	unsigned int a;
	unsigned int b;
	HDC hdc;
	unsigned int prevPointX;
	unsigned int prevPointY;
} DrawEllipseContext;


//----------------------------------------

#define UNUSES_VALUE	0xFFFFFFFF

static void DrawEllipsePoint (void *ctx, EllipseCoordinateType x, EllipseCoordinateType y) {

DrawEllipseContext *dec = (DrawEllipseContext*) ctx;

unsigned int currentPointX = x + dec->a + dec->leftOffset;
unsigned int currentPointY = y + dec->b + dec->bottomOffset;

	if (dec->prevPointX != UNUSES_VALUE && dec->prevPointY != UNUSES_VALUE) {
		LineTo (dec->hdc, currentPointX, currentPointY);
		}
	else {
		MoveToEx(dec->hdc, currentPointX, currentPointY, NULL);
		}

	dec->prevPointX = currentPointX;
	dec->prevPointY = currentPointY;

	return;
}



void ShowEllipse (HDC hdc, unsigned int leftOffset, unsigned int bottomOffset, unsigned int width, unsigned int hight) {

	DrawEllipseContext ctx = {leftOffset, bottomOffset, width / 2, hight / 2, hdc, UNUSES_VALUE, UNUSES_VALUE};

	EnumerateAllEllipsePoints (ctx.a, ctx.b, DrawEllipsePoint, &ctx);

	return;
}



void ShowEllipseByPoint (HDC hdc, unsigned int leftOffset, unsigned int bottomOffset, unsigned int width, unsigned int hight) {

	DrawEllipseContext ctx = {leftOffset, bottomOffset, width / 2, hight / 2, hdc, UNUSES_VALUE, UNUSES_VALUE};

	EllipseCoordinateType t = EllipsePointStartValue;

	do {
		EllipseCoordinateType x;
		EllipseCoordinateType y;
		t = GetNextEllipsePoints (ctx.a, ctx.b, &x, &y, t);
		DrawEllipsePoint (&ctx, x, y);
	} while (t != EllipsePointStartValue);

	return;
}