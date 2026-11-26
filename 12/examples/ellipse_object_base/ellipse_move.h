/*
*/


#ifndef	_ELLIPSE_MOVE_H_
#define _ELLIPSE_MOVE_H_

#include "ellipse_math.h"

#include <windows.h>


//----------------------------------------

typedef struct _EllipseMoveContext EllipseMoveContext;

void MoveEllipseToNextPoint (struct _EllipseMoveContext* ctx);

struct _EllipseMoveContext* CreateEllipseContext (unsigned int leftOffset, unsigned int bottomOffset, unsigned int width, unsigned int hight, HWND hwnd);

//----------------------------------------


#endif	// _ELLIPSE_MOVE_H_
