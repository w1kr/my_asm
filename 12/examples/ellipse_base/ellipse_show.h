/*
*/


#ifndef	_ELLIPSE_SHOW_H_
#define _ELLIPSE_SHOW_H_

#include "ellipse_math.h"

#include <windows.h>


//----------------------------------------


void ShowEllipse (HDC hdc, unsigned int leftOffset, unsigned int bottomOffset, unsigned int width, unsigned int hight);

void ShowEllipseByPoint (HDC hdc, unsigned int leftOffset, unsigned int bottomOffset, unsigned int width, unsigned int hight);

//----------------------------------------


#endif	// _ELLIPSE_SHOW_H_
