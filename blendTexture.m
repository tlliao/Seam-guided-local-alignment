function [seam_cut] = blendTexture(warped_img1, warped_img2)

% warped_img1: aligned target image
% warped_img2: aligned reference image
patch_size = 21;

%%  pre-process of seam-cutting
w1 = imfill(imbinarize(rgb2gray(warped_img1), 0),'holes');
w2 = imfill(imbinarize(rgb2gray(warped_img2), 0),'holes');
A = w1;  B = w2;
C = A & B;  % mask of overlapping region
[ sz1, sz2 ]=size(C);
ind = find(C);  % index of overlapping region
nNodes = size(ind,1);
revindC = zeros(sz1*sz2,1);
revindC(C) = 1:length(ind);

%%  terminalWeights, choose source and sink nodes
border_B = findBorder(B);
border_C = findBorder(C);

imgseedA = border_B & border_C;
imgseedB = ~imgseedA & border_C; 

% data term
tw=zeros(nNodes,2);
tw(revindC(imgseedA),1)=inf;
tw(revindC(imgseedB),2)=inf;

terminalWeights=tw;       % data term

%% calculate edgeWeights
CL1=C&[C(:,2:end) false(sz1,1)];
CL2=[false(sz1,1) CL1(:,1:end-1)];
CU1=C&[C(2:end,:);false(1,sz2)];
CU2=[false(1,sz2);CU1(1:end-1,:)];
    
%  edgeWeights:  sigmoid-metric difference map
[imgdif_sig, ~] = calcSigmoidDiff(warped_img1, warped_img2, C);

% sigmoid method
DL = (imgdif_sig(CL1)+imgdif_sig(CL2))./2;
DU = (imgdif_sig(CU1)+imgdif_sig(CU2))./2;        

% smoothness term
edgeWeights=[
    revindC(CL1) revindC(CL2) DL+1e-8 DL+1e-8;
    revindC(CU1) revindC(CU2) DU+1e-8 DU+1e-8];

%%  graph-cut labeling
[~, labels] = graphCutMex(terminalWeights, edgeWeights); 

As=A;
Bs=B;
As(ind(labels==1))=false;   % mask of target seam
Bs(ind(labels==0))=false;   % mask of reference seam
imgout = gradient_blend(warped_img1, As, warped_img2); 
        
SE_seam = strel('diamond', 1);
As_seam = imdilate(As, SE_seam) & A;
Cs_seam = As_seam & Bs;

%%  find potential artifacts along the seam for patch mark

% extract pixels on the seam and evaluate the patch error
seam_pts = contourTracingofSeam(Cs_seam);
[ssim_error, ~, patch_coor] = evalSSIMofSeam(warped_img1, warped_img2, C, seam_pts, patch_size);


% mark misaligned local regions
if max(ssim_error)<=1.5*mean(ssim_error)
    seam_cut=imgout;
    return;
end
T = graythresh(ssim_error);
artifacts_pixels = seam_pts(ssim_error>=T,:);
artifacts_patchs = patch_coor(ssim_error>=T,:);
artifacts_masks = false(sz1,sz2);
mask_pixels = false(sz1,sz2);
for i=1:size(artifacts_patchs,1)
    artifacts_masks(artifacts_patchs(i,1):artifacts_patchs(i,2),artifacts_patchs(i,3):artifacts_patchs(i,4))=1;
    mask_pixels(artifacts_pixels(i,1),artifacts_pixels(i,2))=1;
end

% add modification to artifacts_masks: connect neighboring patches if they
% are close enough
artifacts_masks = imclose(artifacts_masks, strel("square",10));


%% delete photometric misaligned patches, preserve geometric misaligned patches for correspondences insertion
[L,n] = bwlabel(artifacts_masks);
As2 = As;
Bs2 = Bs;
for i=1:n
    tmp_L = L==i;
    [tmpm, tmpn]=ind2sub([sz1,sz2],find(tmp_L));
    s_y = min(tmpm); e_y = max(tmpm);
    s_x = min(tmpn); e_x = max(tmpn);
    crop_img1 = warped_img1(s_y:e_y,s_x:e_x,:);
    crop_img2 = warped_img2(s_y:e_y,s_x:e_x,:);
    s_c_img1 = As(s_y:e_y,s_x:e_x);
    s_c_img2 = Bs(s_y:e_y,s_x:e_x);
    [w_c_img1, w_c_img2]=realignmentviaSIFTflow(crop_img1, crop_img2, s_c_img1);
    [seam_As, seam_Bs] = blendTexture_clean(w_c_img1, w_c_img2, s_c_img1, s_c_img2);
    As2(s_y:e_y,s_x:e_x)=seam_As;
    Bs2(s_y:e_y,s_x:e_x)=seam_Bs;
    warped_img1(s_y:e_y,s_x:e_x,:)=w_c_img1;
    warped_img2(s_y:e_y,s_x:e_x,:)=w_c_img2;       
end

seam_cut = gradient_blend(warped_img1, As2, warped_img2); 

end