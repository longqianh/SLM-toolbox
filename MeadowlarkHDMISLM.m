classdef MeadowlarkHDMISLM < SLM
properties
    lib_dir
    RGB  % The RGB parameter is always set to true for the HDMI interface.
end
% properties (Dependent)
%     sz
% end
methods (Static)

    function img_rgb=gray2rgb(img_gray) % encodeRGB
        N=numel(img_gray);
        img_rgb=zeros(3*N,1);
        img_rgb(3*(1:N))=zeros(size(img_gray));
        img_rgb(3*(1:N)-1)=zeros(size(img_gray));
        img_rgb(3*(1:N)-2)=rot90(img_gray);
        img_rgb=reshape(img_rgb,[size(img_gray),3]);
    end

    % BUG here
    function img_gray=rgb2gray(img_rgb) % decodeRGB
        N=size(img_rgb,1)*size(img_rgb,2);
%         img_rgb=reshape(img_rgb,3*N,1);
        img_gray=img_rgb(3*(1:N)-2);
        img_gray=reshape(img_gray,size(img_rgb,1),size(img_rgb,2));
% figure;image(slm.rgb2gray(slm.blaze),'CDataMapping','scaled');
    end

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
        fprintf('LUT loaded from %s.\n',lut_path);
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
%         if slm_para.RGB
%             obj.init_image = zeros([slm_para.height,slm_para.width,3],'uint8');
%         end
% height = calllib('Blink_C_wrapper', 'Get_Height');
% depth = calllib('Blink_C_wrapper', 'Get_Depth');
    end

    function disp_image(obj,image_in,use_blaze,use_padding)
        arguments
            obj
            image_in
            use_blaze (1,1) = true
            use_padding (1,1) = true
%             is_8_bit (1,1) = true % false if use RGB
        end

        if ~isempty(obj.LUT)
            img=obj.reset_image_lut(image_in);
        else
            img=image_in;
        end

        if use_padding
            if obj.RGB && length(size(img))==3
                img_pad=zeros(obj.height,obj.width,3);
                for i=1:3
                    img_pad(:,:,i)=obj.image_padding(squeeze(img(:,:,i)));
                end
            else 
                img_pad=obj.image_padding(img);
            end
        else
            img_pad=img;
        end
        
        if obj.RGB
            is_8_bit=false;
            if length(size(img_pad))==2
                img_pad = obj.gray2rgb(img_pad);
            end
        else
            is_8_bit=true;
        end
        
        if use_blaze
            if isempty(obj.blaze)
                disp('no blaze added, set blaze first.');
                disp_img=img_pad;
            else
                if obj.RGB && length(size(obj.blaze))~=3
                    obj.blaze=obj.gray2rgb(obj.blaze);
                end
                disp_img=double(img_pad)+obj.blaze;
            end
        else 
            disp_img=img_pad;
        end
        disp_img=mod(disp_img,256);
        calllib('Blink_C_wrapper', 'Write_image', mod((disp_img),2^obj.depth), is_8_bit);

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