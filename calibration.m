%% Initialization
clear;clc;close all;
addpath(genpath('./utils'));
root='../experiments/20230131';
name='Cali1';

before_path=[root,'/',name,'/before'];
if ~exist(before_path,'dir'), mkdirs(before_path); end
after_path=[root,'/',name,'/after'];
if ~exist(after_path,'dir'), mkdirs(after_path); end

dirname=[root,'/',name];
if ~exist(dirname,'dir'), mkdirs(dirname); end
cam_para.ROI=[300 150 170 160];
cam_para.exposure=0.0070;
cam_para.gain=0;
cam_para.trigger_frames=10;
cam_para.frame_rate = 30;
cam_para.frame_delay = 10e-3;
cam=Camera(cam_para);

slm_para.height=1080;
slm_para.width=1920;
slm_para.fresh_time=0.06;
slm_para.pixel_size=8e-6;
% save('./data/slm_pluto.mat','slm_para');

sys_para.wavelength=532e-9;
sys_para.cam_pixel_size=8e-6;
sys_para.focal=200e-3;
sys_para.mag_prop=1;
sys_para.cam_pixel_size=8e-6;
slm=SLM(slm_para,sys_para);
slm.blaze=slm.blazedgating(-0.04,-0.23,1)/(2*pi)*255;
slm.disp_image(slm.init_image,1);
%% Before Calibration


% grayVal=(1:10:255)';
grayVal=(0:255)'; 
loaded_imgs=genGrayImages(grayVal,slm.sz,'double');

for i=1:length(loaded_imgs)
    savePath=[before_path,'/',num2str(i-1)];
    disp(['(before) image: ',num2str(i-1)]);
    slm.disp_image(loaded_imgs{i},1);
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
xRange=25:125;
yRange=70:90;
y0=yRange(round(length(yRange/2)));
startPoint=[0 0 0 0.63]; % use curve fitting tool to determine
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
ft = fittype( 'poly5' );
%     ft=fittype('poly1');
[lut, res] = fit( xData, yData, ft ); % Note: polyfit 不如 fit 效果好
disp(['fitting residual: ',num2str(res.rmse)]);

slm.LUT=lut;
save([dirname,'/lut.cfit'],'lut');
save([dirname,'/phaseVal.mat'],'phaseVal');

show_lut_result(grayVal_cut,phaseVal,lut,dirname);

%% Evaluation: replay calibrated phase
% lut=importdata([dirname,'/lut.cfit'],'lut');
% lut=importdata('./data/lut.cfit','lut');

phaseGT=linspace(0,2*pi,256);
% grayValLut=round(mod(phaseGT,2*pi)/(2*pi)*255); % linear
% grayValLut=round(funLUT(phaseGT,lut));
% grayValLut=mod(round(slm.lut(phaseGT-2*pi)),256);

calibrated_imgs=genGrayImages(grayVal,slm.sz,'double');
cam.start_preview();
pause(1);
for i=1:length(calibrated_imgs)
    savePath=[after_path,'/',num2str(i-1)];
    disp(['(after) image: ',num2str(i-1)]);
    slm.disp_image(calibrated_imgs{i},1);
    cam.capture(savePath);
end
cam.stop_preview();

%% Evaluation: compute
phaseIndex=0:length(grayVal_cut)-1;
cap_imgs=load_imgs(after_path,phaseIndex);
calibrated_phases=retrivePhase(cap_imgs,yRange,xRange,startPoint,after_path);

eval_cali_result(phaseGT',calibrated_phases,dirname);

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

function x_lut=funLUT(x,lut)
    ps=unique(fieldnames(lut));
    n=length(ps);
    x_lut=zeros(size(x));
    for i=1:n
        p=lut.(ps(i));
        x_lut=x_lut+p*x.^(n-i);
    end
end