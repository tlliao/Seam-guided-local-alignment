function [warped_img1, warped_img2] = registerTexture(img1,img2, parameters)
% given two images£¨img1 target£¬ img2 reference£©£¬
% detect and match sift features, estimate homography transformation
% and calculate alignment result

[pts1, pts2] = siftMatch(img1, img2, parameters);

%% image alignment via homography method
[matches_1, matches_2] = homoRANSAC(pts1, pts2, parameters); % delete wrong match features
init_H = calcHomo(matches_1, matches_2);  % fundamental homography
[warped_img1, warped_img2] = homographyAlign(img1, img2,init_H);

% show the feature matches on image matches
% figure,imshow(img1); hold on
% for i=1:length(matches_1)
%     plot(matches_1(1,i),matches_1(2,i),'rx');
%     text(matches_1(1,i),matches_1(2,i),num2str(i));
% end
% hold off
% 
% figure,imshow(img2); hold on
% for i=1:length(matches_2)
%     plot(matches_2(1,i),matches_2(2,i),'ro');
%     text(matches_2(1,i),matches_2(2,i),num2str(i));
% end
% hold off

%% image alignment via apap method
% [matches_1, matches_2] = multiSample_APAP(pts1, pts2);
% [warped_img1, warped_img2] = apapPoint(img1, img2, matches_1, matches_2);

end