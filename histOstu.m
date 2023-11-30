function [ alpha ] = histOstu(edge_D, interval_rgb)
% use Ostu's method to compute the parameter of logistic function
xbins = 0:interval_rgb:1;
center_bins = 0+interval_rgb/2:interval_rgb:1-interval_rgb/2;
num_x = size(center_bins,2);
counts = histcounts(edge_D, xbins);
%figure,hist(edge_D, xbins);
num = sum(counts);
pro_c = counts./num;
ut_c = pro_c.*center_bins;
sum_ut = sum(ut_c);
energy_max = 0;
threshold = 1;
for k=1:num_x
    uk_c = pro_c(1:k).*center_bins(1:k);
    sum_uk = sum(uk_c);
    sum_wk = sum(pro_c(1:k));

    sigma_c = (sum_uk-sum_ut*sum_wk).^2/(sum_wk*(1-sum_wk));

    if sigma_c>energy_max
        energy_max = sigma_c;
        threshold = k;
    end
end

alpha = center_bins(threshold)+interval_rgb/2;
end