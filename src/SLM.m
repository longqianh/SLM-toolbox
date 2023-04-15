classdef SLM
properties
    height {mustBeInteger}
    width {mustBeInteger}
    depth {mustBeInteger} = 8
    pixel_size
    fresh_time
    init_image
    blaze % should be phase
    LUT
    lambda % LUT wavelength

end
properties (Dependent)
    sz % size
    X
    Y
end

methods (Static)
    function computeLUT(phaseVal,oneLambdaRange,gammaBit,polytype,savePath,verbose)
        arguments
            phaseVal
            oneLambdaRange
            gammaBit
            polytype = 'poly9'
            savePath = 'test.lut'
            verbose = 1
        end

        phaseGT=linspace(0,2*pi,256);
        
        phaseVal_cut=phaseVal(oneLambdaRange)-phaseVal(oneLambdaRange(1));
        
        grayVal=phaseGT/(2*pi)*(2^gammaBit-1);
        grayVal_cut=grayVal(oneLambdaRange);
    
        lutVal=unwrap(phaseVal_cut)/(2*pi)*255;
        ft = fittype( polytype );
        [xData, yData] = prepareCurveData( lutVal, grayVal_cut );
        [lutCurve, ~] = fit( xData, yData, ft );
            
        grayLUT=(0:255)';
        mapLUT=[grayLUT,round(lutCurve(grayLUT))];
        
        if verbose
            figure('Color','White');
            plot(xData,yData,'b.');hold on;
            plot(grayLUT,mapLUT(:,2),'r');
            xlim([0 256]);
            title('Fitted gamma curve (LUT)');

        end
        
        fileID = fopen(savePath,'w+');
        fprintf(fileID,"%d %d\n",mapLUT');
        fclose(fileID);
    end

    function x_lut=funLUT(x,lut)
        % x in (0,2pi)
        if isempty(lut)
%             disp('Use linear LUT.');
            x_lut=x/(2*pi)*255;
        else
%             disp('Use calibrated LUT.');
            ps=unique(fieldnames(lut));
            n=length(ps);
            x_lut=zeros(size(x));
            for i=1:n
                p=lut.(ps(i));
                x_lut=x_lut+p*x.^(n-i);
            end

        end
    end
end

methods (Abstract)
    disp_image(obj,image_in,use_blaze);

end
methods
	function obj = SLM(slm_para)
		obj.height = slm_para.height;
		obj.width = slm_para.width;
        obj.pixel_size = slm_para.pixel_size;

        if isprop(slm_para,'depth')
            obj.depth = slm_para.depth;
        end
        
        if isprop(slm_para,'fresh_time')
            obj.fresh_time=slm_para.fresh_time;
        else
            obj.fresh_time=1; % 1s
        end
        
        obj.init_image = zeros([slm_para.height,slm_para.width],'uint8');
        if isprop(slm_para,'LUT')
            obj.LUT=slm_para.LUT;
        else
            obj.LUT=[];
        end


        if isprop(slm_para,'lambda')
            obj.lambda=slm_para.wavelength;
        else
            obj.lambda=532e-9;
        end
        if isprop(slm_para,'blaze')
            obj.blaze=slm_para.blaze;
        else 
            obj.blaze=[];
        end
    end
	
    function obj=set.LUT(obj,val)
        obj.LUT=val;
    end


    function obj=set.blaze(obj,val)
        obj.blaze=val;
    end
     
    function obj=set.lambda(obj,val)
        obj.lambda = val;
    end

    function obj=set.init_image(obj,val)
        obj.init_image = val;
    end

    function sz=get.sz(obj)
        sz = [obj.height,obj.width];
    end

    function X=get.X(obj)
        x_slm = (-obj.width/2:obj.width/2-1)*obj.pixel_size;  
        y_slm = (-obj.height/2:obj.height/2-1)*obj.pixel_size; 
        [X,~] = meshgrid(x_slm, y_slm);
    end

    function Y=get.Y(obj)
        x_slm = (-obj.width/2:obj.width/2-1)*obj.pixel_size;  
        y_slm = (-obj.height/2:obj.height/2-1)*obj.pixel_size; 
        [~,Y] = meshgrid(x_slm, y_slm);
    end
    
    % -------- DISPLAY --------
    
    function gray_image=lut(obj,phase)
        gray_image=round(obj.funLUT(mod(phase,2*pi),obj.LUT));        
    end
    
    function gray_image=reset_image_lut(obj,image_in)
        % change image from linear lut to calibrated lut 
        gray_image=obj.lut(im2double(image_in)*2*pi);
    end

    function phaseimg=compute_phaseimg(obj,phase,use_blaze)
        arguments
            obj
            phase
            use_blaze = 0;
        end
         
        if use_blaze
            if isempty(obj.blaze)
                disp('no blaze added, set blaze first.');
                phaseimg=phase;
            else
                phaseimg=phase+ModulatorUtil.centercut(obj.blaze,size(phase));
            end
        else
            phaseimg=phase;
        end

        phaseimg=ModulatorUtil.image_padding(phaseimg,obj.sz);
        
        
%         if use_blaze
%             if isempty(obj.blaze)
%                 disp('no blaze added, set blaze first.');
%             else
%                 phaseimg=phaseimg+obj.blaze;
%             end
%         end
        
        phaseimg=obj.lut(phaseimg);
    end

    function disp_phase(obj,phase,use_blaze)
        % phase: [0,2pi]
        phaseimg=obj.compute_phaseimg(phase,use_blaze);
        obj.disp_image(phaseimg,use_blaze);
    end
% 
%     function disp_image_seq(obj,imgs,interval_time)
%         if nargin<3
%             interval_time=obj.fresh_time;
%         end
%         for i=1:length(imgs)
%             disp(['display image: ',num2str(i)]);
%             disp_image(obj,imgs{i});
%             pause(interval_time);
%         end
%         
%     end
% 		
    % -------- HOLOGRAPHY COMPUTATION --------
     
     function img_slm=GS_resample(obj,img,lambda,z,cam_p,mag_img,mag_prop)
        slm_p=obj.pixel_size;
        [h,w]=size(img);
        img_flip=flipud(img); % consider the last lens
        img_mag = imresize(img_flip,mag_img);
        x = (round(-w*mag_img)/2 : round(w*mag_img)/2-1).*cam_p;
        y = (round(-h*mag_img)/2 : round(h*mag_img)/2-1).*cam_p;
        [X_mag,Y_mag]=meshgrid(x,y);
%         dx_im=lambda*z/(obj.width*slm_p)/mag_prop;
        dy_im=lambda*z/(obj.height*slm_p)/mag_prop;
%         Nu = floor(cam_p*(w*mag_img-1)/dx_im); % ?
        Nv = floor(cam_p*(h*mag_img-1)/dy_im); % ?
%         u = (-Nu/2:Nu/2-1)*dx_im;
        v = (-Nv/2:Nv/2-1)*dy_im;
%         lambda*z*(-obj.height/2: dy_im: obj.height/2-1)*slm_p/mag_prop;
        
%         du = lambda*z/(cam_pixel*obj.width)/mag_prop;
%         dv = lambda*z/(cam_pixel*obj.height)/mag_prop;
        [U,V]=meshgrid(v);

        if (w*mag_img*cam_p > dy_im*obj.height)
            fprintf('Warning: Pattern too big!!');
        end

        img_int=interp2(X_mag,Y_mag,img_mag,U,V);
        img_slm = zeros(obj.sz);
       
        loc_u = floor((obj.width-Nv)/2) : floor((obj.width+Nv)/2-1);
        loc_v = floor((obj.height-Nv)/2) : floor((obj.height+Nv)/2-1);
        img_slm(loc_v, loc_u) = img_int;
        img_slm = img_slm - (img_slm<0).*img_slm;% 由于差值带来的小于0的地方补回0
        img_slm = img_slm/max(max(img_slm)); % 插值后归一
    end
        
     function phase=GS(obj,image_in,z,options)
        arguments
            obj
            image_in
            z
            options.iter_num = 100
            options.verbose = 0
        end
    
        % GS phase retrieval for lens imaging
        
        A0 = ones(obj.height, obj.width) .* (obj.X.^2 + obj.Y.^2 <= ((obj.height)/2).^2); % 光束直径限制
        a = sum(sum(A0.^2))/sum(sum(image_in.^2))/(obj.lambda*z).^2; % 能量守恒
    
        img = image_in*sqrt(a);
        phase=rand(obj.sz)*2*pi; % 初始随机相位
        for i = 1:options.iter_num
            Af = A0;
            f0 = Af.*exp(1i.*phase); % 振幅置1保留相位
            g0 = fftshift(fft2(f0)); 
            ang0 = angle(g0); % 取出相位与振幅
            Ampg = img;
            g1=Ampg.*exp(1i.*ang0); % 目标振幅替换，保留相位
            f1=ifft2(fftshift(g1));    
            phase=angle(f1); % Ampf = abs(f1);%取出一次迭代后相位
        end
        phase = phase + pi; % angle返回-pi~pi，转换到0~2pi
        phase = phase.*A0;
        if options.verbose
            figure,imshow(phase,[]);title('phase extracted');
        end
    end

    % -------- FUNCTIONAL PHASE COMPUTATION --------
    function blazedgrating_phase=blazedgrating(obj, Tx, Ty, T)
        % Tx: whether use x direction grating
        % Ty: whether use y direction grating
        if nargin<4
            T=1;
        end
        
        T = T*obj.pixel_size; % 闪耀光栅周期
        blazedgatingX_phase = 2*pi*mod(Tx*obj.X,T)/T;
        blazedgatingY_phase = 2*pi*mod(Ty*obj.Y,T)/T;
        blazedgrating_phase = mod(blazedgatingX_phase+blazedgatingY_phase,2*pi);
    end

    function defocus_phase=defocus(obj,d)  
        y_slm = (-obj.height/2:obj.height/2-1)*obj.pixel_size;
        [X1,Y1] = meshgrid(y_slm, y_slm);
        defocus_phase = pi*d/(obj.lambda*(obj.focal)^2)*(X1.^2+Y1.^2);
        defocus_phase(sqrt(X1.^2+Y1.^2)>=obj.height/2*obj.pixel_size)=0;
        defocus_phase=defocus_phase/(max(defocus_phase,[],'all'))*(2*pi);
    end

   % -------- CALIBRATION
  

   % -------- CONNECTION/COMMUNICATION --------
   % waiting.       
   
end
end
