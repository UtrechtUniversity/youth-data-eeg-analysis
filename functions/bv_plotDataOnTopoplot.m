function hout = bv_plotDataOnTopoplot(Ws, lay, propThr, globNorm, weighted, color, subplotlabels)

% defaultHeight = 1;
% defaultUnits = 'inches';
% defaultShape = 'rectangle';
% expectedShapes = {'square','rectangle','parallelogram'};
% 
% p = inputParser;
% validScalarPosNum = @(x) isnumeric(x) && isscalar(x) && (x > 0);
% addRequired(p,'Ws',validScalarPosNum);
% addRequired(p,'lay',validScalarPosNum);
% 
% addOptional(p,'height',defaultHeight,validScalarPosNum);
% addParameter(p,'units',defaultUnits,@isstring);
% addParameter(p,'shape',defaultShape,...
%     @(x) any(validatestring(x,expectedShapes)));
% parse(p,width,varargin{:});
% 
% a = p.Results.width*p.Results.height;

if nargin < 4
    globNorm = false;
end
if nargin < 5
    weighted = true;
end
if nargin < 6
    color = [0 0 0];
end
if nargin < 7
    subplotlabels = '';
end

if ischar(color)
    cmap = color;
else
    cmap = 'plasma';
end

if nargin < 1
    error('Input variable W not given')
end
if nargin < 2
    error('Input variable labels not given')
end
if nargin < 3 || isempty(propThr)
    doThresh = 0;
else
    doThresh = 1;
end

if weighted && globNorm
    I = find(Ws);
    
    absWs = abs(Ws);
    
    widthRange = [0.1 4];
    normdataWidth = zeros(size(absWs));
    widthNrmA = (widthRange(2)-widthRange(1))/(max(absWs(I))-min(absWs(I)));
    widthNrmB = widthRange(2) - widthNrmA * max(absWs(I));
    normdataWidth(I) = widthNrmA * absWs(I) + widthNrmB;
    
    alphaRange = [0.2 0.7];
    normdataAlpha = zeros(size(absWs));
    alphaNrmA = (alphaRange(2)-alphaRange(1))/(max(absWs(I))-min(absWs(I)));
    alphaNrmB = alphaRange(2) - alphaNrmA * max(absWs(I));
    normdataAlpha(I) = alphaNrmA * absWs(I) + alphaNrmB;
    rng = [min(absWs(I)) max(absWs(I))];
    nrmWs = abs(Ws ./ max(abs(Ws(:))));
end

% figure;
for currW = 1:size(Ws,3)

    W = squeeze(Ws(:,:,currW));
    W(isnan(W)) = 0;
    
    if doThresh
        W = bv_thresholdMultipleWs(W, propThr);
    end
    
    if weighted && ~globNorm
        I = find(W);
        absW = abs(W);
        widthRange = [0.1 2];
        alphaRange = [1 1];
        
        
        if length(I) == 1
            normdataWidth = zeros(size(absW));
            normdataAlpha = zeros(size(absW));
            normdataWidth(I) = nanmean(widthRange);
            normdataAlpha(I) = nanmean(alphaRange);
            
        elseif length(unique(abs(W(I)))) == 1
            normdataWidth = zeros(size(absW));
            normdataAlpha = zeros(size(absW));
            normdataWidth(I) = 2;
            normdataAlpha(I) = max(alphaRange);
            
        else
            normdataWidth = zeros(size(absW ));
            widthNrmA = (widthRange(2)-widthRange(1))/(max(absW(I))-min(absW(I)));
            widthNrmB = widthRange(2) - widthNrmA * max(absW(I));
            normdataWidth(I) = widthNrmA * absW(I) + widthNrmB;
            
            normdataAlpha = zeros(size(absW));
            alphaNrmA = (alphaRange(2)-alphaRange(1))/(max(absW(I))-min(absW(I)));
            alphaNrmB = alphaRange(2) - alphaNrmA * max(absW(I));
            normdataAlpha(I) = alphaNrmA * absW(I) + alphaNrmB;
        end
        nrmW = abs(W ./ max(W(:)));
    end
    
    if size(Ws,3) > 1 
        [subplotindx] = numSubplots(size(Ws,3));
        subplot(subplotindx(1), subplotindx(2), currW)
        cla;
        
    end
    
    fprintf('creating topoplot %s...', num2str(currW))
    hold on
    
    if nansum(W(:))~=0
        counter = 0;
        for i = 1:size(W,1)
            for j = 1:size(W,2)
                if W(i,j)==0
                    continue
                    %                 elseif j > i
                    %                     continue
                end
                
                counter = counter + 1;
                
                if i==j
                    radius = 0.025;
                    center = [lay.pos(i,1), (lay.pos(i,2) + radius)];
                    if ~weighted
                        circular_arrow(radius, center, color, 3, 1, false);
                    elseif globNorm
                        circular_arrow(radius, center, W(i,j)*[1], ...
                            normdataWidth(i,j,currW), normdataAlpha(i,j,currW), true);
                    else
                        circular_arrow(radius, center, W(i,j)*[1], ...
                            normdataWidth(i,j), normdataAlpha(i,j), true);
                    end
                else
                    
                    x = lay.pos([i j],1);
                    y = lay.pos([i j],2);
                    
                    if ~weighted
                        h(counter) = patch('xdata', x, 'ydata', y, 'Edgecolor', color, 'LineWidth', 3, 'edgealpha', 0.1);
                    elseif globNorm
                        h(counter) = patch(x,y, W(i,j)*[1 1], 'edgecolor',...
                            'flat','linewidth', normdataWidth(i,j,currW), 'edgealpha', ...
                            normdataAlpha(i,j,currW));
                    else
                        h(counter) = patch(x,y, W(i,j)*[1 1], 'edgecolor',...
                            'flat','linewidth', normdataWidth(i,j), 'edgealpha', ...
                            normdataAlpha(i,j));                        
                    end
                end
            end
        end
        
    end
    
    if weighted
        if isfolder('~/MatlabToolboxes/Colormaps/')
            addpath('~/MatlabToolboxes/Colormaps/')
            addpath('~/MatlabToolboxes/OwnColormaps/')
            colormap(cmap)
        end
    end
    
%     scatter(lay.pos(:,1), lay.pos(:,2), (sum(W)+1/10)*20', 'MarkerFaceColor', 'k', ...
%         'MarkerFaceAlpha', 0.7, 'MarkerEdgeAlpha', 0.2)
    scatter(lay.pos(:,1), lay.pos(:,2), (sum(W)+1/10)*10', ...
        'MarkerFaceColor', [.5 .5 .5], ...
        'MarkerEdgeColor', [.5 .5 .5])
    line(lay.outline{1}(:,1), lay.outline{1}(:,2), 'LineWidth', 3, 'color', ...
        [0.5 0.5 0.5])
    
    if not(isempty(subplotlabels))
        title(subplotlabels{currW})
    end
    axis equal
    axis off
    if globNorm
        set(gca, 'CLim', rng)
    end
    if weighted
        colorbar
    end
    fprintf('done \n')
    
end

function circular_arrow(radius, centre, colour, linewidth, edgealpha, weighted)
% Adapted from: https://nl.mathworks.com/matlabcentral/fileexchange/59917-circular_arrow
% This is a function designed to draw a circular arrow onto the current
% figure. It is required that "hold on" must be called before calling this
% function.
%
% The correct calling syntax is:
%   circular_arrow(height, centre, angle, direction, colour, head_size)
%   where:
%       radius - the radius of the arrow.
%       centre - a vector containing the desired centre of the circular
%                   arrow.
%       colour (optional) - the desired colour of the arrow, using Matlab's
%                   <a href="matlab:
%                   web('https://au.mathworks.com/help/matlab/ref/colorspec.html')">Color Specification</a>.
%       linewidth - the desired linewidth of the line

% correct imputs for circular arrow
arrow_angle = 90;
angle = 240;
direction = 2;
head_style = 'vback2';
head_size = 6;
edgealpha = 0.3;
if nargin < 6
    weighted = true;
end

% Check centre is vector with two points
[m,n] = size(centre);
if m*n ~= 2
    error('Centre must be a two element vector');
end

arrow_angle = deg2rad(arrow_angle); % Convert angle to rad
angle = deg2rad(angle); % Convert angle to rad
xc = centre(1);
yc = centre(2);

% Creating (x, y) values that are in the positive direction along the x
% axis and the same height as the centre
x_temp = centre(1) + radius;
y_temp = centre(2);

% Creating x & y values for the start and end points of arc
x1 = (x_temp-xc)*cos(arrow_angle+angle/2) - ...
    (y_temp-yc)*sin(arrow_angle+angle/2) + xc;
x2 = (x_temp-xc)*cos(arrow_angle-angle/2) - ...
    (y_temp-yc)*sin(arrow_angle-angle/2) + xc;
x0 = (x_temp-xc)*cos(arrow_angle) - ...
    (y_temp-yc)*sin(arrow_angle) + xc;
y1 = (x_temp-xc)*sin(arrow_angle+angle/2) + ...
    (y_temp-yc)*cos(arrow_angle+angle/2) + yc;
y2 = (x_temp-xc)*sin(arrow_angle-angle/2) + ...
    (y_temp-yc)*cos(arrow_angle-angle/2) + yc;
y0 = (x_temp-xc)*sin(arrow_angle) + ...
    (y_temp-yc)*cos(arrow_angle) + yc;

% Plotting twice to get angles greater than 180
i = 1;

% Creating points
P1 = struct([]);
P2 = struct([]);
P1{1} = [x1;y1]; % Point 1 - 1
P1{2} = [x2;y2]; % Point 1 - 2
P2{1} = [x0;y0]; % Point 2 - 1
P2{2} = [x0;y0]; % Point 2 - 1
centre = [xc;yc]; % guarenteeing centre is the right dimension
n = 20; % The number of points in the arc
v = struct([]);

while i < 3
    
    v1 = P1{i}-centre;
    v2 = P2{i}-centre;
    c = det([v1,v2]); % "cross product" of v1 and v2
    a = linspace(0,atan2(abs(c),dot(v1,v2)),n); % Angle range
    v3 = [0,-c;c,0]*v1; % v3 lies in plane of v1 and v2 and is orthog. to v1
    v{i} = v1*cos(a)+((norm(v1)/norm(v3))*v3)*sin(a); % Arc, center at (0,0)
    v_tmp(:,1) = v{i}(1,:)+xc;
    v_tmp(:,2) = v{i}(2,:)+yc;
    if weighted
        h_patch = patch([v_tmp(:,1); NaN], [v_tmp(:,2); NaN], repmat(colour,1,length(v_tmp)+1), ...
            'EdgeColor', 'flat', 'FaceColor', 'none', 'linewidth',linewidth, 'edgealpha', edgealpha);
    else
        plot(v{i}(1,:)+xc,v{i}(2,:)+yc,'Color', colour, 'LineWidth',3) % Plot arc, centered at P0
    end
    i = i + 1;
    
end

position = struct([]);

% Setting x and y for CW and CCW arrows
if direction == 1
    position{1} = [x2 y2 x2-(v{2}(1,2)+xc) y2-(v{2}(2,2)+yc)];
elseif direction == -1
    position{1} = [x1 y1 x1-(v{1}(1,2)+xc) y1-(v{1}(2,2)+yc)];
elseif direction == 2
    position{1} = [x2-0.001 y2-0.0005 x2-(v{2}(1,2)+xc) y2-(v{2}(2,2)+yc)];
    position{2} = [x1+0.001 y1-0.0005 x1-(v{1}(1,2)+xc) y1-(v{1}(2,2)+yc)];
elseif direction == 0
    % Do nothing
else
    error('direction flag not 1, -1, 2 or 0.');
end

% Loop for each arrow head
i = 1;
while i < abs(direction) + 1
    h=annotation('arrow'); % arrow head
    set(h,'parent', gca, 'position', position{i}, ...
        'HeadLength', head_size, 'HeadWidth', head_size,...
        'HeadStyle', head_style, 'linestyle','none','Color', 'k');
    
    i = i + 1;
end

function [p,n]=numSubplots(n)
% function [p,n]=numSubplots(n)
%
% Purpose
% Calculate how many rows and columns of sub-plots are needed to
% neatly display n subplots.
%
% Inputs
% n - the desired number of subplots.
%
% Outputs
% p - a vector length 2 defining the number of rows and number of
%     columns required to show n plots.
% [ n - the current number of subplots. This output is used only by
%       this function for a recursive call.]
%
%
%
% Example: neatly lay out 13 sub-plots
% >> p=numSubplots(13)
% p =
%     3   5
% for i=1:13; subplot(p(1),p(2),i), pcolor(rand(10)), end
%
%
% Rob Campbell - January 2010


while isprime(n) & n>4,
    n=n+1;
end

p=factor(n);

if length(p)==1
    p=[1,p];
    return
end


while length(p)>2
    if length(p)>=4
        p(1)=p(1)*p(end-1);
        p(2)=p(2)*p(end);
        p(end-1:end)=[];
    else
        p(1)=p(1)*p(2);
        p(2)=[];
    end
    p=sort(p);
end


%Reformat if the column/row ratio is too large: we want a roughly
%square design
while p(2)/p(1)>2.5
    N=n+1;
    [p,n]=numSubplots(N); %Recursive!
end
