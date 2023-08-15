%% Initialize Exp
clc;close all;clear;
addpath("F:\Longqian\Projects\ExpManager\src"); % add ExpManager first
exp_toolbox=["SLM-toolbox","Camera-toolbox"];
ma=ExpManager('SLM-calibration-3',exp_toolbox);
ma.info()
before_path=fullfile(ma.exp_save_dir,'before');
after_path=fullfile(ma.exp_save_dir,'after');
ma.mkdirs(before_path);
ma.mkdirs(after_path);
%% Initialize Cam
% cam_para.ROI=[200 150 120 150];

% cam_para.ROI=[200 180 240 180];
cam_para.exposure=1/60;
cam_para.gain=0;
cam_para.trigger_frames=3;
cam_para.frame_rate = 30;
cam_para.vidtype='Y16 (1280x960)'; %'Y16 (752x480)';
cam=ICCamera(cam_para);

%% Initialize SLM 

% Holoeye
slm_para.height=1080;
slm_para.width=1920;
slm_para.fresh_time=1/60;
slm_para.pixel_size=8e-6;

slm=HoloeyeSLM(slm_para);
slm.blaze=slm.blazedgrating(1,0,12);

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
% % lut_path=strcat(lib_dir,'20230517.lut');
% slm=MeadowlarkSLM(slm_para,lib_dir,lut_path); 
% blaze=slm.blazedgrating(1,0,12)*0.87;% 220/255;
% slm.blaze=double(blaze);
% slm.disp_image(slm.init_image,1);
slm.disp_image(slm.init_image,0);

% Meadowlark-HDMI
% lib_dir = './utils/meadowlarkhdmi_sdk/';
% lut_path='./utils/meadowlarkhdmi_sdk/19x12_8bit_linearVoltage.lut';
% slm_para.height=1200;
% slm_para.width=1920;
% slm_para.RGB=1;
% slm_para.depth=8;
% slm_para.pixel_size=9.2e-6; 
% slm_para.bCppOrPython=false; 
% slm=MeadowlarkHDMISLM(slm_para,lib_dir,lut_path);
% slm.blaze=slm.blazedgrating(1,0,32)/(2*pi)*70;
% slm.LUT=importdata('./data/lut.cfit');
% slm.disp_image(slm.init_image,1,1);
% slm.clear_sdk();

%% Selece ROI
im=cam.capture();
roi=cam.selectROI(im);
cam.setROI(roi);
%% Before Calibration
grayVal=(0:255)'; 
loaded_imgs=ModulatorUtil.generate_cali_images(slm.sz,grayVal,'mode','double','base',0);
slm.disp_image(loaded_imgs{1},1);pause(1);
% cam.open();
for i=1:length(loaded_imgs)
    savePath=fullfile(before_path,strcat(num2str(i-1),'.bmp'))                                                      ;
    disp(['(before) image: ',num2str(i-1)]);
    slm.disp_image(loaded_imgs{i},1);
    pause(0.05);
    cam.capture(savePath);
end

%% Phase Retrivel: pre-load
% to determine x/y range uncomment the following

% ySLM = mean(double(img(y0,xRange)),1);
% xSLM= 1:length(ySLM);

phaseIndex=0:255;
cap_imgs=load_imgs(before_path,phaseIndex);
img=cap_imgs{150};imshow(img,[]);
figure;
image(img,'CDataMapping','scaled');
% for i=1:length(cap_imgs)
%     cap_imgs{i}=cap_imgs{i}';
% end
%% Phase Retrivel: compute
xRange=108:134;
yRange=98;
y0=yRange(round(length(yRange)/2));
startPoint=[0 0 0 0.9]; % use curve fitting tool to determine

phases=retrivePhase(cap_imgs,yRange,xRange,startPoint,before_path);
% save(fullfile(ma.exp_save_dir,'phase_shift_ori.mat'),'phases');

figure('Color','White');
plot(phases);hold on;
plot(unwrap(phases));
legend('original phase','unwrapped phase');
phaseVal=unwrap(phases);
print(fullfile(before_path,'slm_cali_strip_curve'),'-dpng','-r400');
%% For Gamma Fitting
close all;
gammabit=10;
one_lambda_range=8:160;
polytype='poly7';
% lut_path=fullfile(ma.exp_save_dir,strcat(ma.exp_date,".lut"));%meadowlark
lut_path=fullfile(ma.exp_save_dir,strcat(ma.exp_date,".csv"));%holoeye
% lut_path='test.csv';
SLM.computeLUT(phaseVal,one_lambda_range,gammabit,polytype,lut_path,'holoeye');
print(fullfile(after_path,'gamma_curve'),'-dpng','-r400');
%% For Gray-Phase Fitting (not recommended)
%     grayVal=grayVal(1:length(phases));
grayVal=(0:255)'; 
one_lambda_range=8:160;
grayVal_cut=grayVal(one_lambda_range);
phaseVal_cut=phaseVal(one_lambda_range);
[xData, yData] = prepareCurveData( phaseVal_cut-phaseVal_cut(1), grayVal_cut );
ft = fittype( 'poly5' );
%     ft=fittype('poly1');
[lut, res] = fit( xData, yData, ft ); % Note: polyfit 不如 fit 效果好
disp(['fitting residual: ',num2str(res.rmse)]);

slm.LUT=lut;
save(fullfile(ma.exp_save_dir,'lut.cfit'),'lut');
save(fullfile(ma.exp_save_dir,'phaseVal.mat'),'phaseVal');

show_lut_result(grayVal_cut,phaseVal_cut-phaseVal_cut(1),lut,ma.exp_save_dir);


%% For Meadowlark SLM
slm.clear_sdk();
% lut_path=strcat('test.lut');
% lut_path=strcat(lib_dir,'slm4633_at532.lut');
slm=MeadowlarkSLM(slm_para,lib_dir,lut_path); 
blaze=slm.blazedgrating(1,0,12)*0.87;
slm.blaze=double(blaze);
slm.disp_image(slm.init_image,0);
%% Evaluation: replay calibrated phase
% slm.dc=0.7;
% phaseGT=linspace(0,2*pi,length(grayVal_cut));
phaseGT=linspace(0,2*pi,256);
eval_phases=ModulatorUtil.generate_cali_images(slm.sz,phaseGT,'mode','double','base',0);

% cam.preview();
% slm.disp_image(slm.init_image,1,1);
% cam.open(); % Thorlabs
slm.disp_phase(eval_phases{1},1);
pause(1);
for i=1:length(eval_phases)
    savePath=fullfile(after_path,strcat(num2str(i-1),'.bmp'));
    disp(['(after) image: ',num2str(i-1)]);
    slm.disp_phase(eval_phases{i},1);
    
    pause(0.06);
    cam.capture(savePath);
end


%% Evaluation: compute

% startPoint=[1 0 0.6 0.5]; % use curve fitting tool to determine
phaseIndex=0:length(eval_phases)-1;
cap_imgs=ModulatorUtil.load_imgs(after_path,phaseIndex);
% for i=1:length(cap_imgs)
%     cap_imgs{i}=cap_imgs{i}';
% end
vidtype="avi";
% xRange=113:139;
% yRange=124;
% y0=yRange(round(length(yRange)/2));
% startPoint=[0 0 0 0.85];
calibrated_phases=retrivePhase(cap_imgs,yRange,xRange,startPoint,after_path,vidtype);

eval_cali_result(phaseGT',calibrated_phases,ma.exp_save_dir);

%% if need gif
addpath(genpath('F:\Longqian\Projects\Exp-toolbox\src'))
vidpath='F:\Longqian\Projects\Experiments\20230411\SLM-calibration\after\shiftvedio.avi';
avi2gif(vidpath,0.03)
%% Unload
% slm.clear_sdk();

%% functions



function imgs=load_imgs(dirname,phase_index)

    imgs=cell(length(phase_index),1);
    for i=1:length(phase_index)
        img=imread(fullfile(dirname,[num2str(phase_index(i)),'.bmp']));
        imgs{i}=double(img);
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
    print(fullfile(dirname,'look_up_table'),'-dpng','-r400');
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
    print(fullfile(savedir,'calib_eval'),'-dpng','-r400');
end
