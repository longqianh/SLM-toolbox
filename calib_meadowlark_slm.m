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
lut_path=strcat(lib_dir,'slm4633_at532.lut');
slm=MeadowlarkSLM(slm_para,lib_dir,lut_path); 
slm.disp_image(slm.init_image,0,0);

%% load bz
PixelValue = 0;
PixelsPerStripe = 4;
blaze=libpointer('uint8Ptr', zeros(prod(slm.sz),1));
Gray=120;
calllib('ImageGen', 'Generate_Stripe', blaze, slm.width, slm.height, PixelValue, Gray, PixelsPerStripe);
blaze=reshape(blaze.Value,slm.sz);
slm.blaze=double(blaze);
slm.disp_image(slm.init_image,1,1);
%% init cam
cam_para.ROI=[320 200 300 10];
cam_para.exposure=0.0015;
cam_para.gain=0;
cam_para.trigger_frames=10;
cam_para.frame_rate = 60;
cam_para.frame_delay = 10e-3;
cam=Camera(cam_para);

%% Before Calibration

% grayVal=(1:10:255)';
grayVal=(0:255)'; 
loaded_imgs=genGrayImages(grayVal,slm.sz,'double');

for i=1:length(loaded_imgs)
    savePath=[before_path,'/',num2str(i-1)];
    disp(['(before) image: ',num2str(i-1)]);
    slm.disp_image(loaded_imgs{i},1,1);
%     calllib('Blink_C_wrapper', 'Write_image', board_number, rot90(loaded_imgs{i}), prod(slm.sz), wait_For_Trigger, external_Pulse, timeout_ms);
%     calllib('Blink_C_wrapper', 'ImageWriteComplete', board_number, timeout_ms); 
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
    slm.disp_image(calibrated_imgs{i},1,1);
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
% todo: integrate into SLM class
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
