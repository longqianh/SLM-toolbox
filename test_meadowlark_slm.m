%% initialize: load dll


%% load vortex beam
img=imread('./data/vortex_6_19.bmp');
% disp_image(img);

%% digital holography
slm_para.height=1152;
slm_para.width=1920;
slm_para.fresh_time=0.06;
slm_para.pixel_size=9.2e-6;
% save('./data/slm_pluto.mat','slm_para');
sys_para.wavelength=532e-9;
sys_para.cam_pixel_size=8e-6;
sys_para.mag_prop=1;

sys_para.focal=200e-3;
slm_meadowlark=SLM(slm_para,sys_para);      
% slm.blaze=slm.blazedgrating(1,0,40)/(2*pi)*255;
% slm.LUT=importdata('./data/lut.cfit');
% slm.disp_image(slm.init_image,1,1);

star_img=imread('./data/star.png');
mag=2;
iter_num=20;
img_in=slm_meadowlark.image_resample(star_img,mag);
star_phase=slm_meadowlark.GS(img_in,iter_num);
% disp_phase(star_phase);