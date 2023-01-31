classdef Camera
    properties
        ROI
        exposure
        gain
        trigger_frames
        frame_rate 
        wait_time
        % 需要改进：set frame_rate 之类的 property cam的对应property也要改变 
        % 目前只是个摆设

    end
    properties (Access = private)
        cam
    end
    methods
    function obj=Camera(cam_para)
        obj.ROI=cam_para.ROI;
        obj.exposure=cam_para.exposure;
        obj.gain=cam_para.gain; 
        obj.trigger_frames=cam_para.trigger_frames;
        obj.frame_rate = cam_para.frame_rate;
        imaqreset;
        vid = videoinput('tisimaq_r2013_64', 1, 'Y16 (752x480)');
        vid.FramesPerTrigger = cam_para.trigger_frames;
        obj.wait_time=cam_para.trigger_frames*(1/cam_para.frame_rate+cam_para.frame_delay)+0.1;
        vid.ReturnedColorspace = 'grayscale';
        vid.ROIPosition = obj.ROI;
        
        % Access the device's video source.
        src = getselectedsource(vid);
        src.ExposureAuto = 'Off';
        src.Exposure = cam_para.exposure;
        src.Gain = cam_para.gain;
        src.FrameRate = cam_para.frame_rate;
        preview(vid);
        obj.cam=vid;
    end

    function obj=set.ROI(obj,val)
        obj.ROI=val;
%         obj.cam.ROIPosition=val;
    end
    function obj=set.exposure(obj,val)
        obj.exposure=val;
    end
    function obj=set.gain(obj,val)
        obj.gain=val;
    end

    function img=capture(obj,savePath)

        start(obj.cam);
        wait(obj.cam,obj.wait_time);
        img = getdata(obj.cam);
        stop(obj.cam);
        img=double(mean(img,4))./65536.0;
        %     figure;subplot(121);imshow(cap_image);subplot(122);imshow(imrotate(cap_image,-3));
        if nargin==2, save(savePath, 'img'); end
    end
    function stop_preview(obj)
        stoppreview(obj.cam);
    end

    function start_preview(obj)
        preview(obj.cam);
    end

    
    end
end