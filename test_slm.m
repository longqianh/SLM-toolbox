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
% lut_path=strcat(lib_dir,'slm4644_532.lut');
slm=MeadowlarkSLM(slm_para,lib_dir,lut_path);
%%
blaze=slm.blazedgrating(1,0,8)/(2*pi)*220;
slm.blaze=double(blaze);
slm.disp_image(slm.init_image,1,1);
 
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
% blaze_angle=100; % 1~255
slm.blaze=slm.blazedgrating(-1,0,4)/(2*pi)*240; 
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
mag=0.5;
img_in=slm.image_resample(star_img,mag); % bug here
star_phase=slm.GS(img_in,20);
slm.disp_phase(star_phase,1,1);
