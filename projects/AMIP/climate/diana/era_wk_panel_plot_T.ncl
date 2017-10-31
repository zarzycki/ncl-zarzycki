;************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"
load "wkSpaceTime_panel.ncl"
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


        varName = "T_GDS4_ISBL"     ; variable to use
        diro     = "./"       ; output dir: location of plots

        latBound = 15       ; latBound
        nDayWin  = 96       ; Wheeler-Kiladis [WK] temporal window length (days) 15
        nDaySkip = -60      ; time (days) between temporal windows [segments] 5
        spd      = 4        ; samples per day (6 hour sampling rate)
        
        opt             = True
        opt@pltType     = "pdf"              ; format of plot file
        opt@debug       = False              ; if =True, Multiple printVarSummary will be activated
        opt@cnLinesOn   = False              ; turn off contour lines
        opt@pltColorMap = "WhiteYellowOrangeRed"       ; wgne15 works okay or nrl_sirkes
        opt@Fig_3a = fspan(1.0,  5.0,  11)   ; specify range for contours
        opt@Fig_3b = fspan(1.0,  5.0,  11)   ; specify range for contours

          nfiles = 1             ; number of files
          panelSize = (/1,1/)    ; panel dimensions
          caseName =    "era_wk_aew"

          plotTit = (/" "/)
          yaxTit = (/"Frequency (cpd)"/)
          xaxTit = (/"Zonal Wave Number"/)
          cases = (/"ds124.1"/)

      fnam = new(nfiles,string)
      do file_step = 0,nfiles-1
         fnam(file_step) = "./temp_netcdf/"+cases(file_step)+"*.nc"
         print(fnam)
      end do


   wkSpaceTime_panel(fnam,nfiles,panelSize,diro,caseName,varName,latBound,spd,nDayWin,nDaySkip,opt,plotTit,yaxTit,xaxTit)



end
