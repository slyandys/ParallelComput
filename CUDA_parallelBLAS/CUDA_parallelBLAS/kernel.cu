
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <stdlib.h>
#define N 4;

//cudaError_t addWithCuda(int *c, const int *a, const int *b, unsigned int size);

//__global__ void addKernel(int *c, const int *a, const int *b)
//{
//    int i = threadIdx.x;
//    c[i] = a[i] + b[i];
//}

__global__ void addKernel(double *a, double *b, double *c,int size)
{
    int i = threadIdx.x;
	for(int k = 0;k<size; k++)
	{
		if(i < size)
			c[i] += a[i*size+k] * b[k];
	}
}

void simple_dgemv(double *A, double *B, double *C,int size)
{
	int i,j;

	for(i = 0;i < size; i++)
	{
		double prod = 0;

		for(j = 0;j < size; j++)
		{	
			prod += A[i * size + j] * B[j];
		}
		C[i] = prod;
	}
}

//__global__ void MVKernel_gm(double *A, double *X, double *Y,int ARRAY_SIZE)
//{
//	//int bx = blockIdx.x; 
//          //int by = blockIdx.y;
//	int tid = threadIdx.x; 
//          //int ty = threadIdx.y;
//	// Calculate the row index of the Pd element and M
//	//int Row = bx * BLOCK_SIZE + tx;
//	// Calculate the column idenx of Pd and N
//	//int Col = bx * BLOCK_SIZE + tx;
//  
//	double tmpSum = 0;
//
//	for (int k = 0; k < ARRAY_SIZE; k++) 
//    {
//      if(tid < ARRAY_SIZE)
//      tmpSum += A[tid*ARRAY_SIZE+k] * X[k];
//    }
//
//	__syncthreads();
//  
//	if(tid < ARRAY_SIZE)  		
//		Y[tid] = tmpSum;
//
//	__syncthreads();
//}

int main()
{
    const int arraySize = 5;
    const int a[arraySize] = { 1, 2, 3, 4, 5 };
    const int b[arraySize] = { 10, 20, 30, 40, 50 };
    int c[arraySize] = { 0 };

	int ARRAY_SIZE = 5;
	int ARRAY_SIZE2 = ARRAY_SIZE*ARRAY_SIZE;

	//Host
	double *h_a;
	double *h_b;
	double *h_c;

	//Device
	double *d_a;
	double *d_b;
	double *d_c;

	//generate the input array on the host
	h_a=(double*)malloc(sizeof(double)*ARRAY_SIZE2);
    h_b=(double*)malloc(sizeof(double)*ARRAY_SIZE);
    h_c=(double*)malloc(sizeof(double)*ARRAY_SIZE);

	//inital the h_a, h_b
	for(int i = 0;i<ARRAY_SIZE2;i++){
		h_a[i] = double(i);
	}
	for(int i = 0;i<ARRAY_SIZE;i++){
		h_b[i] = double(i);
	}
	for(int i = 0;i<ARRAY_SIZE;i++){
		h_c[i] = double(0);
	}


	////print out test
	//printf("\nThe vector A is:\n");
	//for(int i=0;i<ARRAY_SIZE2;i++){
	//	printf("%f", h_a[i]);
	//	printf(((i%4)!=3)? "\t" : "\n");
	//}

	//printf("\nThe Matrix X is:\n");
	//for(int i=0;i<ARRAY_SIZE;i++){
	//	printf("%f", h_b[i]);
	//	printf(((i%4)!=3)? "\t" : "\n");
	//}


    //// Add vectors in parallel.
    //cudaError_t cudaStatus = addWithCuda(c, a, b, arraySize);
    //if (cudaStatus != cudaSuccess) {
    //    fprintf(stderr, "addWithCuda failed!");
    //    return 1;
    //}

    //printf("{1,2,3,4,5} + {10,20,30,40,50} = {%d,%d,%d,%d,%d}\n",
    //    c[0], c[1], c[2], c[3], c[4]);

    //// cudaDeviceReset must be called before exiting in order for profiling and
    //// tracing tools such as Nsight and Visual Profiler to show complete traces.
    //cudaStatus = cudaDeviceReset();
    //if (cudaStatus != cudaSuccess) {
    //    fprintf(stderr, "cudaDeviceReset failed!");
    //    return 1;
    //}

	//allocate GPU memory
	cudaMalloc((void**)&d_a, sizeof(double)*ARRAY_SIZE2);
    cudaMalloc((void**)&d_b, sizeof(double)*ARRAY_SIZE);
    cudaMalloc((void**)&d_c, sizeof(double)*ARRAY_SIZE);

	//transfer the array from Host to device(CPU->GPU)
	cudaMemcpy(d_a, h_a, sizeof(double)*ARRAY_SIZE2, cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, h_b, sizeof(double)*ARRAY_SIZE, cudaMemcpyHostToDevice);
	cudaMemcpy(d_c, h_c, sizeof(double)*ARRAY_SIZE, cudaMemcpyHostToDevice);

	//Run kernel function calculate the matrix-vector multiplication
	printf("\n\nRunning Kernel...\n\n");
    //MVKernel_gm<<<1,256>>>(d_a, d_b, d_c, ARRAY_SIZE);//ARRAY_SIZE/256+1, 256
	addKernel<<<1, ARRAY_SIZE>>>(d_a,d_b,d_c,ARRAY_SIZE);

	//transfer the array from Device to Host(GPU->CPU)
	//cudaMemcpy(h_out, d_out, ARRAY_BYTES, cudaMemcpyDeviceToHost);
	cudaMemcpy(h_c, d_c, sizeof(double)*ARRAY_SIZE, cudaMemcpyDeviceToHost);

	//print out the result array
	for(int i = 0; i<ARRAY_SIZE;i++){
		printf("%f\n", h_c[i]);
		//printf(((i%4)!=3)? "\t" : "\n");
	}

	//free GPU memory allocation
	cudaFree(d_a);
    cudaFree(d_b);
    cudaFree(d_c);

	//free Host memory allocation
	free(h_a);
	free(h_b);
	free(h_c);

	system("pause");

    return 0;
}

// Helper function for using CUDA to add vectors in parallel.
//cudaError_t addWithCuda(int *c, const int *a, const int *b, unsigned int size)
//{
//    int *dev_a = 0;
//    int *dev_b = 0;
//    int *dev_c = 0;
//    cudaError_t cudaStatus;
//
//    // Choose which GPU to run on, change this on a multi-GPU system.
//    cudaStatus = cudaSetDevice(0);
//    if (cudaStatus != cudaSuccess) {
//        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
//        goto Error;
//    }
//
//    // Allocate GPU buffers for three vectors (two input, one output)    .
//    cudaStatus = cudaMalloc((void**)&dev_c, size * sizeof(int));
//    if (cudaStatus != cudaSuccess) {
//        fprintf(stderr, "cudaMalloc failed!");
//        goto Error;
//    }
//
//    cudaStatus = cudaMalloc((void**)&dev_a, size * sizeof(int));
//    if (cudaStatus != cudaSuccess) {
//        fprintf(stderr, "cudaMalloc failed!");
//        goto Error;
//    }
//
//    cudaStatus = cudaMalloc((void**)&dev_b, size * sizeof(int));
//    if (cudaStatus != cudaSuccess) {
//        fprintf(stderr, "cudaMalloc failed!");
//        goto Error;
//    }
//
//    // Copy input vectors from host memory to GPU buffers.
//    cudaStatus = cudaMemcpy(dev_a, a, size * sizeof(int), cudaMemcpyHostToDevice);
//    if (cudaStatus != cudaSuccess) {
//        fprintf(stderr, "cudaMemcpy failed!");
//        goto Error;
//    }
//
//    cudaStatus = cudaMemcpy(dev_b, b, size * sizeof(int), cudaMemcpyHostToDevice);
//    if (cudaStatus != cudaSuccess) {
//        fprintf(stderr, "cudaMemcpy failed!");
//        goto Error;
//    }
//
//    // Launch a kernel on the GPU with one thread for each element.
//    //addKernel<<<1, size>>>(dev_c, dev_a, dev_b);
//
//    // Check for any errors launching the kernel
//    cudaStatus = cudaGetLastError();
//    if (cudaStatus != cudaSuccess) {
//        fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
//        goto Error;
//    }
//    
//    // cudaDeviceSynchronize waits for the kernel to finish, and returns
//    // any errors encountered during the launch.
//    cudaStatus = cudaDeviceSynchronize();
//    if (cudaStatus != cudaSuccess) {
//        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
//        goto Error;
//    }
//
//    // Copy output vector from GPU buffer to host memory.
//    cudaStatus = cudaMemcpy(c, dev_c, size * sizeof(int), cudaMemcpyDeviceToHost);
//    if (cudaStatus != cudaSuccess) {
//        fprintf(stderr, "cudaMemcpy failed!");
//        goto Error;
//    }
//
//Error:
//    cudaFree(dev_c);
//    cudaFree(dev_a);
//    cudaFree(dev_b);
//
//
//    
//    return cudaStatus;
//}
