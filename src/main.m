slm_para.height=1080;
slm_para.width=1920;
slm_para.fresh_time=1/60;
slm_para.pixel_size=8e-6;

slm=DemoSLM(slm_para);
blaze=slm.blazedgrating(1,0,12)*0.87;
slm.blaze=double(blaze);
wf=rand(1000,1000);
menuoff=0;
slm.disp_image(wf,1,menuoff);

%% Set initial image
slm.disp_image(slm.init_image,0);
slm.init_image=rand(slm.sz);
slm.disp_image(slm.init_image,0);