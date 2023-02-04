cam_para.ROI=[0 0 400 400];
cam_para.exposure=0.0020;
cam_para.gain=0;
cam_para.trigger_frames=10;
cam_para.frame_rate = 30;
cam_para.frame_delay = 10e-3;
cam=Camera(cam_para);

cam.start_preview();


%% capture and save
savePath="test_cam.bmp";
img=cam.capture(savePath);
figure('Color','White');
imshow(img);
% cam.stop_preview();