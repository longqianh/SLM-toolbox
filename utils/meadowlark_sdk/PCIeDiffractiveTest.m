%% initialize SLM
clc;clear;close all;
lib_dir = './utils/meadowlark_sdk/';
slm_para.height=1152;
slm_para.width=1920;
slm_para.fresh_time=1.18e-3;
slm_para.pixel_size=9.2e-6;
slm_para.bit_depth = 12;
slm_para.is_nematic_type = 1;
slm_para.RAM_write_enable = 1;
slm_para.use_GPU = 0;
slm_para.max_transients  = 10;
% lut_path=strcat(lib_dir,'linear.lut');
lut_path='./output/slm4633_at532.lut';
slm=MeadowlarkSLM(slm_para,lib_dir,lut_path); 
slm.disp_image(slm.init_image,0,0);
%%
% slm.blaze=slm.blazedgrating(1,0,4)/(2*pi)*255;
PixelValue = 0;
PixelsPerStripe = 4;
Image=libpointer('uint8Ptr', zeros(prod(slm.sz),1));
Gray=120; 
calllib('ImageGen', 'Generate_Stripe', Image, slm.width, slm.height, 0, Gray, PixelsPerStripe);
Image=reshape(Image.Value,slm.sz);
slm.disp_image(Image,0,1);

%% initialize camera
cam_para.ROI=[220 100 100 100];
cam_para.exposure=0.0015;
cam_para.gain=0;
cam_para.trigger_frames=10;
cam_para.frame_rate = 90;
cam_para.frame_delay = 0.1;
cam=Camera(cam_para);

%%  
%set some dimensions
NumDataPoints = 256;
NumRegions = 1;
    
%allocate arrays for our images
Image = libpointer('uint8Ptr', zeros(prod(slm.sz),1));

% Create an array to hold measurements from the analog input (AI) board
AI_Intensities = zeros(NumDataPoints,2);

% Generate a blank wavefront correction image, you should load your
% custom wavefront correction that was shipped with your SLM.

calllib('ImageGen', 'Generate_Solid', Image, slm.width, slm.height, PixelValue);
calllib('Blink_C_wrapper', 'Write _image', slm.board_number, Image, prod(slm.sz), 0, 0, 5000);
calllib('Blink_C_wrapper', 'ImageWriteComplete', slm.board_number, 5000);

%loop through each region
for Region = 0:(NumRegions-1)
  
    AI_Index = 1;
    %loop through each graylevel
    for Gray = 0:(NumDataPoints-1)
        %Generate the stripe pattern and mask out current region
        calllib('ImageGen', 'Generate_Stripe', Image, slm.width, slm.height, PixelValue, Gray, PixelsPerStripe);
        calllib('ImageGen', 'Mask_Image', Image, slm.width, slm.height, Region, NumRegions);
        img=reshape(Image.Value,slm.sz);
%         figure('Color','White');
%         imshow(img,[]);
        %write the image
        slm.disp_image(img,0,0);
%         calllib('Blink_C_wrapper', 'Write_image', slm.board_number, Image, prod(slm.sz), slm.wait_for_trigger, slm.external_pulse, slm.timeout_ms);
%         calllib('Blink_C_wrapper', 'Write_image', slm.board_number, Image, prod(slm.sz), 0, 0, 5000);
        
        %let the SLM settle for 10 ms
        pause(0.01);
        
        %YOU FILL IN HERE...FIRST: read from your specific AI board, note it might help to clean up noise to average several readings
        img=cam.capture();
        I=sum(img,"all");
        fprintf("Gray %d: %f\n",Gray,I);
%         plot(Gray,I);hold on;
        %SECOND: store the measurement in your AI_Intensities array
        AI_Intensities(AI_Index, 1) = Gray; %This is the varable graylevel you wrote to collect this data point
        AI_Intensities(AI_Index, 2) = I; % HERE YOU NEED TO REPLACE 0 with YOUR MEASURED VALUE FROM YOUR ANALOG INPUT BOARD

        AI_Index = AI_Index + 1;
        
    end
        
    % dump the AI measurements to a csv file
    filename = ['./output/Raw' num2str(Region) '.csv'];
    csvwrite(filename, AI_Intensities);  
end

figure('Color','White');
plot(AI_Intensities(:,2));

%% clear sdk
slm.clear_sdk();
