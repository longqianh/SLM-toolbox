classdef MeadowlarkSLM < SLM
properties
    lib_dir
    lut_loaded
    board_number (1,1) int8 = 1
    bit_depth (1,1) int8 = 12
    is_nematic_type (1,1) = 1;
    RAM_write_enable (1,1) = 1;
    use_GPU (1,1) = 0;
    max_transients (1,1) = 10;
end

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

    function load_lut(board_number,lut_path)
        calllib('Blink_C_wrapper','Load_LUT_file',board_number, lut_path);
        fprintf('LUT loaded from %s. LUT loading should not be called twice!\n',lut_path);
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
    function obj=MeadowlarkSLM(slm_para,lib_dir,lut_path)
        obj=obj@SLM(slm_para);
        obj.lib_dir=lib_dir; 
        obj.bit_depth = slm_para.bit_depth;
        obj.is_nematic_type = slm_para.is_nematic_type;
        obj.RAM_write_enable = slm_para.RAM_write_enable;
        obj.use_GPU = slm_para.use_GPU;
        obj.max_transients = slm_para.max_transients;

        obj.load_libs(lib_dir);
        ret=construct_sdk(obj);
        if ret, obj.board_number=1; end
        obj.load_lut(obj.board_number,lut_path);

    end
    
    function ret=construct_sdk(obj)
    
        num_boards_found = libpointer('uint32Ptr', 0);
        constructed_okay = libpointer('int32Ptr', 0);
        reg_lut = libpointer('string');

        % Call the constructor
        calllib('Blink_C_wrapper', 'Create_SDK', obj.bit_depth,...
            num_boards_found, constructed_okay,...
            obj.is_nematic_type, obj.RAM_write_enable,...
            obj.use_GPU, obj.max_transients, reg_lut);
        
        if constructed_okay.value ~= 0  
            disp('Blink SDK was not successfully constructed');
            disp(calllib('Blink_C_wrapper', 'Get_last_error_message'));
            calllib('Blink_C_wrapper', 'Delete_SDK');
        else
            disp('Blink SDK was successfully constructed');
            fprintf('Found %u SLM controller(s)\n', num_boards_found.value);
        end
        ret=constructed_okay.value;
    end

    function obj=set.lut_loaded(obj,val)
        obj.lut_loaded=val;
    end

    function obj=set.board_number(obj,val)
        obj.board_number=val;
    end

    function disp_image(obj,image_in,use_blaze,use_padding,options)
        arguments
            obj
            image_in
            use_blaze (1,1) boolean = true
            use_padding (1,1) boolean = true
            options.wait_for_trigger (1,1) boolean = false
            options.external_pulse (1,1) boolean = false
            options.timout_ms (1,1) double = 5000
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
       
        calllib('Blink_C_wrapper', 'Write_image', obj.board_number,...
            rot90(disp_img), prod(obj.sz), options.wait_for_trigger, options.external_pulse, options.timeout_ms);
        calllib('Blink_C_wrapper', 'ImageWriteComplete', obj.board_number, options.timeout_ms); 
        disp('Image displayed on Meadowlark SLM.');
    end

end

end