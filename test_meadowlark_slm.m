%%
% the parameters of slm
slm_para.height=1152;
slm_para.width=1920;
slm_para.pixel_size=9.2e-6;
slm_para.fresh_time=1/30;
sys_para.wavelength=532e-9;
sys_para.cam_pixel_size=8e-6;
sys_para.mag_prop=1; 
sys_para.focal=150e-3;
slm_meadowlark=SLM(slm_para,sys_para);   
%% initialize: load dll
addpath(genpath('./utils/'));
%relative path of dll
lib_dir = './utils/meadowlark_sdk/';
C_wrapper_path = strcat(lib_dir,"Blink_C_wrapper.dll");
C_wrapper_h_path = strcat(lib_dir,"Blink_C_wrapper.h");

%load dll
if ~libisloaded(C_wrapper_path)
    loadlibrary(C_wrapper_path,C_wrapper_h_path);
end

% This loads the image generation functions
if ~libisloaded('ImageGen')
    loadlibrary('ImageGen.dll', 'ImageGen.h');
end

% Basic parameters for calling Create_SDK
bit_depth = 12;
num_boards_found = libpointer('uint32Ptr', 0);
constructed_okay = libpointer('int32Ptr', 0);
is_nematic_type = 1;
RAM_write_enable = 1;
use_GPU = 0;
max_transients  = 10;
wait_For_Trigger = 0; % This feature is user-settable; use 1 for 'on' or 0 for 'off'
external_Pulse = 0;
timeout_ms = 5000;



% In your program you should use the path to your custom LUT as opposed to linear LUT
lut_file = strcat(lib_dir,'slm4633_at532.lut');
% lut_file=strcat(lib_dir,'calibraPCIe1064.LUT');
reg_lut = libpointer('string');

% Call the constructor
calllib('Blink_C_wrapper', 'Create_SDK', bit_depth, num_boards_found, constructed_okay, is_nematic_type, RAM_write_enable, use_GPU, max_transients, reg_lut);


if constructed_okay.value ~= 0  
    disp('Blink SDK was not successfully constructed');
    disp(calllib('Blink_C_wrapper', 'Get_last_error_message'));
    calllib('Blink_C_wrapper', 'Delete_SDK');
else
    board_number = 1;
    disp('Blink SDK was successfully constructed');
    fprintf('Found %u SLM controller(s)\n', num_boards_found.value);
end

% load a LUT 
calllib('Blink_C_wrapper', 'Load_LUT_file',board_number, lut_file);
disp("load LUT successfully.");

calllib('Blink_C_wrapper', 'Write_image', board_number, slm_meadowlark.init_image, slm_meadowlark.width*slm_meadowlark.height, wait_For_Trigger, external_Pulse, timeout_ms);
calllib('Blink_C_wrapper', 'ImageWriteComplete', board_number, timeout_ms); 

%% generate image
% disp_image(img);
% img_vor=imread('./data/vortex_6_19.bmp');% load vortex beam
% img_vor=slm_meadowlark.image_padding(img_vor);
% 
% % Generate a blazed grating
img_g = libpointer('uint8Ptr', zeros(slm_meadowlark.width*slm_meadowlark.height,1));
Period = 4;
Increasing = 1;
horizontal = false;
calllib('ImageGen', 'Generate_Grating', img_g, slm_meadowlark.width, slm_meadowlark.height, Period, Increasing, horizontal);
img_g = reshape(img_g.Value, [slm_meadowlark.height, slm_meadowlark.width]);

% img = libpointer('uint8Ptr', zeros(slm_meadowlark.width*slm_meadowlark.height,1));
% VortexCharge=16;
% fork =0;
% cX=slm_meadowlark.width/2;
% cY=slm_meadowlark.height/2;
% calllib('ImageGen','Generate_LG',img,slm_meadowlark.width,slm_meadowlark.height,VortexCharge,cX,cY,fork);
% img = reshape(img.Value, [slm_meadowlark.height, slm_meadowlark.width]);

% figure;
% subplot(121);
% imshow(mod(img*0.5,256),[0 255]);colorbar;
% subplot(122);
% imshow(mod(img_vor,256),[0 255]);colorbar;
%% load image


calllib('Blink_C_wrapper', 'Write_image', board_number, rot90(img_g), slm_meadowlark.width*slm_meadowlark.height, wait_For_Trigger, external_Pulse, timeout_ms);
calllib('Blink_C_wrapper', 'ImageWriteComplete', board_number, timeout_ms); 
pause(1.0) % This is in seconds
%%

% img = rot90(mod(double(img)+img_vor, 256));
% img=mod(double(img),256);
calllib('Blink_C_wrapper', 'Write_image', board_number, rot90(star_phase)/(2*pi)*255, slm_meadowlark.width*slm_meadowlark.height, wait_For_Trigger, external_Pulse, timeout_ms);
calllib('Blink_C_wrapper', 'ImageWriteComplete', board_number, timeout_ms); 
pause(1.0) % This is in seconds
% stop(vid);    
   




%% digital holography

% slm.blaze=slm.blazedgrating(1,0,40)/(2*pi)*255;
% slm.LUT=importdata('./data/lut.cfit');
% slm.disp_image(slm.init_image,1,1);

star_img=imread('./data/star.png');
% star_img=squeeze(star_img(:,:,1));
% star_img=slm_meadowlark.image_padding(star_img);
mag=1;
iter_num=50;
img_in=slm_meadowlark.image_resample(star_img,mag,0.2);
star_phase=slm_meadowlark.GS(img_in,iter_num);
% disp_phase(star_phase);


%% clear

calllib('Blink_C_wrapper', 'Delete_SDK');
%destruct
if libisloaded('Blink_C_wrapper')
    unloadlibrary('Blink_C_wrapper');
end