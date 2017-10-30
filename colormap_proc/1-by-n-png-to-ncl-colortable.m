z = imread('irsat_colors.png','png')
z = squeeze(z)
z_short = z(1:2:end,:)
dlmwrite('irsat',z_short)
