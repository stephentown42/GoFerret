data = importdata('E:\Data\Behavior\F1504_Kiwi\4_6_2015 level06_SNR_Vis 9_1_Block10-19_RHS log.txt');

col = strcmp(data.colheaders, 'LED_bgrd_V')
%strfind(data.colheaders, 'Spkr_bgrd_V')
bkgnds= data.data(:,col);

SNRs = unique(bkgnds);

bkgnds == SNRs(1);

easyTrials = data.data(bkgrnds==SNRs(1),:);

