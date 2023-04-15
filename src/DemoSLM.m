classdef DemoSLM < SLM

methods
    function obj=DemoSLM(slm_para)
        obj=obj@SLM(slm_para);
    end

    function disp_image(obj,image_in,use_blaze,menuoff)
         arguments
            obj
            image_in
            use_blaze = 0
            menuoff = 1
         end
            img=obj.compute_phaseimg(image_in,use_blaze);
            if menuoff
                figure('Color','White','Name','DemoDisplay','MenuBar','none','ToolBar','none','resize','off');
            else
                figure('Color','White','Name','DemoDisplay','resize','off');
            end
            image(img);
            colormap(gray(256));
            axis off; 
            set(gca,'units','normalized','position',[0 0 1 1],'Visible','off');
            
        end
    end
end
