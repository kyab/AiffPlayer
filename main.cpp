/*
 *  main.cpp
 *  AiffPlayer
 *
 *  Created by koji on 11/02/05.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include <iostream>
#include <iomanip>
#include <cstdlib>

#include "main.h"
#include "fft.h"



using namespace std;

int main(int argc, char *argv[])
{
	cout << "hello" << endl;
	int length = 8;
	if (argc > 1) length = atoi(argv[1]);
	if (((~length+1)&length) != length){
		cout << "Length must be a power of two!\n";
		exit(1);
	}
	
	complex<double> *input = new complex<double>[length];
	for (int i =0 ; (i < length)&&(!cin.eof()); i++){
		cin >> input[i];
		cout << input[i] << "\n";
	}
	
	complex<double> *output = new complex<double>[length];
	//for (int i = 0 ; i < length; i++) output[i] = input[i];
	fastForwardFFT(input, length, output);
	
	cout << "fast FFT\n";
	for (int i =0; i < length; i++){
		cout << setprecision(20) << output[i] << "\n";
	}
	
	cout << "slow FFT\n";
	slowForwardFFT(input, length , output);
	for (int i =0; i < length; i++){
		cout << setprecision(20) << output[i] << "\n";
	}	
	
	cout << "DFT\n";
	DFT(input, length , output);
	for (int i =0; i < length; i++){
		cout << setprecision(20) << output[i] << "\n";
	}	
    
}

