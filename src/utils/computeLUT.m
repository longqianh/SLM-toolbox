function computeLUT(phaseVal,one_lambda_range,bit,savePath)
    phaseGT=linspace(0,2*pi,256);
    % computeLUT(phase,16);
    
    phaseVal_cut=phaseVal(one_lambda_range)-phaseVal(one_lambda_range(1));
    
    grayVal=phaseGT/(2*pi)*(2^bit-1);
    grayVal_cut=grayVal(one_lambda_range);

    lutVal=unwrap(phaseVal_cut)/(2*pi)*255;
    ft = fittype( 'poly9' );
    [xData, yData] = prepareCurveData( lutVal, grayVal_cut );
    [lutCurve, ~] = fit( xData, yData, ft );
    
    figure('Color','White');
    plot(lutCurve,'b');
    hold on;
    plot(xData,yData,'r.');
    
    grayLUT=(0:255)';
    mapLUT=[grayLUT,round(lutCurve(grayLUT))];
    figure('Color','White');
    plot(mapLUT)
    
    fileID = fopen(savePath,'w+');
    fprintf(fileID,"%d %d\n",mapLUT');
    fclose(fileID);
end