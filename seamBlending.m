function [imgout, seam_quality] = seamBlending(warped_img1, warped_img2, seam_As, seam_Bs)

% warped_img1: aligned target image
% warped_img2: aligned reference image
% seam_As: seam mask in warped_img1
% seam_Bs: seam mask in warped_img2
patchsize=21;
%% seam quality estimation
w1 = imfill(imbinarize(rgb2gray(warped_img1), 0),'holes');
w2 = imfill(imbinarize(rgb2gray(warped_img2), 0),'holes');
A = w1;  B = w2;
C = A & B;  % mask of overlapping region
SE_seam = strel('diamond', 1);
As_seam = imdilate(seam_As, SE_seam) & A;
Cs_seam = As_seam & seam_Bs;
[seam_ptsy,seam_ptsx] = ind2sub([size(C,1),size(C,2)], find(Cs_seam));
seam_quality=zeros(size(seam_ptsy,1),3);  % psnr, ssim, zncc indices
for i=1:size(seam_ptsy,1)
    i_bound = seam_ptsy(i);
    j_bound = seam_ptsx(i);

    y1 = max(i_bound-(patchsize-1)/2, 1);
    y2 = min(i_bound+(patchsize-1)/2, size(warped_img1,1));
    x1 = max(j_bound-(patchsize-1)/2, 1);
    x2 = min(j_bound+(patchsize-1)/2, size(warped_img1,2));
    patch_mask = C(y1:y2,x1:x2);
    
    img1_crop = warped_img1(y1:y2,x1:x2,:).*cat(3,patch_mask,patch_mask,patch_mask);
    img2_crop = warped_img2(y1:y2,x1:x2,:).*cat(3,patch_mask,patch_mask,patch_mask);

    % SSIM
    ssim_error1 = ssim(img1_crop(:,:,1), img2_crop(:,:,1));
    ssim_error2 = ssim(img1_crop(:,:,2), img2_crop(:,:,2));
    ssim_error3 = ssim(img1_crop(:,:,3), img2_crop(:,:,3));

    % ZNCC
    mu1=mean(img1_crop(:));
    mu2=mean(img2_crop(:));
    sigma1=std(img1_crop(:));
    sigma2=std(img2_crop(:));

    seam_quality(i,1) = psnr(img1_crop,img2_crop);                 %% PSNR
    seam_quality(i,2) = (ssim_error1 + ssim_error2 +ssim_error3)/3;  %% SSIM
    seam_quality(i,3) = (1-mean((img1_crop(:)-mu1).*(img2_crop(:)-mu2)./(sigma1*sigma2),'all'))/2;  %% ZNCC
    
end

seam_quality=mean(seam_quality,1);
seam_quality = [mean(sum((img1_crop-img2_crop).^2,3),'all'), seam_quality]; %%add RMSE

%% image composition via seam-cutting
% imgout = warped_img1.*cat(3,seam_As,seam_As,seam_As) + warped_img2.*cat(3,seam_Bs,seam_Bs,seam_Bs); % without gradient domain blending
imgout = gradient_blend(warped_img1, seam_As, warped_img2); % with gradient domain blending

end