classdef ModulatorUtil

methods(Static)
    function cut_img=centercut(img,sz)
        [h,w]=size(img);
        if (h<sz(1) || w<sz(2))
            cut_img=img;
        else
            hcut=round(h/2-sz(1)/2)+1:round(h/2+sz(1)/2);
            wcut=round(w/2-sz(2)/2)+1:round(w/2+sz(2)/2);
            cut_img=img(hcut,wcut);
        end
    end

    function cut_img=cornercut(img,sz)
        [h,w]=size(img);
        if (h<=sz(1) || w<=sz(2))
            cut_img=img;
        else
            cut_img=img(1:sz(1),1:sz(2));
        end
    end

    function image_out=image_padding(image_in,pad_sz)

         img_sz=size(image_in);
         image_out=zeros(pad_sz);
         h_mid=pad_sz(1)/2; w_mid=pad_sz(2)/2;
         img_h_mid=img_sz(1)/2; img_w_mid=img_sz(2)/2;
         if (img_sz(1)<=pad_sz(1)) && (img_sz(2)<=pad_sz(2))
             image_out(h_mid-img_h_mid+1:h_mid+img_h_mid,w_mid-img_w_mid+1:w_mid+img_w_mid)=image_in;
         end
         if (img_sz(1)<=pad_sz(1)) && (img_sz(2)>pad_sz(2))
             scale=pad_sz(2)/img_sz(2);
             image_resize=imresize(image_in,scale);
             image_out(h_mid-img_h_mid*scale+1:h_mid+img_h_mid*scale,...
                 w_mid-img_w_mid*scale+1:w_mid+img_w_mid*scale)=image_resize;
         end
         if (img_sz(1)>pad_sz(1)) && (img_sz(2)<=pad_sz(2))
             scale=pad_sz(1)/img_sz(1);
             image_resize=imresize(image_in,scale);
             image_out(h_mid-img_h_mid*scale+1:h_mid+img_h_mid*scale,...
                 w_mid-img_w_mid*scale+1:w_mid+img_w_mid*scale)=image_resize;
         end
         if (img_sz(1)>pad_sz(1)) && (img_sz(2)>pad_sz(2))
             scale=min([pad_sz(1)/img_sz(1),pad_sz(2)/img_sz(2)]);
             image_resize=imresize(image_in,scale);
             image_out(h_mid-img_h_mid*scale+1:h_mid+img_h_mid*scale,...
                 w_mid-img_w_mid*scale+1:w_mid+img_w_mid*scale)=image_resize;
         end
    end


    function imgs=load_imgs(dirname,img_index)
    
        imgs=cell(length(img_index),1);
        for i=1:length(img_index)
            % load(fullfile(dirname,[num2str(img_index(i)),'.mat']),img_name);
            % imgs{i}=im2double(img);
            imgs{i} = imread(fullfile(dirname,[num2str(img_index(i)),'.bmp']));
        end
        disp([num2str(length(img_index)),' image loaded.']);
    end

    function gray_imgs=generate_cali_images(img_sz,grayVal,options)
       arguments
           img_sz
           grayVal = 0:255
           options.mode = "double"  
           options.base = 0
       end
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
            elseif options.mode=="double-rev"
                tmp=zeros(img_sz,'double');
                tmp(:,1:round(img_sz(2)/2))=options.base;
                tmp(:,round(img_sz(2)/2)+1:end)=grayVal(i);
                gray_imgs{i}=tmp;
            end
        end
   end
end

end