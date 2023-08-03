clc;clear;close all;

%% init Manager
addpath("F:\Longqian\Projects\Expmanger\src"); % add ExpManager first
% addpath("F:\KangYuan\project\ExpManager\src"); 
exp_toolbox=["SLM-toolbox","Camera-toolbox"];
ma=ExpManager('SLM-MMF',exp_toolbox);   
ma.info()
%%
slm_para.height=1080;
slm_para.width=1920;
slm_para.fresh_time=1/60;
slm_para.pixel_size=8e-6;

slm=HoloeyeSLM(slm_para);      
% slm.blaze=slm.blazedgrating(1,0,6)*0.88;
slm.blaze=slm.blazedgrating(1,0,6)*0.88;

slm.LUT=importdata('../data/20230718-lut.cfit');
slm.disp_image(slm.init_image,1);
%% 
phase = ones(64)*pi/2;
H=(1-hadamard(32^2))*pi/2;
phase(32-16+1:32+16,32-16+1:32+16)=reshape(H(:,10),[32,32]);
% amp = im2double(imread("lena_gray_512.tif"));imshow(amp,[]);
% amp = ones(512);
phase = OpticUtil.expand_img(phase,16);
slm.disp_phase(phase,1);

