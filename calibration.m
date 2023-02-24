%% Initialize Cam
% clear;clc;close all;
addpath(genpath('./utils'));
root='../experiments/20232024';
name='Cali6-base-123';

before_path=[root,'/',name,'/before'];
if ~exist(before_path,'dir'), mkdirs(before_path); end
after_path=[root,'/',name,'/after'];
if ~exist(after_path,'dir'), mkdirs(after_path); end

dirname=[root,'/',name];
if ~exist(dirname,'dir'), mkdirs(dirname); end
cam_para.ROI=[320 160 160 160];
cam_para.exposure=0.0001;
cam_para.gain=0;
cam_para.trigger_frames=10;
cam_para.frame_rate = 60;
cam_para.frame_delay = 0.1;
cam=Camera(cam_para);

%% Initialize SLM 

% Holoeye
% slm_para.height=1080;
% slm_para.width=1920;
% slm_para.fresh_time=1/60;
% slm_para.pixel_size=8e-6;
% 
% slm=HoloeyeSLM(slm_para);
% slm.blaze=slm.blazedgrating(1,0,4)/(2*pi)*255;

% Meadowlark
% lib_dir = './utils/meadowlark_sdk/';
% slm_para.height=1152;
% slm_para.width=1920;
% slm_para.fresh_time=1.18e-3;
% slm_para.pixel_size=9.2e-6;
% slm_para.bit_depth = 12;
% slm_para.is_nematic_type = 1;
% slm_para.RAM_write_enable = 1;
% slm_para.use_GPU = 0;
% slm_para.max_transients  = 10;
% lut_path=strcat(lib_dir,'linear.lut');
% lut_path=strcat(lib_dir,'slm4633_at532.lut');
% slm=MeadowlarkSLM(slm_para,lib_dir,lut_path); 
% % PixelValue = 0;
% % PixelsPerStripe = 4;
% % blaze=libpointer('uint8Ptr', zeros(prod(slm.sz),1));
% % Gray=120;
% % calllib('ImageGen', 'Generate_Stripe', blaze, slm.width, slm.height, PixelValue, Gray, PixelsPerStripe);
% % blaze=reshape(blaze.Value,slm.sz);
% slm.blaze=slm.blazedgrating(1,0,32)/(2*pi)*105;
% slm.blaze=double(blaze);
% slm.disp_image(slm.init_image,0,0);

% Meadowlark-HDMI
lib_dir = './utils/meadowlarkhdmi_sdk/';
lut_path='./utils/meadowlarkhdmi_sdk/19x12_8bit_linearVoltage.lut';
slm_para.height=1200;
slm_para.width=1920;
slm_para.RGB=1;
slm_para.depth=8;
slm_para.pixel_size=9.2e-6; 
slm_para.bCppOrPython=false; 
slm=MeadowlarkHDMISLM(slm_para,lib_dir,lut_path);
slm.blaze=slm.blazedgrating(1,0,32)/(2*pi)*70;
% slm.LUT=importdata('./data/lut.cfit');
slm.disp_image(slm.init_image,1,1);
% slm.clear_sdk();


%% Before Calibration
% grayVal=(1:10:255)';
grayVal=(0:255)'; 
loaded_imgs=slm.cali_genimgs(grayVal,'mode','double','base',123);

for i=1:length(loaded_imgs)
    savePath=[before_path,'/',num2str(i-1)];
    disp(['(before) image: ',num2str(i-1)]);
    slm.disp_image(loaded_imgs{i},1,1);
    pause(0.06);
    cam.capture(savePath);
end
cam.stop_preview();

%% Phase Retrivel: pre-load
% to determine x/y range uncomment the following
% img=cap_imgs{1};imshow(img);
% image(img,'CDataMapping','scaled');
% ySLM = mean(double(img(y0,xRange)),1);
% xSLM= 1:length(ySLM);

phaseIndex=0:255;
cap_imgs=load_imgs(before_path,phaseIndex);
%% Phase Retrivel: compute
xRange=53:110;
yRange=65:75;
y0=yRange(round(length(yRange)/2));
startPoint=[0 0 0 0.85]; % use curve fitting tool to determine
phases=retrivePhase(cap_imgs,yRange,xRange,startPoint,before_path);
save([dirname,'/phase_shift_ori.mat'],'phases');

figure('Color','White');
plot(phases);hold on;
plot(unwrap(phases));
legend('original phase','unwrapped phase');
phaseVal=unwrap(phases);
%%
%     grayVal=grayVal(1:length(phases));
grayVal=(0:255)'; 
% one_lambda_range=25:73;
one_lambda_range=73:187;
grayVal_cut=grayVal(one_lambda_range);
phaseVal_cut=phaseVal(one_lambda_range);
[xData, yData] = prepareCurveData( phaseVal_cut-phaseVal_cut(1), grayVal_cut );
ft = fittype( 'poly5' );
%     ft=fittype('poly1');
[lut, res] = fit( xData, yData, ft ); % Note: polyfit 不如 fit 效果好
disp(['fitting residual: ',num2str(res.rmse)]);

slm.LUT=lut;
save([dirname,'/lut.cfit'],'lut');
save([dirname,'/phaseVal.mat'],'phaseVal');

show_lut_result(grayVal_cut,phaseVal_cut-phaseVal_cut(1),lut,dirname);

%% Evaluation: replay calibrated phase
% slm.dc=0.7;
phaseGT=linspace(0,2*pi,length(grayVal_cut));
eval_phases=slm.cali_genimgs(phaseGT,'mode','double','base',pi);

cam.start_preview();
% slm.disp_image(slm.init_image,1,1);
slm.disp_phase(eval_phases{1},1,1);
pause(1);
for i=1:length(eval_phases)
    savePath=[after_path,'/',num2str(i-1)];
    disp(['(after) image: ',num2str(i-1)]);
    slm.disp_phase(eval_phases{i},1,1);
    
    pause(0.06);
    cam.capture(savePath);
end
cam.stop_preview();

%% Evaluation: compute
phaseIndex=0:length(grayVal_cut)-1;
cap_imgs=load_imgs(after_path,phaseIndex);
calibrated_phases=retrivePhase(cap_imgs,yRange,xRange,startPoint,after_path);

eval_cali_result(phaseGT',calibrated_phases,dirname);

%% Unload
% slm.clear_sdk();

%% functions



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
