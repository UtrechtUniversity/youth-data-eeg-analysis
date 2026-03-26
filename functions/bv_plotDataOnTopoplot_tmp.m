function bv_plotDataOnTopoplot_tmp(Ws, lay, propThr, subplotlabels, weighted, color)

if nargin < 4
    subplotlabels = strsplit(num2str(1:size(Ws,3)),' ');
end
if nargin < 5
    weighted = true;
end

addpath('~/MatlabToolboxes/Colormaps/')

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
fprintf('preparing layout...')

% figure;
for currW = 1:size(Ws,3)
    
    W = squeeze(Ws(:,:,currW));
    W(isnan(W)) = 0;
    
    if doThresh
        W = threshold_proportional(W, propThr);
    end

    if size(Ws,3) > 1
        if size(Ws,3) == 2
            subplot(1,2,currW)
        else
            subplot(ceil(sqrt(size(Ws,3))), ceil(sqrt(size(Ws,3))), currW)
        end
    end
    
    fprintf('creating topoplot %s...', num2str(currW))
    hold on
    
    if weighted
        I = find(W);
        
        norm_data = (W(I) - min(W(I))) / ( max(W(I)) - min(W(I)) ) + 0.1;
        
        W(I) = norm_data;
    end
    
    if nansum(W(:))~=0
        counter = 0;
        for i = 1:size(W,1)
            for j = 1:size(W,2)
                if W(i,j)==0
                    continue
                end
                
                counter = counter + 1;
                
                if i==j
                    
                    radius = 0.025;
                    center = [lay.pos(i,1), (lay.pos(i,2) + radius)];
                    circular_arrow(radius, center, W(i,j)*[1], (W(i,j)+0.25)*5, (W(i,j)-0.01)/2);

                else
                    
                    x = lay.pos([i j],1);
                    y = lay.pos([i j],2);
                    
                    if ~weighted
                        h(counter) = patch(x,y, [0 0 0], 'LineWidth',3 ); %,'edgecolor','flat','linewidth',(weights(i,j)+0.25)*5);
                    else
                        h(counter) = patch(x,y, W(i,j)*[1 1], 'edgecolor','flat','linewidth', (W(i,j)+0.25)*5, 'edgealpha', (W(i,j)-0.01)/2);
                    end
                end
            end
        end
        
    end
    
    if weighted
        colormap(viridis)
    end
    
    scatter(lay.pos(:,1), lay.pos(:,2), 10, 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k')
    line(lay.outline{1}(:,1), lay.outline{1}(:,2), 'LineWidth', 3, 'color', [0.5 0.5 0.5])
    
    if not(isempty(subplotlabels))
        title(subplotlabels{currW})
    end
    axis equal
    axis off
    colorbar
    fprintf('done \n')
    
end

function circular_arrow(radius, centre, colour, linewidth, edgealpha)
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
angle = 330;
direction = 2;
head_style = 'vback2';
head_size = 10;

% display a warning if the headstyle has been specified, but direction has
% been set to no heads
if nargin == 9 && direction == 0
    warning(['Head style specified, but direction set to 0! '...
        'This will result in no arrow head being displayed.']);
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
n = 1000; % The number of points in the arc
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
    
    h_patch = patch([v_tmp(:,1); NaN], [v_tmp(:,2); NaN], repmat(colour,1,length(v_tmp)+1), ...
        'EdgeColor', 'flat', 'FaceColor', 'none', 'linewidth',linewidth, 'edgealpha', edgealpha);
    
    i = i + 1;

end

position = struct([]);

% Setting x and y for CW and CCW arrows
if direction == 1
    position{1} = [x2 y2 x2-(v{2}(1,2)+xc) y2-(v{2}(2,2)+yc)];
elseif direction == -1
    position{1} = [x1 y1 x1-(v{1}(1,2)+xc) y1-(v{1}(2,2)+yc)];
elseif direction == 2
    position{1} = [x2 y2 x2-(v{2}(1,2)+xc) y2-(v{2}(2,2)+yc)];
    position{2} = [x1 y1 x1-(v{1}(1,2)+xc) y1-(v{1}(2,2)+yc)];  
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

