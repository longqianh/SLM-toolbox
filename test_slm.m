%% initialization (Holoeye SLM) 
clc;clear;close all;

slm_para.height=1080;
slm_para.width=1920;
slm_para.fresh_time=1/60;
slm_para.pixel_size=8e-6;

slm=HoloeyeSLM(slm_para);      
slm.blaze=slm.blazedgrating(1,0,40)/(2*pi)*255;
% slm.LUT=importdata('./data/lut.cfit');
slm.disp_image(slm.init_image,1,1);

%% initialization (Meadowlark SLM) 
lib_dir = './utils/meadowlark_sdk/';
slm_para.height=1152;
slm_para.width=1920;
slm_para.fresh_time=1.18e-3;
slm_para.pixel_size=9.2e-6;
slm_para.bit_depth = 12;
slm_para.is_nematic_type = 1;
slm_para.RAM_write_enable = 1;
slm_para.use_GPU = 0;
slm_para.max_transients = 10;
lut_path='C:\Program Files\Meadowlark Optics\Blink 1920 HDMI\LUT Files\1920x1152_linearVoltage.lut';
slm=MeadowlarkSLM(slm_para,lib_dir,lut_path); 

PixelValue = 0;
PixelsPerStripe = 4;
blaze=libpointer('uint8Ptr', zeros(prod(slm.sz),1));
Gray=120;
calllib('ImageGen', 'Generate_Stripe', blaze, slm.width, slm.height, PixelValue, Gray, PixelsPerStripe);
blaze=reshape(blaze.Value,slm.sz);
slm.blaze=double(blaze);
slm.disp_image(slm.init_image,0,1);

%% Meadowlark SLM (HDMI)
% lib_dir = './utils/meadowlarkhdmi_sdk/';
lib_dir = 'C:\Program Files\Meadowlark Optics\Blink 1920 HDMI\SDK\';
lut_path='C:\Program Files\Meadowlark Optics\Blink 1920 HDMI\SDK\19x12_8bit_linearVoltage.lut';
slm_para.height=1200;
slm_para.width=1920;
slm_para.RGB=1;
slm_para.depth=8;
slm_para.pixel_size=9.2e-6; 
slm_para.bCppOrPython=false; 
slm=MeadowlarkHDMISLM(slm_para,lib_dir,lut_path);

PixelValueOne = 0;
PixelValueTwo = 50;
PixelsPerStripe=2;
WFC = libpointer('uint8Ptr', zeros(prod(slm.sz)*3,1));
img_g_p = libpointer('uint8Ptr', zeros(prod(slm.sz)*3,1));
calllib('ImageGen', 'Generate_Stripe', img_g_p, WFC, slm.width, slm.height, slm.depth, PixelValueOne, 255-PixelValueTwo, PixelsPerStripe, slm.RGB);
blaze=reshape(img_g_p.Value,[slm.sz,3]);

slm.blaze=double(blaze);
% slm.disp_image(slm.init_image,0,1); % bug here
slm.disp_image(slm.init_image,1,1);
 
% slm.clear_sdk();
%% image display
close all;
img=imread('./data/vortex_6_19.bmp');
slm.disp_image(img,1,1);

%% holography display 

sys_para.wavelength=532e-9;
sys_para.cam_pixel_size=8e-6;
sys_para.focal=180-3;
sys_para.mag_prop=1;
sys_para.cam_pixel_size=8e-6;

close all;
star_img=imread('./data/star.png');
mag=2;
img_in=slm.image_resample(star_img,mag,sys_para);
star_phase=slm.GS(img_in,20);
slm.disp_phase(star_phase,1,1);
