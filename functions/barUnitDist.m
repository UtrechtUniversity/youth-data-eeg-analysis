output = bv_summarizeResults('pli5_');
output = output([4 6 1 2 3 5]);

mr_unitwise = cat(1, output.mr_unitwise);
se_unitwise = 2*nanstd(cat(1,output.r_unitwise), [], 2) / sqrt(length(cat(1,output.r_unitwise)));

colors = [0.1 0.1 0.1; 0.25 0.25 0.25; 0.4 0.4 0.4; 0.55 0.55 0.55; 0.7 0.7 0.7; 0.85 0.85 0.85];

figure;
superbar(unitWise75Conn, 'BarFaceColor', [1 1 1], 'BarEdgeColor', colors, ...
    'E', unitWise75ConnSE, 'ErrorBarColor', colors, 'ErrorbarStyle', 'T', ...
    'ErrorbarLineWidth', 2, 'BarLineWidth', 2)
hold on

superbar(unitWiseConn, 'BarFaceColor', colors, 'E', unitWiseConnSE, ...
    'ErrorBarColor', [1 1 1],'ErrorbarLineWidth', 2)
