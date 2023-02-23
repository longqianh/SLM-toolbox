WFC = libpointer('uint8Ptr', zeros(prod(slm.sz)*3,1));
a1 = libpointer('uint8Ptr', zeros(prod(slm.sz)*3,1));
calllib('ImageGen', 'Generate_Random',a1, WFC, slm.width, slm.height, slm.depth, 1);

% calllib('ImageGen', 'Generate_Solid',a1, WFC, slm.width, slm.height, slm.depth, 123, 1);
% calllib('ImageGen', 'Generate_Stripe', a1, WFC, slm.width, slm.height, slm.depth, PixelValueOne, 255-PixelValueTwo, 64, 1);
a1=reshape(a1.Value,[slm.sz,3]);

WFC1 = libpointer('uint8Ptr', zeros(prod(slm.sz),1));
a2 = libpointer('uint8Ptr', zeros(prod(slm.sz),1));
calllib('ImageGen', 'Generate_Random',a2, WFC, slm.width, slm.height, slm.depth, 0);
% calllib('ImageGen', 'Generate_Solid',a2, WFC1, slm.width, slm.height, slm.depth, 123, 0);
% calllib('ImageGen', 'Generate_Stripe', a2, WFC, slm.width, slm.height, slm.depth, PixelValueOne, 255-PixelValueTwo, 64, 0);
a2=reshape(a2.Value,slm.sz);

a3=slm.gray2rgb(a2);

sum(abs(a3-double(a1)),'all')
