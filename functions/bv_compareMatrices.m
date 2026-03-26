% clear all
% load('gratings_HSF_alpha2.mat')

% halfway = floor(size(Ws,3)/2);
% 
% Ws1 = Ws(:,:,1:halfway);
% Ws2 = Ws(:,:,halfway+1:(halfway+size(Ws1,3)));

Ws1 = Ws(:,:,1:2:end);
Ws2 = Ws(:,:,2:2:end);

W1 = mean(Ws1,3);
W2 = mean(Ws2,3);

W1_plot = W1;
W2_plot = W2;

n = size(W1, 2);
W1_plot(1:n+1:end) = NaN;
W2_plot(1:n+1:end) = NaN;


figure;
subplot(1,2,1); colorbar
imagesc(W1_plot)
set(gca, 'CLim', [min(squareform(W1)) max(squareform(W1))])
set(gca, 'XTick', 1:length(labels), 'XTickLabel', labels)
set(gca, 'YTick', 1:length(labels), 'YTickLabel', labels)
% title('Alpha2 - Social 1')

subplot(1,2,2); colorbar
imagesc(W2_plot)
set(gca, 'CLim', [min(squareform(W2)) max(squareform(W2))])
set(gca, 'XTick', 1:length(labels), 'XTickLabel', labels)
set(gca, 'YTick', 1:length(labels), 'YTickLabel', labels)
% title('Alpha2 - Social 2')

R = correlateMatrices(W1, W2);

figure;
scatter(squareform(W1), squareform(W2))
ylabel('Session 1');
xlabel('Session 2');
title('Coherency Social Task, interleaved')

disp(R)