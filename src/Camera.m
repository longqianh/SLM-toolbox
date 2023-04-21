classdef Camera < handle
    properties
        ROI
        exposure
        gain
        trigger_frames
        frame_rate 
        frame_delay
        device_id 

    end
    properties (Access = private)
        cam
        max_frame_rate
        wait_time
    end
    methods
    function obj=Camera(cam_para)
%         imaqreset;
        if ~isfield(cam_para,"trigger_frames")
            cam_para.trigger_frames=1;
        end
        if ~isfield(cam_para,"frame_delay")
            cam_para.frame_delay=0.001;
        end
        if ~isfield(cam_para,"ROI")
            cam_para.ROI=[0,0,600,400];
        end
        if ~isfield(cam_para,"device_id")
            cam_para.device_id=1;
        end

        vid = videoinput('tisimaq_r2013_64', cam_para.device_id, cam_para.vidtype);
        vid.FramesPerTrigger = cam_para.trigger_frames;
        obj.frame_delay=cam_para.frame_delay;
        obj.wait_time=cam_para.trigger_frames*(1/cam_para.frame_rate+cam_para.frame_delay);
        vid.ReturnedColorspace = 'grayscale';
        vid.ROIPosition = cam_para.ROI;
        
        % Access the device's video source.
        src = getselectedsource(vid);
        obj.max_frame_rate=src.FrameRate;
        src.ExposureAuto = 'Off';
        
        if 1/cam_para.exposure>obj.max_frame_rate
            % 曝光时间对应帧率大于最大帧率, 以曝光时间为准
            obj.frame_rate=obj.max_frame_rate;
            src.Exposure = cam_para.exposure;
            obj.exposure=src.Exposure;
        else
            % 曝光时间帧率小于最大帧率，以帧率为准
            src.FrameRate = cam_para.frame_rate;
            obj.frame_rate = cam_para.frame_rate;
        end
        src.Gain = cam_para.gain;
        preview(vid);
        obj.cam=vid;
        obj.ROI=vid.ROIPosition;
        obj.gain=src.Gain; 
        obj.trigger_frames=vid.FramesPerTrigger;        
        obj.device_id=cam_para.device_id;
    end

    function info(obj)
        src = getselectedsource(obj.cam);
        fprintf("Camera Name: %s\n",src.SourceName);
        fprintf("Max FrameRate: %.2f\n",src.FrameRate);
        fprintf("Frames Per Triger: %d\n",obj.cam.FramesPerTrigger);
        fprintf("Exposure Time: %.2f ms\n",src.Exposure*1e3);
        fprintf("Triger State: %s\n",src.Trigger);
        fprintf("Triger Delay: %.3f\n",src.TriggerDelay);
%         fprintf("Triger Polarity: %s\n",src.TriggerPolarity);
    end

    function setTriggerFrames(obj,val)
        obj.cam.FramesPerTrigger=val;
    end

    function setROI(obj,val)
        obj.cam.ROIPosition=val;
        obj.ROI=val;
        obj.update_max_frame_rate();
    end

    function setExposure(obj,val)
        if 1/val>obj.max_frame_rate
            obj.frame_rate=100;
        else 
            obj.frame_rate=1/val;
        end
        src=getselectedsource(obj.cam);
        src.Exposure=val;
        obj.exposure=val;
        fprintf("Frame rate changed to %.2f Hz.\n",obj.frame_rate);
        obj.update_wait_time();
    end
    function setGain(obj,val)
        src=getselectedsource(obj.cam);
        src.Gain=val;
        obj.gain=val;
    end

    function setFrameRate(obj,val)
        % Frame rate changes with exposure
        % Only at maximum frame rate can we change exposure
        if val>obj.max_frame_rate
            fprintf("Over max frame rate.\n");
        else
            src=getselectedsource(obj.cam);
            src.Exposure=1/val;
            obj.frame_rate = val;
            obj.exposure=src.Exposure;
            fprintf("Exposure time change to %.3f ms.\n",src.Exposure*1e3);
        end
        obj.update_wait_time();
    end

    function update_max_frame_rate(obj)
        src=getselectedsource(obj.cam);
        obj.max_frame_rate = src.FrameRate;
        fprintf("Max frame rate updated: %.2f\n",obj.max_frame_rate);
    end

    function update_wait_time(obj)
        if obj.exposure>1/obj.frame_rate
            obj.frame_rate=1/obj.exposure;
        end
        obj.wait_time=obj.trigger_frames*(1/obj.frame_rate+obj.frame_delay);
        fprintf("Waittime updated: %.2f ms\n",obj.wait_time*1e3);

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

%     function trigger_on(obj)
%         triggerconfig(obj.cam,"immediate");
%         triggerconfig(obj.cam,'hardware')
%  end
% 
%     function trigger_off(obj)
%         triggerconfig(obj.cam,"manual");
% 
%     end
%     
%     function trigger_info(obj)
%         config = triggerinfo(obj.cam);
%         fprintf("Trigger mode: %s\n",config.TriggerCondition);
%     end

    function free(obj)
        obj.stop_preview();
        delete(obj.cam);

    end
    end
end