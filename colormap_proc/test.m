% Extract 1xn png of colormap with screenshot util, etc.
% Read 1xN png, squeeze singleton dimension, return RGB trips.
z = imread('wxbell_snow.png','png');
z = squeeze(z);

% For "thick" colorbars with many pixels of same color, need to stride to eliminate dups.
% Better to write option that only keeps RGB trip materially different from previous
% Ex: if (RGB(i) similar to RGB(i-1), go to RGB(i+1)
stride=18;
z_short = z(1:stride:end,:)

% Write CSV output file which can be read into NCL and applied via cmap
dlmwrite('wxbell_snow',z_short);