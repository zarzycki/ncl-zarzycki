load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_outline_fcn.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_hommegrid_fcn.ncl"

begin

minlat=8
maxlat=43
minlon=280
maxlon=340
y1 = (/minlat,maxlat,maxlat,minlat/)
x1 = (/minlon,minlon,maxlon,maxlon/)
lonlength = maxlon-minlon

minlon=160
maxlon=minlon+lonlength
y2 = (/minlat,maxlat,maxlat,minlat/)
x2 = (/minlon,minlon,maxlon,maxlon/)

minlat = -10
maxlat = 25
minlon = 255
maxlon = 300
y3 = (/minlat,maxlat,maxlat,minlat/)
x3 = (/minlon,minlon,maxlon,maxlon/)

wks  = gsn_open_wks("pdf","AMIP_avg_regions")            ; open a ps file
gsn_define_colormap(wks,"amwg")

res                             = True
res@mpFillOn                    = False        ; turn off gray fill
res@mpOutlineOn = True
res@gsnFrame = False
res@gsnDraw = False
;res@mpGreatCircleLinesOn=True
res@tiMainString    = "Statistic Averaging Regions"   ; add titles

res@mpCenterLonF = 240.
plot = gsn_csm_map(wks,res)                 ; draw blank map for met division outlines

resp                  = True                      ; polyline mods desired
resp@mpGreatCircleLinesOn=True
resp@gsFillColor = "Red"
  resp@gsEdgesOn   = True       ; draw border around polygons
  resp@gsEdgeColor = "Red"
resp@gsFillIndex        = 3
;resp@cnFillPattern      = 3

dum1 = gsn_add_polygon(wks,plot,x1,y1,resp)

resp@gsFillIndex        = 17
resp@gsFillColor = "Blue"
resp@gsEdgeColor = "Blue"
dum2 = gsn_add_polygon(wks,plot,x2,y2,resp)

resp@gsFillIndex        = 11
resp@gsFillColor = "Green"
resp@gsEdgeColor = "Green"
dum3 = gsn_add_polygon(wks,plot,x3,y3,resp)


;=========================

plot = plot_outline_fcn(wks,plot,"black",2.5)

draw(plot)



frame(wks)

end





