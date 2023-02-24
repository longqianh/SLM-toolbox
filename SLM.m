classdef SLM
properties
    height {mustBeInteger}
    width {mustBeInteger}
    depth {mustBeInteger} = 8
    pixel_size
    fresh_time
    init_image
    blaze
    LUT

end
properties (Dependent)
    sz % size
    X
    Y
end

methods (Static)
    function x_lut=funLUT(x,lut)
        % x in (0,2pi)
        if isempty(lut)
            disp('Use linear LUT.');
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
    disp_image(obj,image_in,use_blaze,use_padding);

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
        gray_image=obj.lut(double(image_in)/255*2*pi);
    end

    function image_out=image_padding(obj,image_in)
         img_sz=size(image_in);
         image_out=zeros(obj.height,obj.width);
         h_mid=obj.height/2; w_mid=obj.width/2;
         img_h_mid=img_sz(1)/2; img_w_mid=img_sz(2)/2;
         if (img_sz(1)<=obj.height) && (img_sz(2)<=obj.width)
             image_out(h_mid-img_h_mid+1:h_mid+img_h_mid,w_mid-img_w_mid+1:w_mid+img_w_mid)=image_in;
         end
         if (img_sz(1)<=obj.height) && (img_sz(2)>obj.width)
             scale=obj.width/img_sz(2);
             image_resize=imresize(image_in,scale);
             image_out(h_mid-img_h_mid*scale+1:h_mid+img_h_mid*scale,...
                 w_mid-img_w_mid*scale+1:w_mid+img_w_mid*scale)=image_resize;
         end
         if (img_sz(1)>obj.height) && (img_sz(2)<=obj.width)
             scale=obj.height/img_sz(1);
             image_resize=imresize(image_in,scale);
             image_out(h_mid-img_h_mid*scale+1:h_mid+img_h_mid*scale,...
                 w_mid-img_w_mid*scale+1:w_mid+img_w_mid*scale)=image_resize;
         end
         if (img_sz(1)>obj.height) && (img_sz(2)>obj.width)
             scale=min([obj.height/img_sz(1),obj.width/img_sz(2)]);
             image_resize=imresize(image_in,scale);
             image_out(h_mid-img_h_mid*scale+1:h_mid+img_h_mid*scale,...
                 w_mid-img_w_mid*scale+1:w_mid+img_w_mid*scale)=image_resize;
         end
    end

    
    function disp_phase(obj,phase,use_blaze,use_padding)
        % phase: [0,2pi]
        if nargin<3
            use_blaze=0;
        end
        if nargin<4
            use_padding=0;
        end
        img=obj.lut(phase);
        obj.disp_image(img,use_blaze,use_padding,1);
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

     function image_out=image_resample(obj,image_in,mag,sys_para)
        % image resample for GS
        arguments
            obj
            image_in
            mag
            sys_para.lambda 
            sys_para.cam_pixel_size
            sys_para.mag_prop
            sys_para.focal
        end
        % mag_prop: magnification between SLM and obj-lens back focal plane

        N=obj.height;
        target =rot90(image_in,2); % fliplr(flipud())
        if length(size(target))==3
            target=squeeze(mean(target,3));
        end
        [h,w] = size(target) ;
        L = max(h,w); 
        L_mag=L*mag;
%         target = imresize(target,[L_mag,L_mag]);
        
%         h = L_mag; w = L_mag;
        target2 = zeros(h,w);
        target3 = imresize(target,[floor(h*mag) floor(w*mag)]);
        target2((h-floor(h*mag))/2+1:(h+floor(h*mag))/2,(w-floor(w*mag))/2+1:(w+floor(w*mag))/2) = target3;
        target = target2;

        % 重采样，用像面坐标x_im重新描述图样
        dx_im = sys_para.lambda*sys_para.focal/(obj.pixel_size*N)/sys_para.mag_prop;
        
        xc2 = ceil(-L_mag/2 : L_mag/2-1).*sys_para.cam_pixel_size;
        [Xc2, Yc2] = meshgrid(xc2); %-1 保持边界一致
        
        Nc = floor(obj.cam_pixel_size*(L_mag-1)/dx_im);
        x_imt = ceil(-Nc/2 : Nc/2-1)*dx_im;
        [X_imT, Y_imT] = meshgrid(x_imt); % Nc缩小一些,x_imt边界不能大于xc2，否则NaN
        
        if L_mag*obj.cam_pixel_size > dx_im*N
            fprintf('Warning: Pattern too big!!');
        end
        
        target = interp2(Xc2,Yc2,target,X_imT,Y_imT,'cubic');
        image_out = zeros(obj.height,obj.width);
        loc_h = floor((obj.height-Nc)/2+1) : floor((obj.height+Nc)/2);
        loc_w = floor((obj.width-Nc)/2+1) : floor((obj.width+Nc)/2);
        image_out(loc_h, loc_w) = target;
        image_out = image_out - (image_out<0).*image_out;% 由于差值带来的小于0的地方补回0
        image_out = image_out/max(max(image_out)); % 插值后归一

     end

    function phase=GS(obj,image_in,iter_num,verbose)

        if nargin<3
            iter_num=100;
        end
        if nargin<4
            verbose=0;
        end
        % GS phase retrieval for lens imaging
        
        A0 = ones(obj.height, obj.width) .* (obj.X.^2 + obj.Y.^2 <= ((obj.height)/2).^2); % 光束直径限制
        
        a = sum(sum(A0.^2))/sum(sum(image_in.^2))/(obj.lambda*obj.focal).^2; % 能量守恒
        image_in = image_in*sqrt(a);

        phase=rand(obj.height,obj.width)*2*pi; % 初始随机相位
        for i = 1:iter_num
            Af = A0;
            f0 = Af.*exp(1i.*phase); % 振幅置1保留相位
            g0 = fftshift(fft2(f0)); 
            ang0 = angle(g0); % 取出相位与振幅
            Ampg = image_in;
            g1=Ampg.*exp(1i.*ang0); % 目标振幅替换，保留相位
            f1=ifft2(fftshift(g1));    
            phase=angle(f1); % Ampf = abs(f1);%取出一次迭代后相位
        end
        phase = phase + pi; % angle返回-pi~pi，转换到0~2pi
        phase = phase.*A0;
        if verbose
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
   function gray_imgs=cali_genimgs(obj,grayVal,options)
       arguments
           obj
           grayVal = 0:2^obj.depth-1
           options.mode = "double"  
           options.base = 0
           options.sz
       end
       if isprop(options,'sz'), img_sz=options.sz; else, img_sz=obj.sz; end
       n=length(grayVal);
       gray_imgs=cell(n,1);
       for i=1:n
            if options.mode=="whole"
                gray_imgs{i}=grayVal(i)*ones(img_sz,'double');
            elseif options.mode=="double"
                tmp=zeros(img_sz,'double');
                tmp(:,1:round(img_sz(2)/2))=grayVal(i);
                tmp(:,round(img_sz(2)/2)+1:end)=options.base;
                gray_imgs{i}=tmp;
            end
        end
   end

   % -------- CONNECTION/COMMUNICATION --------
   % waiting.       
   
end
end
