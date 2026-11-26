/*
Модуль для работы с точками эллипса.

Маткин Илья Александрович	27.11.2023
*/


#include "ellipse_math.h"

#include <math.h>

//----------------------------------------


#define PI	3.14

#define ELLIPSE_POINT_ENUMERATE_STEP	0.01


//----------------------------------------


void EnumerateAllEllipsePoints (unsigned int a, unsigned int b, EnumeratePointsCallback fun, void *ctx) {

EllipseCoordinateType t;

	for (t = 0; t < 2 * PI; t += ELLIPSE_POINT_ENUMERATE_STEP) {
		EllipseCoordinateType x = a * cos (t);
		EllipseCoordinateType y = b * sin (t);
		fun (ctx, x, y);
		}
}



EllipsePointGeneratorValue GetNextEllipsePoints (
	unsigned int a,
	unsigned int b,
	EllipseCoordinateType *x,
	EllipseCoordinateType *y,
	EllipsePointGeneratorValue prevValue) {

	EllipseCoordinateType t = prevValue + ELLIPSE_POINT_ENUMERATE_STEP;
	*x = a * cos (t);
	*y = b * sin (t);

	if (t > 2 * PI) {
		return EllipsePointStartValue;
		}

	return t;
}