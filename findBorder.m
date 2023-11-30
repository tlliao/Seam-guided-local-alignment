function [ border_img ] = findBorder( mask_img )
% give a mask image, find its border, (boundary points)
% border of mask image
[sz1, sz2] = size(mask_img);
mask_R=(mask_img-[mask_img(:,2:end) false(sz1,1)])>0;
mask_L=(mask_img-[false(sz1,1) mask_img(:,1:end-1)])>0;
mask_D=(mask_img-[mask_img(2:end,:);false(1,sz2)])>0;
mask_U=(mask_img-[false(1,sz2);mask_img(1:end-1,:)])>0;
border_img = mask_R | mask_L | mask_D | mask_U;

end

