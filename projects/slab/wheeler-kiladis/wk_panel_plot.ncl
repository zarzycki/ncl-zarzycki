
;************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"
;load "wkSpaceTime_panel.ncl"
;************************************************

;===============================================
; This calls the function wkSpaceTime_panel.ncl to 
; create a panel plot of Wheeler-Kiladis diagrams
;
; Required Input:
;    fnam      - an array of the file paths
;    nfiles    - number of files to be paneled
;    panelSize - dimensions of panel ie (/1,2/)
;    diro      - output directory
;    caseName  - used for file name
;    varName   - variable name in data file
;    latBound  - boundary latitude ie 15
;    spd       - samples per day
;    nDayWin   - temporal window length
;    nDaySkip  - days between temporal windows
;    opt       - resource with a variety of options
;    plotTit   - an array of titles over each plot
;
; Diana Thatcher, dtatch@umich.edu, 8/29/2013
;================================================

  begin

print("wk_panel_plot.ncl")

; Settings ----------------------------------


varName = "FLUT"     ; variable to use
diro     = "./"       ; output dir: location of plots

latBound = 15       ; latBound
nDayWin  = 96       ; Wheeler-Kiladis [WK] temporal window length (days) 15
nDaySkip = -60      ; time (days) between temporal windows [segments] 5
spd      = 4        ; samples per day (6 hour sampling rate)

opt             = True
opt@pltType     = "pdf"              ; format of plot file
opt@debug       = True               ; if =True, Multiple printVarSummary will be activated
opt@cnLinesOn   = False              ; turn off contour lines
opt@pltColorMap = "nrl_sirkes"       ; wgne15 works okay or nrl_sirkes
;opt@Fig_3a = fspan(0.4,  4.4,  16)   ; specify range for contours
;opt@Fig_3b = fspan(0.4,  4.4,  16)   ; specify range for contours

; for now, have to run regrid_file.ncl before to gen lat/lon
; --> someday will create driver
; to do this online instead of offline

nfiles = 2             ; number of files
panelSize = (/1,nfiles/)    ; panel dimensions
caseName =    "wk_varres_CAM5"

plotTit = (/"fixedSST","slab3"/)
yaxTit = (/"Frequency (cpd)"," "," "/)
xaxTit = (/"Zonal Wave Number","Zonal Wave Number","Zonal Wave Number"/)

paths = (/"/glade/u/home/zarzycki/scratch/slab_trop_waves/","/glade/u/home/zarzycki/scratch/slab_trop_waves/"/)
cases = (/"cat_fixedSST.nc","cat_slab3.nc"/)

level    = -999

fnam = new(nfiles,string)
do file_step = 1,1
  wkSpaceTime_cam(paths(file_step),cases(file_step),diro,caseName,varName,latBound,spd,level,nDayWin,nDaySkip,opt)
end do


end
