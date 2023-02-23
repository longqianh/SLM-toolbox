//
//:  IMAGE_GEN for programming languages that can interface with DLLs - generate various image types
//
//   (c) Copyright Meadowlark Optics 2017, All Rights Reserved.


#ifndef IMAGE_GEN_H_
#define IMAGE_GEN_

#ifdef IMAGE_GEN_EXPORTS
#define IMAGE_GEN_API __declspec(dllexport)
#else
#define IMAGE_GEN_API __declspec(dllimport)
#endif


#ifdef __cplusplus
extern "C" { /* using a C++ compiler */
#endif
  
  IMAGE_GEN_API void Concatenate_TenBit(unsigned char* ArrayOne, unsigned char* ArrayTwo, int width, int height);

  IMAGE_GEN_API void Generate_Stripe(unsigned char* Array, unsigned char* WFC, int width,  int height, int depth, int PixelValOne, int PixelValTwo, int PixelsPerStripe, int RGB);

  IMAGE_GEN_API void Generate_Checkerboard(unsigned char* Array, unsigned char* WFC, int width, int height, int depth, int PixelValOne, int PixelValTwo, int PixelsPerCheck, int RGB);

  IMAGE_GEN_API void Generate_Solid(unsigned char* Array, unsigned char* WFC, int width, int height, int depth, int PixelVal, int RGB);

  IMAGE_GEN_API void Generate_Random(unsigned char* Array, unsigned char* WFC, int width, int height, int depth, int RGB);

  IMAGE_GEN_API void Generate_Zernike(unsigned char* Array, unsigned char* WFC, int width, int height, int depth, int centerX, int centerY, int radius, double Piston, double TiltX, double TiltY,
    double Power, double AstigX, double AstigY, double ComaX, double ComaY, double PrimarySpherical,
    double TrefoilX, double TrefoilY, double SecondaryAstigX, double SecondaryAstigY, double SecondaryComaX,
    double SecondaryComaY, double SecondarySpherical, double TetrafoilX, double TetrafoilY, double TertiarySpherical,
    double QuaternarySpherical, int RGB);

  IMAGE_GEN_API void Generate_FresnelLens(unsigned char* Array, unsigned char* WFC, int width, int height, int depth, int centerX, int centerY, int radius, double Power, int cylindrical,
    int horizontal, int RGB);

  IMAGE_GEN_API void Generate_Grating(unsigned char* Array, unsigned char* WFC, int width, int height, int depth, int Period, int increasing, int horizontal, int RGB);

  IMAGE_GEN_API void Generate_Sinusoid(unsigned char* Array, unsigned char* WFC, int width, int height, int depth, int Period, int horizontal, int RGB);

  IMAGE_GEN_API void Generate_LG(unsigned char* Array, unsigned char* WFC, int width, int height, int depth, int VortexCharge, int centerX, int centerY, int fork, int RGB);

  IMAGE_GEN_API void Generate_ConcentricRings(unsigned char* Array, unsigned char* WFC, int width, int height, int depth, int InnerDiameter, int OuterDiameter, int PixelValOne, int PixelValTwo, int centerX, int centerY, int RGB);
	
  IMAGE_GEN_API void Generate_Axicon(unsigned char* Array, unsigned char* WFC, int width, int height, int depth, int PhaseDelay, int centerX, int centerY, int increasing, int RGB);

  IMAGE_GEN_API void Mask_Image(unsigned char* Array, int width, int height, int depth, int Region, int NumRegions, int RGB);

  IMAGE_GEN_API int Initialize_HologramGenerator(int width, int height, int depth, int iterations, int RGB);

  IMAGE_GEN_API int CalculateAffinePolynomials(int SLM_X_0, int SLM_Y_0, int CAM_X_0, int CAM_Y_0,
                                               int SLM_X_1, int SLM_Y_1, int CAM_X_1, int CAM_Y_1,
                                               int SLM_X_2, int SLM_Y_2, int CAM_X_2, int CAM_Y_2);

  IMAGE_GEN_API int Generate_Hologram(unsigned char *Array, unsigned char* WFC, float *x_spots, float *y_spots, float *z_spots, float *I_spots, int N_spots, int ApplyAffine);

  IMAGE_GEN_API void Destruct_HologramGenerator();

  IMAGE_GEN_API int Initialize_GerchbergSaxton();

  IMAGE_GEN_API int GerchbergSaxton(unsigned char *Phase, unsigned char* InputImg, unsigned char* WFC, int width, int height, int depth, int Iterations, int RGB);

  IMAGE_GEN_API void Destruct_GerchbergSaxton();

  IMAGE_GEN_API int Initialize_RegionalLUT(int width, int height, int depth);

  IMAGE_GEN_API int Load_RegionalLUT(const char* const RegionalLUTPath, float* Max, float* Min);

  IMAGE_GEN_API int Apply_RegionalLUT(unsigned char *Array);

  IMAGE_GEN_API void Destruct_RegionalLUT();

  IMAGE_GEN_API int SetBESTConstants(int FocalLength, float BeamDiameter, float Wavelength, float SLMpitch, int SLMNumPixels, float ObjNA, float ObjMag, float ObjRefInd, float TubeLength, float RelayMag);

  IMAGE_GEN_API int GetBESTAmplitudeMask(float* AmplitudeY, float* Peaks, int* PeaksIndex, float Period);
 
  IMAGE_GEN_API int GetBESTAxialPSF(double* axialAmplitude, float* Intensity, float Period, float OuterDiameter, float InnerDiameter);

  IMAGE_GEN_API void Generate_BESTRings(unsigned char* Array, unsigned char* WFC, int width, int height, int depth, int centerX, int centerY, float S, int RGB);

#ifdef __cplusplus
}
#endif

#endif //IMAGE_GEN_
