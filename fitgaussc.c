#include "mex.h"
#include "lapack.h"
#include "matrix.h"
#include "math.h"
#include "stdlib.h"


/* this function uses the lapack package to implement the matlab mldivide ('\') function
 * for least square fitting problems
 */


/* cpu version of the fitgauss function
 * note that the x, y, sigx, sigy, a, and b parameters have initial values stored in them.
 * upon return these variables will be filled with the new, fitted parameters
 *
 * order of the paras array:
 * b, a, y0, x0, sigy, sigx, bk_rms, goodness
 *
 * note: jg and dif are jacobian matrices allocated in the Mex function and pointers are 
 *       passed on so no need to allocate the memory for each call.
 *       the sizes of jg and dif are pre-determined; the only variable is how many elements
 *       would jg and dif will actually have, which depends on how many elements in the img
 *       matrix are non-zero.
 */

/* Auxiliary routine: printing a matrix */
void print_matrix( char* desc, int m, int n, double* a, int lda) 
{
        int i, j;
        printf( "\n %s\n", desc );
        for( i = 0; i < m; i++ ) {
                for( j = 0; j < n; j++ ) printf( " %10.4f", a[i+j*lda] );
                printf( "\n" );
        }
}

/* Auxiliary routine: finding min (non-zero) and max of an image */
void find_minmax(double *a, int m, int n, double *minmax)
{
    double min = 65535, max = 1, ave_x = 0, ave_y = 0, sum = 0;
    int min_idx = 1, min_idy = 1, max_idx = 1, max_idy = 1;
    int nonzeros = 0;
    int i, j;
    
    for(i=0; i<m; i++)
    {
        for(j=0; j<n; j++)
        {
            if(a[i+j*m] == 0)
                continue;
            
            nonzeros ++;
            sum = sum + a[i+j*m];
            /*ave_x = ave_x + a[i+j*m]*(j+1);
            ave_y = ave_y + a[i+j*m]*(i+1);*/
            
            if(a[i+j*m]>max) {
                max = a[i+j*m];
                max_idx = j;
                max_idy = i;
                
                /*mexPrintf("max value at [%d, %d]", max_idx, max_idy);*/
            }
            else if(a[i+j*m]<min) {
                min = a[i+j*m];
                min_idx = j;
                min_idy = i;
            }
        }
    }
    
    minmax[0] = min;
    minmax[1] = max;
    minmax[2] = min_idy;
    minmax[3] = min_idx;
    minmax[4] = max_idy;
    minmax[5] = max_idx;
    minmax[6] = nonzeros;
    /*minmax[7] = ave_x / (sum + 0.01);       intensity weighted x
    minmax[8] = ave_y / (sum + 0.01);       intensity weighted y */
    minmax[7] = sum;
    
    return;
}
            
/* lapack version of the mldivide (which is the same as what Matlab uses */
void lapack_mldivide(mwSize MA, mwSize NA, double *A, mwSize MB, mwSize NB, double *B, mwSize MX, mwSize NX, double *X)
{
    ptrdiff_t m, n, ldb, nrhs;
    ptrdiff_t info, lwork;
    double *work, workopt;
    double *temp;
    int i=0;
    
    m = MA;
    n = NA;
    ldb = MB;
    nrhs = NB;
    lwork = -1;
    temp = (double *) mxCalloc(ldb, sizeof(double));
    
    for(i=0; i<ldb; i++)
        temp[i] = B[i];
    
    /*emcpy(temp, B, ldb*sizeof(double)); */
    
    dgels("N", &m, &n, &nrhs, A, &m, temp, &ldb, &workopt, &lwork, &info);
    if(info == 0)
            lwork = (int) workopt;
    else
    {
        for(i=0; i<MX; i++)
            X[i] = 0;
         
        mexPrintf("Info output is %d and the optimal lwork size is %d.\n", info, lwork);
    
        mxFree(temp);
        return;
    }
    
   
    work = (double *) mxCalloc(lwork, sizeof(double));
    dgels("N", &m, &n, &nrhs, A, &m, temp, &ldb, work, &lwork, &info);
    
    if (info == 0)
        for(i=0; i<MX; i++)
            X[i]=temp[i];
    else
        for(i=0; i<MX; i++)
            X[i] = 0;
    
    /*
    if(info == 0)  /* successful execution; temp(0:n-1) is the solution *
        memcpy(X, temp, MX*sizeof(float));
     */
    
    mxFree(work);   
    mxFree(temp);
 
    return;
}


int fitgaussc(double *img, mwSize sizex, mwSize sizey, int nonzeros, double *paras, double err, int max_iter)
{
    mwSize length;
    double b, a, x0, y0, sigx, sigy, goodness, bk_rms;
    double *dlambda;
    double ex = 1, ey = 1, ea = 1;
    double pexp;
    double sum_dif, std_dif, sum_dif_sq, sum_img;
    int iter = 0, i, j, pos = 0;
    double *jg, *dif;
    
    jg  = (double *) mxCalloc(nonzeros*6, sizeof(double));
    dif = (double *) mxCalloc(nonzeros, sizeof(double));
    dlambda = (double *) mxCalloc(6, sizeof(double));
 
    length = nonzeros;
    
    /* assign the initial values */
    b    = paras[0];
    a    = paras[1];
    y0   = paras[2];
    x0   = paras[3];
    sigy = paras[4];
    sigx = paras[5];
    
    /* check the initial values 
    mexPrintf("The intital values are: %.2f, %.2f, %.2f, %.2f, %.2f, %.2f.\n", b, a, y0, x0, sigy, sigx);*/
    
    
    while (((ex > err) || (ey > err) || (ea > err)) && (iter < max_iter) && (pos<=nonzeros))    
    {
        pos = 0;
        sum_img = 0;
 
        for(j=1; j<=sizex; j++) {
            for(i=1; i<=sizey; i++) {
         
                /* ignore the points set as 0 - those were non-qualified data points 
                 * note that img(i, j) in matlab is equiv to img[(i-1)*n+j-1] in C 
                 */
                
                if (img[(j-1)*sizey + (i-1)] == 0) {
                    /*mexPrintf("Encountered a blank pixel.\n");*/
                    continue;
                }
                
                pos ++;
                sum_img += img[(j-1)*sizey + (i-1)];
                
                pexp = a * exp(- pow((i-y0), 2.0)/(2.0*pow(sigy, 2.0)) - pow((j-x0), 2.0)/(2*pow(sigx, 2.0)));
                
                /*if(i==1) 
                    mexPrintf("pexp is %f\n", pexp);
                */
                /* compared with the matlab code, this section needs to be rewritten to comply to the
                 * way that C stores the matrices.
                 */
     
                jg[(pos-1)]             = 1;
                jg[(pos-1) + length] = pexp / a;
                jg[(pos-1) + length*2]  = (j-x0) * pexp / pow(sigx, 2.0);
                jg[(pos-1) + length*3]  = (i-y0) * pexp / pow(sigy, 2.0);
                jg[(pos-1) + length*4]  = pow((j-x0), 2.0) * pexp / pow(sigx, 3.0);
                jg[(pos-1) + length*5]  = pow((i-y0), 2.0) * pexp / pow(sigy, 3.0);
                dif[pos-1] = b + pexp - img[(j-1)*sizey + (i-1)];
            }
        }
        
        /*printf("%dth iteration", iter+1);*/
        /*mexPrintf("%d non-zero pixels are computed\n", pos);*/
        /*print_matrix("Matrix JG in iteration", 15, 6, jg, length);*/
        /*mexPrintf("The first four elements in JG is %10.4f, %10.4f, %10.4f, %10.4f", jg[0], jg[1], jg[2], jg[3]); */
        /*print_matrix("Matrix DIF in iteration", pos, 1, dif, pos);*/
        
        /* jg has m = pos rows and 6 columns; dif has m rows and 1 column
         * now calculate the parameter adjustment matrix
         
        memset(dlambda, 0, 6*sizeof(double));*/
        lapack_mldivide(pos, 6, jg, pos, 1, dif, 6, 1, dlambda);
        
        /*print_matrix("Matrix DLambda:", 6, 1, dlambda, 6);
        mexPrintf("The 6 elements of dlambda are: %.2f, %.2f, %.2f, %.2f, %.2f, %.2f\n", 
                dlambda[0], dlambda[1], dlambda[2]/y0, dlambda[3]/x0, dlambda[4], dlambda[5]);*/
        
        /* add additional criterion to make sure the fitting converges 
        if(fabs(dlambda[2]) > sizex/2.0)
            dlambda[2] = 1;
        
        if(fabs(dlambda[3]) > sizey/2.0)
            dlambda[3] = 1;*/
        
        
        b    = b - dlambda[0];
        a    = a - dlambda[1];
        x0   = x0 - dlambda[2];
        y0   = y0 - dlambda[3];
        sigx = sigx - dlambda[4];
        sigy = sigy - dlambda[5];
        
        ex = fabs(dlambda[2]/sizex);
        ey = fabs(dlambda[3]/sizey);
        ea = fabs(dlambda[1]/(sum_img+0.01));
        
        /*mexPrintf("The outputs are b = %.3f, a = %.3f, x = %.3f, y = %.3f\n", b, a, x0, y0);*/
        
        iter ++;
    }
    
   
    /* calculate the bk_rms and finess */
    sum_dif = 0;
    sum_dif_sq = 0;
    for(i = 0; i<pos; i++)    {
        sum_dif += dif[i];
        sum_dif_sq += pow(dif[i], 2.0);
    }
    
    std_dif = 0;
    for(i = 0; i<pos; i++)
        std_dif += pow((sum_dif/pos - dif[i]), 2.0);
    
    bk_rms = sqrt(std_dif/(pos-1));
    goodness = sqrt(sum_dif_sq)/(sum_img);
    
    /* mexPrintf("Fitting completed in %d iterations.\n", iter); */
    
    /* assign return array values */
    paras[0] = b;
    paras[1] = a;
    paras[2] = y0;
    paras[3] = x0;
    paras[4] = sigy;
    paras[5] = sigx;
    paras[6] = goodness;
    paras[7] = bk_rms;   
    paras[8] = iter;
    
    /* returns an indicator whether this fitting is successful */
    if(paras[2]<=0 || paras[3]<=0 || paras[2]>sizey || paras[3]>sizex || paras[4]<=0 || paras[5]<=0 || paras[6]>1 || paras[7]>sum_img)
        paras[9] = 0;
    else
        paras[9] = 1;
    
    mxFree(jg);
    mxFree(dif);
    mxFree(dlambda);
}


/* mex interface function */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *stack, *img, err, *paras, *output;
    double *minmax;
    mwSize sizex, sizey, num_frames;
    mwSize length;
    int max_iter, i, j, k;
    char msg[200];
    
    /*double *temp;*/
    
    if(nrhs != 4)
        mexErrMsgTxt("Four inputs (stack, num_frames, err, and max_iter) are required.");
    else if(nlhs > 1)
        mexErrMsgTxt("Too many output arguments.");
    
    if(!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]))
        mexErrMsgTxt("Input must be noncomplex double.");
    
    sizey = mxGetM(prhs[0]);
    sizex = mxGetN(prhs[0]);
    num_frames = mxGetScalar(prhs[1]);
    
    if (sizex != num_frames * (int) (sizex/num_frames))
        mexErrMsgTxt("Array size mismatch. Make sure the second parameter (Num Frames) is set correctly.");
    
    sizex = (mwSize) (sizex / num_frames);
    stack = (double *) mxGetPr(prhs[0]);
    
    err   = mxGetScalar(prhs[2]);
    max_iter = mxGetScalar(prhs[3]);
    length = sizey * sizex;
    
    if(mxGetNumberOfElements(prhs[0]) != length * num_frames)
        mexErrMsgTxt("Array size mismatch. Make sure the second parameter (Num Frames) is set correctly.");
   
    /*mexPrintf("Input image dimensions are: (y, x) = [%d, %d]; total %d of frames.\n", sizey, sizex, num_frames);*/
    
    /* output parameter matrix */
    plhs[0] = mxCreateDoubleMatrix(10, num_frames, mxREAL);
    output = mxGetPr(plhs[0]);
    
    paras = mxCalloc(10, sizeof(double));
    img = mxCalloc(length, sizeof(double));
    minmax = mxCalloc(8, sizeof(double));
    /*
         
    fedisableexcept(FE_DIVBYZERO | FE_INVALID | FE_OVERFLOW);
    */    
    
    for(k=0; k<num_frames; k++)
    {
        /* copy data to the img array */
        for(i=0; i<sizey; i++)
            for(j=0; j<sizex; j++)
                img[j*sizey+i] = stack[k*length+j*sizey+i];
        
        /*print_matrix("Original image:", sizey, sizex, img, sizey);*/
        
        /* assign initial values to fitting parameters */
        /* find the min, max of img 
        minmax[0] = min;
        minmax[1] = max;
        minmax[2] = min_idy;
        minmax[3] = min_idx;
        minmax[4] = max_idy;
        minmax[5] = max_idx;
        minmax[6] = nonzeros;    
        minmax[7] = sum;*/
    
        find_minmax(img, sizey, sizex, minmax);

        /* non-empty image matrix */
        if(minmax[6] != 0) 
        {
         
            /* initial round of fitting using the maximum pixel as the initial x0 and y0 */
            paras[0] = minmax[0];
            paras[1] = minmax[1] - minmax[0];
            paras[2] = minmax[4]+1;       /* initial y */
            paras[3] = minmax[5]+1;       /* initial x */
            paras[4] = 1.0;        
            paras[5] = 1.0;    
            /*
            mexPrintf("Sum, Min and Max values of image are %.1f, %.1f, %.1f, %d, %d, respectively.\n", sum, minmax[0], minmax[1], (int) minmax[4], (int) minmax[5]);
            */ 
            /* assign return array values 
            paras[0] = b;
            paras[1] = a;
            paras[2] = y0;
            paras[3] = x0;
            paras[4] = sigy;
            paras[5] = sigx;
            paras[6] = goodness;
            paras[7] = bk_rms;   
            paras[8] = iter;
            paras[9] = success 
             */
        
            /*print_matrix("Fitting result:", 9, 1, paras, 9);*/
        
            /* look through the fitting results es */
        
            fitgaussc(img, sizex, sizey, (int) minmax[6], paras, err, max_iter);
            
            if(paras[9] == 1) /* good fitting, assign output */
            {
                for(j=0; j<10; j++)
                    output[k*10+j] = paras[j];
            }        
           
            else
            {
            /* bad fitting. look for alternative initial values? */
                for(j=0; j<10; j++)
                    output[k*10+j] = 0;
            }
        }
        else    /* empty image. returns 0s */
        {
            for(j=0; j<10; j++)
                output[k*10+j] = 0;
        }
        
        /*mexPrintf("Last written bit is %d and total length of output is %d.\n", k*10+j, 10*num_frames);*/
        if(((k+1) % 2000) ==0 || k == 1 || k ==num_frames-1)
        {
            sprintf(msg, "global h_mainfig; showmsg(h_mainfig, 'message', 'Extracting centroids for %d particles (%.1f %% finished).'); pause(0.001);", num_frames, 100.0 * k/num_frames);
            mexEvalString(msg);
            /*mexPrintf("%s\n", msg);*/
        }
    } 

    
    
    /* free up dynamically allocated memory */
    mxFree(img);
    mxFree(minmax);
    mxFree(paras);

    
    return;
}
    
