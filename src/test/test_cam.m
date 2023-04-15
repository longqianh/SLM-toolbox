cam_para.ROI=[200 0 300 400];
cam_para.exposure=0.01;
cam_para.gain=0;
cam_para.trigger_frames=1;
cam_para.frame_rate = 100;
cam_para.frame_delay = 10e-3;
cam_para.vidtype= 'Y16 (640x480)'; %'Y16 (752x480)';
cam=Camera(cam_para);

cam.start_preview();


%% capture and save
savePath="test_cam.bmp";
img=cam.capture(savePath);
figure('Color','White');
imshow(img);
% cam.stop_preview();

%% Trigger mode setting (with Bug now)
cam.trigger_info();
cam.trigger_on();
cam.trigger_off();
%% 
cam.free();