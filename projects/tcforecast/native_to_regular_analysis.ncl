; Inputs
; iniyear (1999)
; inimon (12)
; iniday (25)
; inisec (24000)
; filename

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

case="450s"
filename="tcforecast_60_x4.cam.h1.2012-09-05-00000.nc"

if (case .eq. "control") then
  thefile = addfile("/glade/u/home/zarzycki/scratch/_TCFORECAST/2012_00Z/2012083100/"+filename,"r")
else if (case .eq. "450s") then
  thefile = addfile("/glade/u/home/zarzycki/scratch/_TCFORECAST/sensitivity_runs/450s_windhighbias/2012083100/"+filename,"r")
else if (case .eq. "nodeep") then
  thefile = addfile("/glade/u/home/zarzycki/scratch/_TCFORECAST/sensitivity_runs/nodeep_windhighbias/2012083100/"+filename,"r")
else if (case .eq. "clubb") then
  thefile = addfile("/glade/u/home/zarzycki/scratch/_TCFORECAST/sensitivity_runs/clubb_windhighbias/2012083100/"+filename,"r")
else
  print("no case")
  exit
end if
end if
end if
end if


prect_se = thefile->PRECT
prect_se = 86400000*prect_se
precc_se = thefile->PRECCav
precc_se = 86400000*precc_se
precl_se = thefile->PRECLav
precl_se = 86400000*precl_se

wgt_file = "/glade/scratch/zarzycki/tcforecast_60_x4_to_0.125x0.125_patch.nc"

Opt         = True
prect  = ESMF_regrid_with_weights(prect_se,wgt_file,Opt)
precl  = ESMF_regrid_with_weights(precl_se,wgt_file,Opt)
precc  = ESMF_regrid_with_weights(precc_se,wgt_file,Opt)

print("Begin interp")
guess     = 1                ; use zonal means
is_cyclic = True             ; cyclic [global]
nscan     = 500             ; usually much less than this
eps       = 1.e-2            ; variable dependent
relc      = 0.5              ; relaxation coefficient
opt       = 0                ; not used
poisson_grid_fill( prect, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( precc, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( precl, is_cyclic, guess, nscan, eps, relc, opt)

printVarSummary(prect)

maxlat = 35.           ; choose subregion           
minlat = 25.
minlon = -67. 
maxlon = -56.

prect_sub = prect(0,{minlat:maxlat},{minlon:maxlon})
precc_sub = precc(0,{minlat:maxlat},{minlon:maxlon})
precl_sub = precl(0,{minlat:maxlat},{minlon:maxlon})

printVarSummary(prect_sub)

contour = new(3,"graphic")

  wks = gsn_open_wks("pdf","panel_prec_"+case)           ; open a ps file
  gsn_define_colormap(wks,"gui_default")

  res                   = True
  res@gsnDraw = False
  res@gsnFrame = False
 
  res@cnFillOn          = True              ; color plot desired
  res@cnLineLabelsOn    = False             ; turn off contour lines

  res@gsnAddCyclic = False

  res@gsnSpreadColors     = True            ; use full range of color map

res@mpMaxLatF                   = maxlat           ; choose subregion
res@mpMinLatF                   = minlat
res@mpMinLonF = minlon
res@mpMaxLonF = maxlon

res@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
res@cnLevelSpacingF      =    50.0
res@cnMinLevelValF       =     0.0
res@cnMaxLevelValF       =  800.0

res@cnFillMode = "RasterFill"
res@cnLinesOn = False

res@gsnRightString="mm/day"
res@gsnLeftString="Total precip"
contour(0) = gsn_csm_contour_map(wks,prect_sub,res)  ; create the plot
res@gsnLeftString="Large-scale precip"
contour(1) = gsn_csm_contour_map(wks,precl_sub,res)  ; create the plot
res@gsnLeftString="Convective precip"
contour(2) = gsn_csm_contour_map(wks,precc_sub,res)  ; create the plot

gsn_panel(wks,contour,(/1,3/),False)             ; now draw as one plot


end
