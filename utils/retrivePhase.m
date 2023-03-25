function phase=retrivePhase(imgs,yRange,xRange,startPoint,savePath,debug)
    if nargin<5
        verbose=0;
    else
        verbose=1;
    end
    if nargin<6
        debug=0;
    end
 
    clc;close all;
    img=imgs{1};
    ySLM = mean(double(img(yRange,xRange)),1);
    ySLM=smoothdata(ySLM);
    xSLM= 1:length(ySLM);
    y0=yRange(round(length(yRange)/2));

    [xData, yData] = prepareCurveData( xSLM, ySLM );
    % Set up fittype and options.
    ft = fittype( 'fourier1' );
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    opts.Display = 'Off';
    opts.StartPoint = startPoint;

    % Fit model to data.
    [fitresult, ~] = fit( xData, yData, ft, opts );
%     plot(fitresult);hold on;plot(ySLM) % check quality
    startPoint=[fitresult.a0, fitresult.a1, fitresult.b1, fitresult.w];
    if verbose
        figure('Color','White');
%         imshow(img,[]);
        image(img,'CDataMapping','scaled');
        line([1 size(img,2)],[y0 y0],'Color','cyan');
%         print([path,'/slm_cali_strip'],'-dpng','-r400');
        figure('Color','White');
        plot(xData,yData,'b');hold on;
        plot(fitresult);
        legend('original curve','fitted curve');
        xlabel('横坐标位置');ylabel('归一化强度');
%         print([path,'/slm_cali_strip_curve'],'-dpng','-r400');
    end
    
    phase=zeros(length(imgs),1);
    
    if debug
        figure('Color','White');
        ySLM0=ySLM;
    end
    for i=1:length(imgs)
        disp(['index: ',num2str(i)]);
        img=imgs{i};
        % Phase retrival
        ySLM=mean(img(yRange,xRange),1);
        
        ySLM=smoothdata(ySLM);
        phase(i)=calPhase(xSLM,ySLM,startPoint);

        if debug
            if i>1
                phi=phase(i)-phase(1);
            elseif i==1
                phi=0;
            end
            plot(ySLM0,'r');hold on;
            plot(ySLM,'b');title(num2str(phi));hold off;
            pause(0.3);
        end
    end
        
    if verbose
       show_phase_shift(imgs,y0,savePath);
    end
    
    phase=phase-phase(1);
    phase(1)=0;
    
end

function phase=calPhase(xSLM,ySLM,startPoint,verbose)
% a0+a1*cos(w*x)+b1*sin(w*x)
%     if w==0
%         ft = fittype( 'fourier1' );
%     else
%         ft= @(a0,a1,b1,x) a0+a1*cos(w*x)+b1*sin(x);
%     end
    
    if nargin<4 
        verbose=0;
    end
    [xData, yData] = prepareCurveData( xSLM, ySLM );

    % Set up fittype and options.
    ft = fittype( 'fourier1' );
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    opts.Display = 'Off';
    opts.StartPoint = startPoint; 

    % Fit model to data.
    [fitresult, ~] = fit( xData, yData, ft, opts );
    if verbose
        fitresult.w
    end
    phase=acos(fitresult.a1/sqrt(fitresult.a1^2+fitresult.b1^2));
    
%     phase=atan(fitresult.b1/fitresult.a1);
    if fitresult.b1>0
        phase=2*pi-phase;
    end
%     elseif fitresult.b1<0 && fitresult.a1>0
%         phase=phase+2*pi;
%     end
%     if fitresult.b1<0
%         phase=phase+pi;
%     end
    if verbose
        plot(fitresult);hold on;plot(ySLM);
        pause(2);
        close all;
    end
end


function show_phase_shift(imgs,y0,savepath)
    if nargin<3
        savepath='';
    end

    anchor=imgs{1};
    if nargin<2
        y0=round(size(anchor,1)/2);
    end

    nData=length(imgs);
    fig=figure('Color','White');
    m=moviein(nData);
    writerObj = VideoWriter([savepath,'/shiftvedio.avi']);
    open(writerObj);
    cmp=zeros(size(anchor));
    cmp(1:y0,:)=anchor(1:y0,:);
    for i=1:nData
        disp(i);
        img=imgs{i};
        cmp(y0+1:end,:)=img(y0+1:end,:);
%         imshow(cmp,[]);
        image(cmp,'CDataMapping','scaled'); % when imshow failed
        m(i+1)=getframe(fig);
%         pause(0.1)
        writeVideo(writerObj,m(i+1));
    end
    close(writerObj);
end