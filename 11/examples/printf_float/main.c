#include <stdio.h>
#include <math.h>


void fun (int a, ...) {

}

typedef double FloatType;

int main () {

float f1  = 1.2;
double f2 = 3.4;
FloatType f3 = 0.3;
FloatType f4 = 0.4;
FloatType f5;
double f6;
FloatType f7;

    fun (1, f1);

    printf ("f1: %f\n", f1);
    printf ("f2: %f\n", f2);

	printf ("f3      = %.30f\n", f3);
	printf ("f4      = %.30f\n", f4);
	printf ("f3 + f4 = %.40f\n", f3 + f4);
	printf ("f3 + f4 = %.30f\n", f3 + f4);
	f5 = f3 + f4;
	printf ("f5      = %.40f\n", f5);
	f6 = f3 + f4;
	printf ("f6      = %.30f\n", f5);

	f7 = f3;
	f7 += f4;
	f7 -= f4;
	printf ("f7      = %.3f\n", f7);

	if (f7 == f3) {
	//if (abs (f7 - f3) < 0.0000001) {
		printf ("%f equal %f\n", f7, f3);
		}
	else {
		printf ("%f not equal %f\n", f7, f3);
		}
}
