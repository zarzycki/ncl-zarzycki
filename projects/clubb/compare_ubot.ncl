;========================================================
; Reads 
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
;========================================================
begin

files=(/"/glade/scratch/zarzycki/clubb-tracking/MEANS/CLUBBavg_regrid.nc","/glade/scratch/zarzycki/clubb-tracking/MEANS/CAM5avg_regrid.nc"/)
nfiles=dimsizes(files)

wks   = gsn_open_wks ("pdf", "ubot_comp")        ; send graphics to PNG file

res                 = True                    ; plot mods desired
res@gsnDraw         = False                   ; don't draw yet
res@gsnFrame        = False                   ; don't advance frame yet
res@cnFillOn        = True                    ; turn on color 
res@cnFillPalette   = "gui_default"           ; set color map
res@lbLabelBarOn    = False                   ; will draw a panel label bar instead
res@cnLinesOn       = False                   ; turn off contour lines
res@cnLineLabelsOn  = False                   ; tuen off line labels
res@cnLevelSelectionMode =  "ManualLevels"
res@cnMinLevelValF       = 0.2
res@cnMaxLevelValF       = 2.5
res@cnLevelSpacingF      = 0.1

plot = new(2,graphic)

do i = 0,nfiles-1
  print("Doing file: "+files(i))
  f=addfile(files(i),"r")
  stride=8
  UBOT=f->UBOT(0,::stride,::stride)
  VBOT=f->VBOT(0,::stride,::stride)
  U850=f->U850(0,::stride,::stride)
  V850=f->V850(0,::stride,::stride)
  ;U10 =f->U10(0,::stride,::stride)

  WIND850=U850
  WINDBOT=UBOT

  WIND850=sqrt(U850^2. + V850^2.)
  WINDBOT=sqrt(UBOT^2. + VBOT^2.)

  RATIO=U850
  RATIO=WINDBOT/WIND850

  print(avg(RATIO))

  plot(i) = gsn_csm_contour_map(wks,RATIO,res)

  delete([/RATIO,WINDBOT,WIND850,V850,U850,VBOT,UBOT/])
end do

panres                     = True
panres@gsnMaximize         = True             ; maximize the plots
panres@gsnPanelLabelBar    = True             ; turn on the panel label bar
panres@lbLabelStride       = 2                ; set the label bar label stride to 2
gsn_panel(wks,plot,(/2,1/),panres) 

end

