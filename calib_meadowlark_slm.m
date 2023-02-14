%% cam
clear;clc;close all;
addpath(genpath('./utils'));
root='../experiments/202302014';
name='Meadowlark-Cali5-1_2';

before_path=[root,'/',name,'/before'];
if ~exist(before_path,'dir'), mkdirs(before_path); end
after_path=[root,'/',name,'/after'];
if ~exist(after_path,'dir'), mkdirs(after_path); end

dirname=[root,'/',name];
if ~exist(dirname,'dir'), mkdirs(dirname); end
cam_para.ROI=[200 280 200 120];
cam_para.exposure=0.0008 ;
cam_para.gain=0;
cam_para.trigger_frames=10;
cam_para.frame_rate = 60;
cam_para.frame_delay = 10e-3;
cam=Camera(cam_para);
%% slm
calllib('Blink_C_wrapper', 'Delete_SDK');
%destruct
if libisloaded('Blink_C_wrapper')
    unloadlibrary('Blink_C_wrapper');
end

slm_para.height=1152;
slm_para.width=1920;
slm_para.pixel_size=9.2e-6;
slm_para.fresh_time=1/30;
% sys_para.wavelength=532e-9;
% sys_para.cam_pixel_size=8e-6;
% sys_para.mag_prop=1; 
% sys_para.focal=200e-3;
slm=SLM(slm_para); 

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
lut_file = strcat(lib_dir,'532.LUT');
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
% calllib('Blink_C_wrapper', 'Load_linear_LUT',board_number);
calllib('Blink_C_wrapper', 'Load_LUT_file',board_number, lut_file);
% disp("load LUT successfully.");

calllib('Blink_C_wrapper', 'Write_image', board_number, slm.init_image, slm.width*slm.height, wait_For_Trigger, external_Pulse, timeout_ms);
calllib('Blink_C_wrapper', 'ImageWriteComplete', board_number, timeout_ms); 

%% Before Calibration

% grayVal=(1:10:255)';
grayVal=(0:255)'; 
loaded_imgs=genGrayImages(grayVal,slm.sz,'double');

for i=1:length(loaded_imgs)
    savePath=[before_path,'/',num2str(i-1)];
    disp(['(before) image: ',num2str(i-1)]);
%     slm.disp_image(loaded_imgs{i},1);
    calllib('Blink_C_wrapper', 'Write_image', board_number, rot90(loaded_imgs{i}), prod(slm.sz), wait_For_Trigger, external_Pulse, timeout_ms);
    calllib('Blink_C_wrapper', 'ImageWriteComplete', board_number, timeout_ms); 
    pause(0.2);
    cam.capture(savePath);
end
cam.stop_preview();

%% Phase Retrivel: pre-load
% to determine x/y range uncomment the following
% img=cap_imgs{1};imshow(img);
% ySLM = mean(double(img(y0,xRange)),1);
% xSLM= 1:length(ySLM);

phaseIndex=0:255;
cap_imgs=load_imgs(before_path,phaseIndex);
%% Phase Retrivel: compute
xRange=40:142;
yRange=30:72;
y0=yRange(round(length(yRange/2)));
startPoint=[0 0 0 0.549778714378214]; % use curve fitting tool to determine
phases=retrivePhase(cap_imgs,yRange,xRange,startPoint,before_path);
save([dirname,'/phase_shift_ori.mat'],'phases');

figure('Color','White');
plot(phases);hold on;
plot(unwrap(phases));
legend('original phase','unwrapped phase');
phaseVal=unwrap(phases);

%     grayVal=grayVal(1:length(phases));
grayVal_cut=grayVal(1:end);
[xData, yData] = prepareCurveData( phaseVal, grayVal_cut );
ft = fittype( 'poly3' );
%     ft=fittype('poly1');
[lut, res] = fit( xData, yData, ft ); % Note: polyfit 不如 fit 效果好
disp(['fitting residual: ',num2str(res.rmse)]);

slm.LUT=lut;
save([dirname,'/lut.cfit'],'lut');
save([dirname,'/phaseVal.mat'],'phaseVal');

show_lut_result(grayVal_cut,phaseVal,lut,dirname);

%% Evaluation: replay calibrated phase
% slm.dc=0.7;
grayVal_cut=grayVal(1:end);
phaseGT=linspace(0,2*pi,length(grayVal_cut));

calibrated_imgs=genGrayImages(grayVal_cut,slm.sz,'double');
cam.start_preview();
pause(1);
for i=1:length(calibrated_imgs)
    savePath=[after_path,'/',num2str(i-1)];
    disp(['(after) image: ',num2str(i-1)]);
%     slm.disp_image(calibrated_imgs{i},1);
    calllib('Blink_C_wrapper', 'Write_image', board_number, rot90(calibrated_imgs{i}), prod(slm.sz), wait_For_Trigger, external_Pulse, timeout_ms);
    calllib('Blink_C_wrapper', 'ImageWriteComplete', board_number, timeout_ms);
    pause(0.2);
    cam.capture(savePath);
end
cam.stop_preview();

%% Evaluation: compute
phaseIndex=0:length(grayVal_cut)-1;
cap_imgs=load_imgs(after_path,phaseIndex);
calibrated_phases=retrivePhase(cap_imgs,yRange,xRange,startPoint,after_path);

eval_cali_result(phaseGT',calibrated_phases,dirname);

%% unload

calllib('Blink_C_wrapper', 'Delete_SDK');
%destruct
if libisloaded('Blink_C_wrapper')
    unloadlibrary('Blink_C_wrapper');
end
%% functions

function gray_imgs=genGrayImages(grayVal,sz,mode)
    n=length(grayVal);
    gray_imgs=cell(n,1);
    for i=1:n
        if mode=="whole"
            gray_imgs{i}=grayVal(i)*ones(sz,'uint8');
        elseif mode=="double"
            tmp=zeros(sz,'uint8');
            tmp(:,1:round(sz(2)/2))=grayVal(i);
            gray_imgs{i}=tmp;
        end
    end
end

function imgs=load_imgs(dirname,phase_index)

    imgs=cell(length(phase_index),1);
    for i=1:length(phase_index)
        img=load([dirname,'/',num2str(phase_index(i)),'.mat']);
        imgs{i}=double(img.img);
    end
    disp([num2str(length(phase_index)),' image loaded.']);
end


function show_lut_result(grayVal,phaseVal,lut,dirname)
    figure('Color','White');
    subplot(211);
    plot(grayVal,phaseVal,'b');
    xlabel('Gray Value','interpreter','latex');
    ylabel('Phase Value / radian','interpreter','latex');
    legend('gray-phase curve','interpreter','latex','Location','best');
    subplot(212);
    plot(phaseVal,grayVal,'r.');hold on;
    plot(phaseVal,lut(phaseVal),'b');
    legend('phase-gray points','fitted curve','interpreter','latex','Location','best');
    xlabel('Phase Value / radian','interpreter','latex');
    ylabel('Gray Value','interpreter','latex');
    print([dirname,'/look_up_table'],'-dpng','-r400');
end


function eval_cali_result(phaseGT,phase_aftercali,savedir)
%     if mode=="minus_phase"
%         phase_aftercali=phase_aftercali+2*pi;
%     end
    phase_rec=unwrap(phase_aftercali);
    [xData, yData] = prepareCurveData( phaseGT, phase_rec);

    ft = fittype( 'poly1' );
    [fitresult, gof] = fit( xData, yData, ft );
    figure('Color','White');
    h = plot( fitresult, xData, yData );
    legend( h, 'phaseVal vs. phaseGT', ['$k=',num2str(fitresult.p1), ', R^2=',num2str(gof.rsquare),'$'], 'Location', 'best','interpreter','latex');
    xlabel('Phase Groundtruth','interpreter','latex');
    ylabel('Phase Value / radian','interpreter','latex');
    print([savedir,'/corrected_result'],'-dpng','-r400');
end
