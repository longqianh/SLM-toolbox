addpath(genpath('./utils'));
root='../Experiments/20232024/';
name='Diffractive-Cali1';

before_path=[root,'/',name,'/before/'];
if ~exist(before_path,'dir'), mkdirs(before_path); end
after_path=[root,'/',name,'/after/'];
if ~exist(after_path,'dir'), mkdirs(after_path); end

dirname=[root,name];
if ~exist(dirname,'dir'), mkdirs(dirname); end
%% cam
cam_para.ROI=[450 200 200 150];
cam_para.exposure=0.0001;
cam_para.gain=0;
cam_para.trigger_frames=10;
cam_para.frame_rate = 60;
cam_para.frame_delay = 0.1;
cam=Camera(cam_para);

%%
%
lib_dir = './utils/meadowlarkhdmi_sdk/';
lut_path='C:\Program Files\Meadowlark Optics\Blink 1920 HDMI\SDK\19x12_8bit_linearVoltage.lut';
% lut_path=strcat(before_path,'slm1234_at920.lut');
slm_para.height=1200;
slm_para.width=1920;
slm_para.RGB=1;
slm_para.depth=8;
slm_para.pixel_size=9.2e-6; 
slm_para.bCppOrPython=false; 
slm=MeadowlarkHDMISLM(slm_para,lib_dir,lut_path); % 找不到指定的模块。
%

% grating for diffractive calibration
PixelValueOne = 0;
PixelValueTwo = 200;
PixelsPerStripe=8;
WFC = libpointer('uint8Ptr', zeros(prod(slm.sz)*3,1));
img_g_p = libpointer('uint8Ptr', zeros(prod(slm.sz)*3,1));
calllib('ImageGen', 'Generate_Stripe', img_g_p, WFC, slm.width, slm.height, slm.depth, PixelValueOne, 255-PixelValueTwo, PixelsPerStripe, slm.RGB);
grating=reshape(img_g_p.Value,[slm.sz,3]);
slm.blaze=slm.blazedgrating(1,0,32)/(2*pi)*105;

slm.disp_image(slm.init_image,1,1);
% slm.disp_image(grating,0,1);

%%
NumDataPoints = 256;

% If you are generating a global calibration (recommended) the number of regions is 1, 
% if you are generating a regional calibration (typically not necessary) the number of regions is 64
NumRegions = 1;

%allocate an array for our image, and set the wavefront correction to 0 for the LUT calibration process
Image = libpointer('uint8Ptr', zeros(prod(slm.sz)*3,1));
WFC = libpointer('uint8Ptr', zeros(prod(slm.sz)*3,1));

% Create an array to hold measurements from the analog input (AI) board. 
% We ususally use a NI USB 6008 or equivalent analog input board.
AI_Intensities = zeros(NumDataPoints,2);

% When generating a calibration you want to use a linear LUT. If you are checking a calibration


PixelsPerStripe = 2;
%loop through each region
for Region = 0:(NumRegions-1)

    AI_Index = 1;
	%loop through each graylevel
	for Gray = 0:(NumDataPoints-1)
	
		if (slm.height == 1152)
			PixelValueTwo = Gray;
		else
			PixelValueTwo = 255 - Gray;
		end 	
        %Generate the stripe pattern and mask out current region
        calllib('ImageGen', 'Generate_Stripe', Image, WFC, slm.width, slm.height, slm.depth, PixelValueOne, PixelValueTwo, PixelsPerStripe, slm.RGB);
        calllib('ImageGen', 'Mask_Image', Image, slm.width, slm.height, slm.depth, Region, NumRegions, slm.RGB);
            
        grating=reshape(Image.Value,[slm.sz,3]);
        slm.disp_image(grating,1,1);
          
        %let the SLM settle for 40 ms (HDMI card can't load images faster than every 33 ms)
        pause(0.04);
            
        %YOU FILL IN HERE...FIRST: read from your specific AI board, note it might help to clean up noise to average several readings
       img=cam.capture();
       I=sum(img,'all');
       fprintf("Gray: %d, I: %d\n",Gray,I);
        %SECOND: store the measurement in your AI_Intensities array
        AI_Intensities(AI_Index, 1) = Gray; %This is the difference between the reference and variable graysclae for the datapoint
        AI_Intensities(AI_Index, 2) = I; % HERE YOU NEED TO REPLACE 0 with YOUR MEASURED VALUE FROM YOUR ANALOG INPUT BOARD

        AI_Index = AI_Index + 1;
	end
        
	% dump the AI measurements to a csv file
	filename = [before_path,'Raw' num2str(Region) '.csv'];
%     filename = [after_path,'Raw' num2str(Region) '.csv'];
	csvwrite(filename, AI_Intensities);  
end

   
slm.disp_image(slm.init_image,1,1);