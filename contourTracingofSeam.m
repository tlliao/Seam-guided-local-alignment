function [ BoundaryPts ] = contourTracingofSeam( mask_seam )
% tracing the image seam of the stitched image，
% B_seam: binary image with only seam mask
% BoundaryPts: contour coordinates [rows, cols]
% the contour points are in white region
    Movement = [0, 1;
                1, 1;
                1, 0;
                1,-1;
                0,-1;
                -1,-1;
                -1, 0;
                -1, 1];
    % //eight directions：1--E, 2--SE, 3--S, 4--SW, 5--W, 6--NW, 7--N, 8--NE
    [sz1,sz2] = size(mask_seam);
    conv_kernel = ones(3,3)./9;
    conv_mask = imfilter(double(mask_seam), conv_kernel);
    conv_mask = conv_mask.*mask_seam;

    [se_row, se_col] = ind2sub([sz1,sz2], find(conv_mask==2/9));

    start_pts = [se_row(1), se_col(1)];
%     end_pts = [se_row(2), se_col(2)];

    max_num = 2*sum(mask_seam(:));
    BoundaryPts = zeros(max_num,2);
    BoundaryPtsNO = 1;
    BoundaryPts(BoundaryPtsNO,1)=start_pts(1);
    BoundaryPts(BoundaryPtsNO,2)=start_pts(2);
    EndFlag = false;
    
    for i=1:8
        tmpi = start_pts(1) + Movement(i,1);
        tmpj = start_pts(2) + Movement(i,2);
        if tmpi>=1 && tmpj>=1 && tmpi<=sz1 && tmpj<=sz2 && mask_seam(tmpi, tmpj)==0
            ClockDireaction = i;
            break;
        end
    end

    %% current version needs revision _by ltl 2022 4/18
    BoundaryPtsNO = BoundaryPtsNO + 1;
    while (~EndFlag)
     for k=0:1:7
        tmpi=BoundaryPts(BoundaryPtsNO-1,1) + Movement(mod(k+ClockDireaction-1,8)+1,1);
        tmpj=BoundaryPts(BoundaryPtsNO-1,2) + Movement(mod(k+ClockDireaction-1,8)+1,2);
        if (tmpi<1 || tmpj<1 || tmpi>sz1 || tmpj>sz2)
            continue;
        end 
        if  mask_seam(tmpi,tmpj)==1   %find the first white point in clockwise in the 8-neighborhood
            break;
        end
     end
        if ismember([tmpi,tmpj],BoundaryPts,'rows')
            break;
        end
        BoundaryPts(BoundaryPtsNO,1) = tmpi;
        BoundaryPts(BoundaryPtsNO,2) = tmpj;
        BoundaryPtsNO = BoundaryPtsNO + 1;
        ClockDireaction = mod(k+ClockDireaction+4,8)+1;
%         if tmpi==end_pts(1) && tmpj==end_pts(2)
%             EndFlag = true;
%         end
        if BoundaryPtsNO>max_num
            fprintf('> Warning! searching number exceeds the max_num in contour tracing, please find the BUG!\n');
            EndFlag = true;
        end
    end
    
    BoundaryPts = BoundaryPts(1:BoundaryPtsNO-1,:);
%     fprintf('Contour tracing finished! total %d pixels traced.\n', BoundaryPtsNO-1);

end
