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

    function disp_image(obj,image_in,use_blaze,use_padding)
        if nargin<3
            use_blaze=0;
        end
        if nargin<4
            use_padding=0;
        end

        if ~isempty(obj.LUT)
            img=obj.reset_image_lut(image_in);
        else
            img=image_in;
        end
        if use_padding
            img=obj.image_padding(img);
        end

        if use_blaze % the blaze stored is already img
            if isempty(obj.blaze)
                disp('no blaze added, set blaze first.');
                disp_img=img;
            else
                disp_img=double(img)+obj.blaze;
            end
        else 
            disp_img=img;
        end
        disp_img=mod(disp_img,256);
        
        if isempty(ishandle(findobj('type','figure','name','pluto')))
            disp('Create Pluto figure handle.');
            figure('Name','pluto','Position',obj.screen_pos,'MenuBar','none','ToolBar','none','resize','off');
            image(disp_img);
            colormap(gray(256));
            axis off; 
            set(gca,'units','normalized','position',[0 0 1 1],'Visible','off');
        else
            image(gca,disp_img);
        end

        disp('Image displayed on SLM.');
    end
end

end