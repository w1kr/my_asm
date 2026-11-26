/*

*/

#ifndef	_ELLIPSE_MATH_H_
#define _ELLIPSE_MATH_H_


typedef double EllipseCoordinateType;

typedef void (*EnumeratePointsCallback) (void*, EllipseCoordinateType, EllipseCoordinateType);

void EnumerateAllEllipsePoints (unsigned int a, unsigned int b, EnumeratePointsCallback fun, void *ctx);



typedef double EllipsePointGeneratorValue;

#define EllipsePointStartValue	0

EllipsePointGeneratorValue GetNextEllipsePoints (
	unsigned int a,
	unsigned int b,
	EllipseCoordinateType *x,
	EllipseCoordinateType *y,
	EllipsePointGeneratorValue prevValue);



#endif	// _ELLIPSE_MATH_H_

