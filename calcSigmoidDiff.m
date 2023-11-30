function [ imgdif_sig, imgdif ] = calcSigmoidDiff(img1, img2, C)


%  edgeWeights:  Euclidean-weighted norm
ang_1=img1(:,:,1); sat_1=img1(:,:,2); val_1=img1(:,:,3);
ang_2=img2(:,:,1); sat_2=img2(:,:,2); val_2=img2(:,:,3);
% baseline difference map
imgdif = sqrt( ( (ang_1.*C-ang_2.*C).^2 + (sat_1.*C-sat_2.*C).^2 + (val_1.*C-val_2.*C).^2 )./3 );   

% sigmoid-metric difference map
a_rgb = 0.06; % bin of histogram
beta=4/a_rgb; % beta
gamma=exp(1); % base number
para_alpha = histOstu(imgdif(C), a_rgb);  % parameter:tau
imgdif_sig = 1./(1+power(gamma,beta*(-imgdif+para_alpha))); % difference map with logistic function
imgdif_sig = imgdif_sig.*C;   % difference to compute the smoothness term 

end