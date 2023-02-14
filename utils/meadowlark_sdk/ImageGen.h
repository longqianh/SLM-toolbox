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


	IMAGE_GEN_API void Generate_Stripe(unsigned char* Array, int width, int height, int PixelValOne, int PixelValTwo, int PixelsPerStripe);

	IMAGE_GEN_API void Generate_Checkerboard(unsigned char* Array, int width, int height, int PixelValOne, int PixelValTwo, int PixelsPerCheck);

	IMAGE_GEN_API void Generate_Solid(unsigned char* Array, int width, int height, int PixelVal);

	IMAGE_GEN_API void Generate_Random(unsigned char* Array, int width, int height);

	IMAGE_GEN_API void Generate_Zernike(unsigned char* Array, int width, int height, int centerX, int centerY, int radius, double Piston, double TiltX, double TiltY,
		double Power, double AstigX, double AstigY, double ComaX, double ComaY, double PrimarySpherical,
		double TrefoilX, double TrefoilY, double SecondaryAstigX, double SecondaryAstigY, double SecondaryComaX,
		double SecondaryComaY, double SecondarySpherical, double TetrafoilX, double TetrafoilY, double TertiarySpherical,
		double QuaternarySpherical);

	IMAGE_GEN_API void Generate_FresnelLens(unsigned char* Array, int width, int height, int centerX, int centerY, int radius, double Power, bool cylindrical, bool horizontal);

	IMAGE_GEN_API void Generate_Grating(unsigned char* Array, int width, int height, int Period, bool increasing, bool horizontal);

	IMAGE_GEN_API void Generate_Sinusoid(unsigned char* Array, int width, int height, int Period, bool horizontal);

	IMAGE_GEN_API void Generate_LG(unsigned char* Array, int width, int height, int VortexCharge, int centerX, int centerY, bool fork);

	IMAGE_GEN_API void Generate_ConcentricRings(unsigned char* Array, int width, int height, int InnerDiameter, int OuterDiameter, int PixelValOne, int PixelValTwo, int centerX, int centerY);
	
	IMAGE_GEN_API void Generate_Axicon(unsigned char* Array, int width, int height, int PhaseDelay, int centerX, int centerY, bool increasing);

	IMAGE_GEN_API void Mask_Image(unsigned char* Array, int width, int height, int Region, int NumRegions);

	IMAGE_GEN_API bool Initalize_HologramGenerator(int width, int height, int iterations);

	IMAGE_GEN_API bool Generate_Hologram(unsigned char *Array, float *x_spots, float *y_spots, float *z_spots, float *I_spots, int N_spots);

	IMAGE_GEN_API void Destruct_HologramGenerator();

	IMAGE_GEN_API bool Initalize_RegionalLUT(int width, int height);

	IMAGE_GEN_API bool Load_RegionalLUT(const char* const RegionalLUTPath, float* Max, float* Min);

	IMAGE_GEN_API bool Apply_RegionalLUT(unsigned char *Array);

	IMAGE_GEN_API void Destruct_RegionalLUT();

	IMAGE_GEN_API bool SetBESTConstants(int FocalLength, float BeamDiameter, float Wavelength, float SLMpitch, int SLMNumPixels, float ObjNA, float ObjMag, float ObjRefInd, float TubeLength, float RelayMag);

	IMAGE_GEN_API bool GetBESTAmplitudeMask(float* AmplitudeY, float* Peaks, int* PeaksIndex, float Period);

	IMAGE_GEN_API bool GetBESTAxialPSF(double* axialAmplitude, float* Intensity, float Period, float OuterDiameter, float InnerDiameter);

	IMAGE_GEN_API void Generate_BESTRings(unsigned char* Array, int width, int height, int centerX, int centerY, float S);


#ifdef __cplusplus
}
#endif

#endif //IMAGE_GEN_
