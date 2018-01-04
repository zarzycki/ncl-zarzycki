z = imread('wxbell_snow.png','png')
z = squeeze(z)
z_short = z(1:2:end,:)
dlmwrite('wxbell_snow',z_short)