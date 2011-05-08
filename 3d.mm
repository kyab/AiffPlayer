/*
 *  3d.cpp
 *  Oscilloscope
 *
 *  Created by koji on 11/02/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#import "3d.h"

float rad(float degree){
	return 2 * M_PI/360 * degree;
}

void cross(const float *va, const float *vb, float *result_vector){
	int x = 0;
	int y = 1;
	int z = 2;
	result_vector[x] = va[y]*vb[z] - va[z]*vb[y];
	result_vector[y] = va[z]*vb[x] - va[x]*vb[z];
	result_vector[z] = va[x]*vb[y] - va[y]*vb[x];
}

//3角形の頂点(OpenGLの左回り)から、法線ベクトルを求める。
//結果であるnormは、正規化されていない
void norm_from_triangle(const float *v0, const float *v1, const float *v2, float *norm){
	float one[] = {v1[0] - v0[0],  v1[1] - v0[1],  v1[2] - v0[2]};
	float two[] = {v2[0] - v0[0],  v2[1] - v0[1],  v2[2] - v0[2]};
	cross(one,two,norm);
}
