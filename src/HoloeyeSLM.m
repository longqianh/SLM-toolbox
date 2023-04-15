classdef HoloeyeSLM < SLM
properties
    screen_pos
end

methods
    function obj=HoloeyeSLM(slm_para)
        obj=obj@SLM(slm_para);
        scrsz = get(0,'ScreenSize');
        obj.screen_pos = [scrsz(3) scrsz(4)-slm_para.height slm_para.width slm_para.height]; 
    end

    function disp_image(obj,image_in,use_blaze,from_phase)
        arguments
            obj
            image_in
            use_blaze = 0
            from_phase = 0
        end

        if ~from_phase
            img=obj.compute_phaseimg(im2double(image_in)*2*pi,use_blaze);
        else
            img=image_in;
        end

        if isempty(ishandle(findobj('type','figure','name','pluto')))
            disp('Create Pluto figure handle.');
            figure('Name','pluto','Position',obj.screen_pos,'MenuBar','none','ToolBar','none','resize','off');
            image(img);
            colormap(gray(256));
            axis off; 
            set(gca,'units','normalized','position',[0 0 1 1],'Visible','off');
        else
            image(gca,img);
        end

        disp('Image displayed on SLM.');
    end
end

end