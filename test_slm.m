%% initialization 
clc;clear;close all;
slm_para.height=1080;
slm_para.width=1920;
slm_para.fresh_time=0.06;
slm_para.pixel_size=8e-6;
% save('./data/slm_pluto.mat','slm_para');

sys_para.wavelength=532e-9;
sys_para.cam_pixel_size=8e-6;
sys_para.focal=180e-3;
sys_para.mag_prop=1;
sys_para.cam_pixel_size=8e-6;
slm=SLM(slm_para,sys_para);      
slm.blaze=slm.blazedgrating(0.1,0,0.2)/(2*pi)*255;
% slm.LUT=importdata('./data/lut.cfit');
slm.disp_image(slm.init_image,1,1);

%% image display
close all;
img=imread('./data/vortex_6_19.bmp');
slm.disp_image(img,1,1);

%% holography display 
close all;
star_img=imread('./data/star.png');
mag=2;
img_in=slm.image_resample(star_img,mag);
star_phase=slm.GS(img_in,20);
slm.disp_phase(star_phase,1,1);
