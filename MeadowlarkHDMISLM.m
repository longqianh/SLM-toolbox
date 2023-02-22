classdef MeadowlarkHDMISLM < SLM
properties
    lib_dir
    RGB
end
% properties (Dependent)
%     sz
% end
methods (Static)
    function load_libs(lib_dir)
        
        C_wrapper_dll_path = strcat(lib_dir,"Blink_C_wrapper.dll");
        C_wrapper_h_path = strcat(lib_dir,"Blink_C_wrapper.h");
        imageGen_dll_path=strcat(lib_dir,"ImageGen.dll");
        imageGen_h_path=strcat(lib_dir,"ImageGen.h");
        
        if ~libisloaded('Blink_C_wrapper')
            loadlibrary(C_wrapper_dll_path,C_wrapper_h_path);
        end
        if ~libisloaded('ImageGen')
            loadlibrary(imageGen_dll_path, imageGen_h_path);
        end
        disp('Blink C libs loaded.');
    end

    function load_lut(lut_path)
        calllib('Blink_C_wrapper','Load_lut', lut_path);
        fprintf('LUT loaded from %s. LUT loading should not be called twice!\n',lut_path);
    end

    function construct_sdk(bCppOrPython)
        calllib('Blink_C_wrapper', 'Create_SDK', bCppOrPython);    
        disp('Blink SDK was successfully constructed');
           
    end
    function clear_sdk()
        calllib('Blink_C_wrapper', 'Delete_SDK');
        disp('Blink C SDK destructed.');
       
        if libisloaded('Blink_C_wrapper')
            unloadlibrary('Blink_C_wrapper');
        end
        if ~libisloaded('ImageGen')
            loadlibrary('ImageGen');
        end
        disp('Blink C libs unloaded.');
    end
end

methods
    function obj=MeadowlarkHDMISLM(slm_para,lib_dir,lut_path)
        obj=obj@SLM(slm_para);
        obj.RGB=slm_para.RGB;
        obj.depth=slm_para.depth;
        obj.lib_dir=lib_dir;        
        obj.load_libs(lib_dir);
        obj.construct_sdk(slm_para.bCppOrPython);
        obj.load_lut(lut_path);
% height = calllib('Blink_C_wrapper', 'Get_Height');
% depth = calllib('Blink_C_wrapper', 'Get_Depth');
    end

    function disp_image(obj,image_in,use_blaze,use_padding,options)
        arguments
            obj
            image_in
            use_blaze (1,1) = true
            use_padding (1,1) = true
            options.isEightBit (1,1) = false
        end

        if ~isempty(obj.LUT)
            img=obj.reset_image_lut(image_in);
        else
            img=image_in;
        end

        if use_padding
            img=obj.image_padding(img);
        end

        if use_blaze
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
        calllib('Blink_C_wrapper', 'Write_image', mod(disp_img,2^obj.depth), options.isEightBit);

    end
    
%      function sz=get.sz(obj)
%         if obj.RGB
%             sz = [obj.height,obj.width,3];
%         else
%             sz = [obj.height,obj.width];
%         end
%     end
end

end