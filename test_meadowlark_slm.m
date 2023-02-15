%% init slm
clear;clc;close all;
addpath(genpath('./utils'));
root='../experiments/202302015';
name='Cali1';
lib_dir = './utils/meadowlark_sdk/';
slm_para.height=1152;
slm_para.width=1920;
slm_para.fresh_time=1.18e-3;
slm_para.pixel_size=9.2e-6;
slm_para.bit_depth = 12;
slm_para.is_nematic_type = 1;
slm_para.RAM_write_enable = 1;
slm_para.use_GPU = 0;
slm_para.max_transients  = 10;
% lut_path=strcat(lib_dir,'linear.lut');
lut_path='./output/slm4633_at532.lut';
slm=MeadowlarkSLM(slm_para,lib_dir,lut_path); 
slm.disp_image(slm.init_image,0,0);

%% init cam
cam_para.ROI=[320 200 300 10];
cam_para.exposure=0.0015;
cam_para.gain=0;
cam_para.trigger_frames=10;
cam_para.frame_rate = 60;
cam_para.frame_delay = 10e-3;
cam=Camera(cam_para);

%% load bz
PixelValue = 0;
PixelsPerStripe = 4;
blaze=libpointer('uint8Ptr', zeros(prod(slm.sz),1));
Gray=120;
calllib('ImageGen', 'Generate_Stripe', blaze, slm.width, slm.height, PixelValue, Gray, PixelsPerStripe);
blaze=reshape(blaze.Value,slm.sz);
slm.blaze=double(blaze);
slm.disp_image(slm.init_image,1,1);

%%
