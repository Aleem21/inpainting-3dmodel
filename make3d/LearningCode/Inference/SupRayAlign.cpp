/*
% *  This code was used in the following articles:
% *  [1] Learning 3-D Scene Structure from a Single Still Image, 
% *      Ashutosh Saxena, Min Sun, Andrew Y. Ng, 
% *      In ICCV workshop on 3D Representation for Recognition (3dRR-07), 2007.
% *      (best paper)
% *  [2] 3-D Reconstruction from Sparse Views using Monocular Vision, 
% *      Ashutosh Saxena, Min Sun, Andrew Y. Ng, 
% *      In ICCV workshop on Virtual Representations and Modeling 
% *      of Large-scale environments (VRML), 2007. 
% *  [3] 3-D Depth Reconstruction from a Single Still Image, 
% *      Ashutosh Saxena, Sung H. Chung, Andrew Y. Ng. 
% *      International Journal of Computer Vision (IJCV), Aug 2007. 
% *  [6] Learning Depth from Single Monocular Images, 
% *      Ashutosh Saxena, Sung H. Chung, Andrew Y. Ng. 
% *      In Neural Information Processing Systems (NIPS) 18, 2005.
% *
% *  These articles are available at:
% *  http://make3d.stanford.edu/publications
% * 
% *  We request that you cite the papers [1], [3] and [6] in any of
% *  your reports that uses this code. 
% *  Further, if you use the code in image3dstiching/ (multiple image version),
% *  then please cite [2].
% *  
% *  If you use the code in third_party/, then PLEASE CITE and follow the
% *  LICENSE OF THE CORRESPONDING THIRD PARTY CODE.
% *
% *  Finally, this code is for non-commercial use only.  For further 
% *  information and to obtain a copy of the license, see 
% *
% *  http://make3d.stanford.edu/publications/code
% *
% *  Also, the software distributed under the License is distributed on an 
% * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either 
% *  express or implied.   See the License for the specific language governing 
% *  permissions and limitations under the License.
% *
% */

//#include <stdio.h>
#include <cstdlib>
#include <math.h>
#include "mex.h"

/* Input Arguments Total 4 input argument*/
#define SUP_IN      prhs[0]
#define VBOUNDARY_IN      prhs[1]
#define HBOUNDARY_IN      prhs[2]
#define STRAIGHLINE_IN             prhs[3]
#define TEXCOORX_IN             prhs[4]
#define TEXCOORY_IN             prhs[5]
#define SUPCOUNT_IN             prhs[6]

/* OutPUT Arguments */
#define TEXCOOR_OUT        plhs[0]

/* Definition */
#if !defined(MAX)
#define MAX(A, B)       ((A) > (B) ? (A) : (B))
#endif
#if !defined(MIN)
#define MIN(A, B)       ((A) > (B) ? (B) : (A))
#endif


static void SupRayAlign( double Sup[],
                double VBoundary[],
                double HBoundary[],
                double SupCountIn[],
                double StraightLine[],
                double TexCoorXOri[],
                double TexCoorYOri[], 
                double TexCoorOut[],
                unsigned int VSup,
                unsigned int HSup,
                unsigned int VB,
                unsigned int HB,
                unsigned int NuStr)
{

 int MaxSup = (VSup*HSup); 
 int *SupMovedBook = new int[MaxSup];
 for (int j = 0; j<HSup; j++){
     int Shift = j*VSup;
     for ( int i=0; i<VSup; i++){
         SupMovedBook[i+Shift] = 0; // all value set to zero
     }
 }

 /* copy TexCoorOri to TexCoorOut*/
 for ( int j = 0; j<HSup; j++){
     int Shift = j*VSup;
     for ( int i=0; i<VSup; i++){
         TexCoorOut[i+Shift] = TexCoorXOri[i+Shift]; // all value set to zero
//         printf("%f\n",TexCoorOut[i+Shift]);
         TexCoorOut[i+Shift+MaxSup] = TexCoorYOri[i+Shift]; // all value set to zero
     }
 } //Checked Coreect copy

  /* for each straight line stitch two rays*/
  for ( int i= 0; i < NuStr; i++){

     int HStart, HEnd;
     double Slope;
     double X1 = StraightLine[i];
     double Y1 = StraightLine[i+NuStr];
     double X2 = StraightLine[i+NuStr*2];
     double Y2 = StraightLine[i+NuStr*3];
     Slope = ( Y1 - Y2)/( X1 -X2);
//     printf(" %f %f\n", X1, X2);
     if ( X1 > X2){
        HStart = (int) ceil( X2);
        HEnd = (int) floor( X1);
     }
     else{ 
        HEnd = (int) floor( X2);
        HStart = (int) ceil( X1);
     }
     if (HStart > HEnd){ // exlude case when line didn't pass index
        continue;
     }
     if (HStart <1 | HStart > HSup |
         HEnd <1 | HEnd > HSup){
        printf("HEnd %d HStart %d",HEnd,HStart);
        printf("X1 %f X2 %f\n",X1,X2);
     }
 //    printf("%d %d \n", HEnd, HStart); 
 
     /* bilding up Vertical Stitch */
     for ( int k = HStart; k<=HEnd; k++){
         int kMinusOne = k -1;
         if (HStart == HEnd){
             break; // invalid vertical stitch for vertical line
         }
         double TarStitch = Slope*(k -X1) + Y1;
         int DownStitch = MIN( (int) ceil( TarStitch), VSup) -1;
         int UpStitch = MAX(DownStitch - 1,1) -1;
         if (TarStitch > VSup+0.5 | TarStitch <= 0.5){
            printf(" VTarStitch = %f k %d X1 %f Y1 %f X2 %f Y2 %f\n", TarStitch,k,X1,Y1,X2,Y2);
         }
   
         if (SupMovedBook[DownStitch + VSup*kMinusOne  ] !=1 ){ 
            TexCoorOut[ DownStitch + VSup*kMinusOne + MaxSup ] = TarStitch;         
            SupMovedBook[DownStitch + VSup*kMinusOne ] = 1;         
//            printf(" TexCoorYOri %f\n", TexCoorYOri[ DownStitch + VSup*k ]);
         }
         if (SupMovedBook[UpStitch + VSup*kMinusOne ] !=1 ){ 
            TexCoorOut[ UpStitch + VSup*kMinusOne + MaxSup ] = TarStitch;         
            SupMovedBook[UpStitch + VSup*kMinusOne ] = 1;         
//            printf(" TexCoorYOri %f\n", TexCoorYOri[ DownStitch + VSup*k ]);
         }
     }


     int VStart, VEnd;
     if ( Y1 > Y2){
        VStart = (int) ceil( Y2);
        VEnd = (int) floor( Y1);
     }
     else{ 
        VEnd = (int) floor( Y2);
        VStart = (int) ceil( Y1);
     }
     if (VStart > VEnd){
        continue;
     }
     if (VStart <1 | VStart > VSup |
         VEnd <1 | VEnd > VSup){
        printf("VEnd %d VStart %d",VEnd,VStart);
        printf("Y1 %f Y2 %f\n",Y1,Y2);
     }
//     printf("%d %d \n", VEnd, VStart);
     /* bilding up Horizontal Stitch */
   for ( int k = VStart; k<=VEnd; k++){
         if (VStart == VEnd){
             break; // invalid vertical stitch for vertical line
         }
         double TarStitch = 1/Slope*( k - Y1) + X1;
         int LeftStitch = MAX( (int) floor( TarStitch),1) - 1;
         int RightStitch = MIN( LeftStitch + 1, HSup) - 1;
         if (TarStitch > HSup+0.5 | TarStitch <= 0.5){
            printf(" HTarStitch = %f k %d X1 %f Y1 %f X2 %f Y2 %f\n", TarStitch,k,X1,Y1,X2,Y2);
         }
   
         if (SupMovedBook[LeftStitch*VSup + k-1] !=1 ){ 
            TexCoorOut[ LeftStitch*VSup + k-1] = TarStitch;         
            SupMovedBook[LeftStitch*VSup + k-1] = 1;         
         }
         if (SupMovedBook[RightStitch*VSup + k-1] !=1 ){ 
             TexCoorOut[ RightStitch*VSup + k-1 ] = TarStitch;         
             SupMovedBook[RightStitch*VSup + k-1] = 1;         
         }
     }

  }


  /*  Superpixel Vertical boundary stitching */
 for (int k = 0; k < HSup; k++){
     int Shift = VSup*k;
     int ShiftVB = VB*k;
     for ( int i = 0; i < (VSup - 1); i++){
         if ( Sup[ i + Shift] != Sup[ i + 1 + Shift ] &&
              ( SupMovedBook[i + Shift ] !=1 ||
                SupMovedBook[i + Shift + 1 ] !=1)
              ){
            int UpVB = (int) ceil( (i +0.5)*((double)VB/(double)VSup)-0.5 );
            int DownVB = (int) floor( (i +1.5)*((double)VB/(double)VSup)-0.5);
//            printf("UpVB %d DownVB %d",UpVB,DownVB);
//            if ( SupCountIn[i + Shift] > SupCountIn[i + Shift + 1]){
               for ( int j = UpVB; j<= DownVB; j++){
//                  printf("j %d",j);
                     if ( VBoundary[j + ShiftVB] != VBoundary[ j + ShiftVB + 1]){
                          double TarStitch = (j + 0.5)*((double)VSup/(double)VB) - 0.5 +1;
//                          printf("%d %f",j,TarStitch);
                          if (SupMovedBook[i + Shift ] !=1){
                             TexCoorOut[ i + Shift + MaxSup ] = TarStitch;
                             SupMovedBook[i + Shift ] = 1;
                          }
                         /* if (SupMovedBook[i + Shift + 1] !=1){
                              TexCoorOut[ i + Shift + 1 + MaxSup ] = TarStitch;
                              SupMovedBook[i + Shift +1 ] = 1; 
                          }*/
                     }
               }
  //          }
 //           else{
            if ( SupCountIn[i + Shift] > SupCountIn[i + Shift + 2]){
               for ( int j = DownVB; j>= UpVB; j--){
//                  printf("j %d",j);
                     if ( VBoundary[j + ShiftVB] != VBoundary[ j + ShiftVB + 1]){
//                          printf("j %d",j);
                          double TarStitch = (j + 0.5)*((double)VSup/(double)VB) - 0.5 + 1;
//                          printf("%d %f",j,TarStitch);
                       /*   if (SupMovedBook[i + Shift ] !=1){
                              TexCoorOut[ i + Shift + MaxSup ] = TarStitch;
                              SupMovedBook[i + Shift ] = 1;
                          }*/
                          if (SupMovedBook[i + Shift + 1 ] !=1){
                              TexCoorOut[ i + Shift + 1 + MaxSup ] = TarStitch;
                              SupMovedBook[i + Shift +1 ] = 1;
                          }
                     }
               }
            }

         }

     }
 }
 
 
  /*  Superpixel Horizontal boundary stitching */
 for (int k = 0; k < (HSup-2); k++){
     int Shift = VSup*k;
     int ShiftHB = VSup*k;
     for ( int i = 0; i < (VSup - 1); i++){
         if ( Sup[ i + Shift] != Sup[ i + VSup + Shift ] &&
              ( SupMovedBook[i + Shift ] !=1 ||
                SupMovedBook[i + Shift + VSup ] !=1 )
              ){
            int LeftVB = (int) ceil( (k +0.5)*((double)HB/(double)HSup)-0.5 );
            int RightVB = (int) floor( (k +1.5)*((double)HB/(double)HSup)-0.5);
//            printf("LeftVB %d RightVB %d",LeftVB,RightVB);
//            if ( SupCountIn[i + Shift] > SupCountIn[i + Shift + VSup]){
               for ( int j = LeftVB; j<= RightVB; j++){
                     if ( HBoundary[j*VSup + i] != HBoundary[ j*VSup + i + VSup]){
                          double TarStitch = (j + 0.5)*( (double)HSup/(double)HB) - 0.5 +1;
    //                      printf("%d %f",j,TarStitch);
                          if (SupMovedBook[i + Shift ] !=1){
                              TexCoorOut[ i + Shift  ] = TarStitch + 1;
                              SupMovedBook[i + Shift ] = 1;
                          }
                     /*     if (SupMovedBook[i + Shift +VSup] !=1){
                              TexCoorOut[ i + Shift + VSup  ] = TarStitch + 1;
                              SupMovedBook[i + Shift + VSup ] = 1; 
                          }*/
                     }
               }
  //          }
//            else{
            if ( SupCountIn[i + Shift] > SupCountIn[i + Shift + VSup*2]){
               for ( int j = RightVB; j>= LeftVB; j--){
                     if ( HBoundary[j*VSup + i] != HBoundary[ j*VSup + i + VSup]){
                          double TarStitch = (j + 0.5)*((double)HSup/ (double)HB) - 0.5 +1;
  //                        printf("%d %f\n",j,TarStitch);
                         /* if (SupMovedBook[i + Shift ] !=1){
                              TexCoorOut[ i + Shift  ] = TarStitch + 1;
                              SupMovedBook[i + Shift ] = 1;
                          }*/
                          if (SupMovedBook[i + Shift +VSup] !=1){
                              TexCoorOut[ i + Shift + VSup  ] = TarStitch + 1;
                              SupMovedBook[i + Shift + VSup ] = 1; 
                          }
                     }
               }
            }

         }

     }
 }
// printf("HB %d HSup %d",HB,HSup);
 delete [] SupMovedBook;
 return;
}

/* mexFunctin (matlab interface will be removed later) */
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
    double   *Sup;
    double   *VBoundary;
    double   *HBoundary;
    double   *StraightLine;
    double   *TexCoorXOri;
    double   *TexCoorYOri;
    double   *TexCoorOut;
    double   *SupCountIn;

    unsigned int VSup, HSup, VB, HB, NuStr, v, h;

    /* Check for proper number of arguments */

    if (nrhs != 7) {
        mexErrMsgTxt("Seven input arguments required.");
    } else if (nlhs > 1) {
        mexErrMsgTxt("Too many output arguments.");
    }

    /* Check the dimensions of the inputs. */

    VSup = mxGetM(SUP_IN);
    HSup = mxGetN(SUP_IN);
    if (!mxIsDouble(SUP_IN) || mxIsComplex(SUP_IN) ) {
        mexErrMsgTxt("The Data Type of Sup shouldn't be complex.");
    }
    VB = mxGetM(VBOUNDARY_IN);
    h = mxGetN(VBOUNDARY_IN);
    if (!mxIsDouble(VBOUNDARY_IN) || mxIsComplex(VBOUNDARY_IN) ||
        (h != HSup ) ) {
        mexErrMsgTxt("The Data Type of VBoundary shouldn't be complex.");
    }
    v = mxGetM(HBOUNDARY_IN);
    HB = mxGetN(HBOUNDARY_IN);
    if (!mxIsDouble(HBOUNDARY_IN) || mxIsComplex(HBOUNDARY_IN) ||
        (v != VSup)) {
        mexErrMsgTxt("The Data Type of HBoundary shouldn't be complex.");
    }
    NuStr = mxGetM(STRAIGHLINE_IN);
    h = mxGetN(STRAIGHLINE_IN);
    if (!mxIsDouble(STRAIGHLINE_IN) || mxIsComplex(STRAIGHLINE_IN) ||
        (h != 4) ) {
        mexErrMsgTxt("StraighLine matrix should always has 4 columns.");
    }
    v = mxGetM( TEXCOORX_IN);
    h = mxGetN( TEXCOORX_IN);
    if (!mxIsDouble( TEXCOORX_IN) || mxIsComplex( TEXCOORX_IN) ||
        (v != VSup) || (h != HSup)) {
        mexErrMsgTxt("TextCoorX matrix should is wrong.");
    }
    v = mxGetM( TEXCOORY_IN);
    h = mxGetN( TEXCOORY_IN);
    if (!mxIsDouble( TEXCOORY_IN) || mxIsComplex( TEXCOORY_IN) ||
        (v != VSup) || (h != HSup) ) {
        mexErrMsgTxt("TextCoorY matrix should is wrong.");
    }
    v = mxGetM( SUPCOUNT_IN);
    h = mxGetN( SUPCOUNT_IN);
    if (!mxIsDouble( SUPCOUNT_IN) || mxIsComplex( SUPCOUNT_IN) ||
        (v != VSup) || (h != HSup) ) {
        mexErrMsgTxt("SUPCOUNT_IN matrix should is wrong.");
    }

    /* Create a matrix for the return argument */
    int DIM[3];
    DIM[0] = VSup;
    DIM[1] = HSup;
    DIM[2] = 2;
    TEXCOOR_OUT = mxCreateNumericArray( 3, DIM, mxDOUBLE_CLASS, mxREAL);
    TexCoorOut = mxGetPr(TEXCOOR_OUT);

    /* Assign pointers to the various parameters */
    Sup = mxGetPr( SUP_IN);
    VBoundary = mxGetPr( VBOUNDARY_IN);
    HBoundary = mxGetPr( HBOUNDARY_IN);
    StraightLine =  mxGetPr( STRAIGHLINE_IN);
    TexCoorXOri =  mxGetPr( TEXCOORX_IN);
    TexCoorYOri =  mxGetPr( TEXCOORY_IN);
    SupCountIn =  mxGetPr( SUPCOUNT_IN);

    /* Do the actual computations in a subroutine */
    SupRayAlign( Sup, VBoundary, HBoundary, SupCountIn, StraightLine, TexCoorXOri, TexCoorYOri, TexCoorOut, VSup, HSup, VB, HB, NuStr);
    return;

}



