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
//結果であるnormは、正規化されていない　http://sky.geocities.jp/freakish_osprey/opengl/opengl_normalvecotr.htm
void norm_from_triangle(const float *v0, const float *v1, const float *v2, float *norm){
	float one[] = {v1[0] - v0[0],  v1[1] - v0[1],  v1[2] - v0[2]};
	float two[] = {v2[0] - v0[0],  v2[1] - v0[1],  v2[2] - v0[2]};
	cross(one,two,norm);
}

SimpleVertex3 norm_from_triangle(const SimpleVertex3 &v0, const SimpleVertex3 &v1, const SimpleVertex3 &v2){
    SimpleVertex3 one = v1 - v0;
    SimpleVertex3 two = v2 - v0;
    
    return one.cross(two);
}

SimpleVertex3 mean_norm_from_triangles(/*const */SimpleVertex3 triangles[][3], int triangleNum){
    
    SimpleVertex3 norms[triangleNum];
    //i want map() i want functional!!
    for(int i = 0 ; i < triangleNum; i++){
        norms[i] = norm_from_triangle( triangles[i][0], triangles[i][1], triangles[i][2]);
    }
    
    SimpleVertex3 mean_norm(0.0,0.0,0.0);
    for (int i = 0; i < triangleNum; i++){
        mean_norm.x += norms[i].x;
        mean_norm.y += norms[i].y;
        mean_norm.z += norms[i].z;
    }
    mean_norm.x /= triangleNum;
    mean_norm.y /= triangleNum;
    mean_norm.z /= triangleNum;
    return mean_norm;
    
}
