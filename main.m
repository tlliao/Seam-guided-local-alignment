clear; clc; close all; 
%% Setup VLFeat toolbox.
%----------------------
addNeedingPaths;
run vlfeat-0.9.21/toolbox/vl_setup;

% setup parameters
% Parameters of SIFT detection
parameters.peakthresh = 0;
parameters.edgethresh = 500;

% % Parameters of RANSAC via fundamental matrix
parameters.minPtNum = 4;    % minimal number for model fitting
parameters.iterNum = 2000;  % maximum number of trials
parameters.thDist = 0.01;   % distance threshold for inliers
imgpath = 'Imgs/';

img_format = '1_*.jpg';
dir_folder = dir(strcat(imgpath, img_format));

path1 =  sprintf('%s%s',imgpath, dir_folder(1).name); %
path2 =  sprintf('%s%s',imgpath, dir_folder(2).name); %
img1 = im2double(imread(path1));  % target image
img2 = im2double(imread(path2));  % reference image

%% image alignment
fprintf('> image alignment...');tic;
[pts1, pts2] = siftMatch(img1, img2, parameters);
[matches_1, matches_2] = homoRANSAC(pts1, pts2, parameters);
init_H=calcHomo(matches_1, matches_2);
[warped_img1, warped_img2] = homographyAlign(img1, img2, init_H);
fprintf('done (%fs)\n', toc);

%% image composition
fprintf('> seam cutting...');tic;
[seam_As, seam_Bs]=seamEstimationInSigmoid(warped_img1, warped_img2);
[seam_As2, seam_Bs2, warped_img1, warped_img2] = seamImproving(warped_img1, warped_img2, seam_As, seam_Bs);
[imgout, seam_quality] = seamBlending(warped_img1, warped_img2, seam_As2, seam_Bs2);
fprintf('done (%fs)\n', toc);


