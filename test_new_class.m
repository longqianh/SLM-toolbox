clc;clear;close all;
slm_para.height=1080;
slm_para.width=1920;
slm_para.fresh_time=1/60;
slm_para.pixel_size=8e-6;
% save('./data/slm_pluto.mat','slm_para');           
% 
% sys_para.wavelength=532e-9;
% sys_para.cam_pixel_size=8e-6;
% sys_para.focal=180-3;
% sys_para.mag_prop=1;
% sys_para.cam_pixel_size=8e-6;
slm=HoloeyeSLM(slm_para);      
slm.blaze=slm.blazedgrating(1,0,40)/(2*pi)*255;
% slm.LUT=importdata('./data/lut.cfit');
% slm.disp_image(slm.init_image,1,1);

%%
lib_dir = './utils/meadowlark_sdk/';
slm_para.height=1080;
slm_para.width=1920;
slm_para.fresh_time=1.18e-3;
slm_para.pixel_size=9.2e-6;
slm_para.bit_depth = 12;
slm_para.is_nematic_type = 1;
slm_para.RAM_write_enable = 1;
slm_para.use_GPU = 0;
slm_para.max_transients  = 10;
lut_path=strcat(lib_dir,'532.lut');
slm=MeadowlarkSLM(slm_para,lib_dir,lut_path); 
