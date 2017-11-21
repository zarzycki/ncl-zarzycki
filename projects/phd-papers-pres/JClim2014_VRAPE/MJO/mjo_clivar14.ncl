;***********************************************************
; Combined EOFs
;***********************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin
   neof    =  2

   latS    = -15
   latN    =  15

   ymdStrt = 00001230                         ; start yyyymmdd
   ymdLast = 00011231                         ; last  

   yrStrt  = 0000
   yrLast  = 0001

   pltDir  = "./"                             ; plot directory
   pltType = "ps"  
   pltName = "mjoclivar"                      ; yrStrt+"_"+yrLast
  
   diri    = "/glade/scratch/zarzycki/APE_levy/CAM5/uniform_15/"         ; input directory
   ;wname = "/glade/p/work/zarzycki/maps/plotmaps/map_uniform_120_TO_0.25x0.25_patc.130729.nc"
   wname = "/glade/p/work/zarzycki/maps/plotmaps/map_uni_15_TO_0.25x0.25_patc.130309.nc"

   filolr  = "h2_anomalies.nc"
   filu200 = "h2_anomalies.nc"
   filu850 = "h2_anomalies.nc"

;************************************************
; create BandPass Filter
;************************************************
  ihp      = 2                             ; bpf=>band pass filter
  nWgt     = 201
  sigma    = 1.0                           ; Lanczos sigma
  fca      = 1./100.
  fcb      = 1./20.
  wgt      = filwgts_lanczos (nWgt, ihp, fca, fcb, sigma )
  print(wgt)

;***********************************************************
; Find the indices corresponding to the start/end times
;***********************************************************
   f       = addfile (diri+filolr , "r")                         
   TIME    = f->time                          ; days since ...
   YMD     = cd_calendar(TIME, -2)            ; entire (time,6)

   iStrt   = 0              ; index start
   iLast   = dimsizes(TIME)-1              ; index last 
   delete(TIME)
   delete(YMD )

;***********************************************************
; Read anomalies
;***********************************************************

guess     = 1                ; use zonal means
is_cyclic = True             ; cyclic [global]
nscan     = 500             ; usually much less than this
eps       = 1.e-2            ; variable dependent
relc      = 0.5              ; relaxation coefficient
opt       = 0                ; not used

   print("Getting OLR from file")
   work_se    = f->FLUT(iStrt:iLast,:)
   work_regrid = ESMF_regrid_with_weights(work_se,wname,False)
   poisson_grid_fill( work_regrid, is_cyclic, guess, nscan, eps, relc, opt)
   work = work_regrid(:,{latS:latN},:)
   OLR     = dim_avg_n_Wrap(work,1)
   
   print("Getting U850 from file")
   f       = addfile (diri+filu850 , "r")                         
   work_se    = f->U850(iStrt:iLast,:)
   work_regrid = ESMF_regrid_with_weights(work_se,wname,False)
   poisson_grid_fill( work_regrid, is_cyclic, guess, nscan, eps, relc, opt)
   work = work_regrid(:,{latS:latN},:)
   U850    = dim_avg_Wrap(work(time|:,lon|:,lat|:))

   print("Getting U200 from file")
   f       = addfile (diri+filu200 , "r")                         
   work_se    = f->U200(iStrt:iLast,:)
   work_regrid = ESMF_regrid_with_weights(work_se,wname,False)
   poisson_grid_fill( work_regrid, is_cyclic, guess, nscan, eps, relc, opt)
   work = work_regrid(:,{latS:latN},:)
   U200    = dim_avg_Wrap(work(time|:,lon|:,lat|:))  ; (time,lon)

   dimw    = dimsizes( work )
   ntim    = dimw(0)
   nlat    = dimw(1)
   mlon    = dimw(2)
   delete(work)
   delete(work_se)
   delete(work_regrid)

   lon     = f->lon                                           
   time    = f->time(iStrt:iLast)             ; days since ...
   date    = cd_calendar(time, -2)            ; yyyymmdd
  

;************************************************
; Apply the band pass filter to the original anomalies
;************************************************
  olr   = wgt_runave_Wrap ( OLR(lon|:, time|:), wgt, 0)
  u850  = wgt_runave_Wrap (U850(lon|:, time|:), wgt, 0)
  u200  = wgt_runave_Wrap (U200(lon|:, time|:), wgt, 0)
  
  print(olr)
  
  if(any(ismissing(olr))) then
    printVarSummary(olr)
    print("olr (zeroth) data contains some missing values. Beware.")
    print("number missing is "+num(ismissing(olr)))
   end if 

;************************************************
; remove means of band pass series: *not* necessary 
;************************************************
  olr   = dim_rmvmean( olr)                   ; (lon,time)
  u850  = dim_rmvmean(u850)
  u200  = dim_rmvmean(u200)
  
  if(any(ismissing(olr))) then
    print("olr (first) data contains some missing values. Beware.")
   end if 

;************************************************
; Compute the temporal variance
;************************************************
  var_olr  = dim_variance_Wrap( olr)          ; (lon)
  var_u850 = dim_variance_Wrap(u850)
  var_u200 = dim_variance_Wrap(u200)
  
  if(any(ismissing(var_olr))) then
    print("var_olr data contains some missing values. Beware.")
   end if 

;************************************************
; Compute the zonal mean of the temporal variance
;************************************************
  zavg_var_olr  = dim_avg_Wrap( var_olr )     
  zavg_var_u850 = dim_avg_Wrap( var_u850)
  zavg_var_u200 = dim_avg_Wrap( var_u200)
  
  if(any(ismissing(zavg_var_olr))) then
    print("zavg_var_olr data contains some missing values. Beware.")
   end if 

;************************************************
; Normalize by sqrt(avg_var*)
;************************************************
  olr   =  olr/sqrt(zavg_var_olr )          ; (lon,time)
  u850  = u850/sqrt(zavg_var_u850)
  u200  = u200/sqrt(zavg_var_u200)
  
  if(any(ismissing(olr))) then
    print("olr data contains some missing values. Beware.")
   end if 

;************************************************
; Combine the normalized data into one variable
;************************************************
  cdata     = new ( (/3*mlon,ntim/), typeof(olr), getFillValue(olr))
  do ml=0,mlon-1
     cdata(ml       ,:) = (/  olr(ml,:) /)
     cdata(ml+  mlon,:) = (/ u850(ml,:) /)
     cdata(ml+2*mlon,:) = (/ u200(ml,:) /)
  end do
  
   if(any(ismissing(cdata))) then
    print("cdata data contains some missing values. Beware.")
   end if 


;************************************************
; Compute Combined EOF
;************************************************
  eof_cdata    = eofunc_Wrap(cdata   , neof, False)      ; (neof,3*mlon)
  eof_ts_cdata = eofunc_ts_Wrap(cdata,eof_cdata,False)   ; (neof,time)

  print("==============")
  printVarSummary(eof_cdata)
  printMinMax(eof_cdata, True)

  print("==============")
  printVarSummary(eof_ts_cdata)
  printMinMax(eof_ts_cdata, True)

;************************************************
; For clarity, explicitly extract each variable 
;************************************************

  nvar = 3  ; "olr", "u850", "u200"

  ceof = new( (/nvar,neof,mlon/), typeof(cdata), getFillValue(cdata))

  do n=0,neof-1
     ceof(0,n,:) = eof_cdata(n,0:mlon-1)      ; olr
     ceof(1,n,:) = eof_cdata(n,mlon:2*mlon-1) ; u850
     ceof(2,n,:) = eof_cdata(n,2*mlon:)       ; u200
  end do

  ceof_ts = new( (/nvar,neof,ntim/), typeof(cdata), getFillValue(cdata))

  ceof_ts(0,:,:) = eofunc_ts_Wrap( olr,ceof(0,:,:),False)   ; (neof,time)
  ceof_ts(1,:,:) = eofunc_ts_Wrap(u850,ceof(1,:,:),False)   ; (neof,time)
  ceof_ts(2,:,:) = eofunc_ts_Wrap(u200,ceof(2,:,:),False)   ; (neof,time)

;************************************************
; Compute cross correlation of each variable's EOF time series at zero-lag
;************************************************
  r_olr_u850  = escorc(ceof_ts(0,:,:) , ceof_ts(1,:,:))
  r_olr_u200  = escorc(ceof_ts(0,:,:) , ceof_ts(2,:,:) )
  r_u850_u200 = escorc(ceof_ts(1,:,:) , ceof_ts(2,:,:) )

  print("==============")
  do n=0,neof-1
     print("neof="+n \
          +"  r_olr_u850=" +sprintf("%4.3f",r_olr_u850(n))  \
          +"  r_olr_u200=" +sprintf("%4.3f",r_olr_u200(n))  \
          +"  r_u850_u200="+sprintf("%4.3f",r_u850_u200(n)) )
  end do
  print("==============")

;************************************************
; Compute cross correlation of the multivariate EOF; EOF 1 vs EOF 2
;************************************************

  mxlag     = 25
  rlag_01   = esccr(eof_ts_cdata(0,:),eof_ts_cdata(1,:), mxlag)   ; (N,mxlag+1)
  rlag_10   = esccr(eof_ts_cdata(1,:),eof_ts_cdata(0,:), mxlag)   ; (N,mxlag+1)
  ccr_12    = new ( (/2*mxlag+1/), float)    

  ccr_12(mxlag:)    = rlag_10(0:mxlag)   
  ccr_12(0:mxlag)   = rlag_01(::-1)       ; reverse order

;************************************************
; Normalize the multivariate EOF 1&2 component time series
; Compute (PC1^2+PC2^2): values > 1 indicate "strong" periods
;************************************************
  eof_ts_cdata(0,:) = eof_ts_cdata(0,:)/stddev(eof_ts_cdata(0,:))
  eof_ts_cdata(1,:) = eof_ts_cdata(1,:)/stddev(eof_ts_cdata(1,:))

  mjo_ts_index      = eof_ts_cdata(0,:)^2 + eof_ts_cdata(1,:)^2 
  mjo_ts_index_smt  = runave(mjo_ts_index, 91, 0) ; 91-day running mean

  nGood   = num(.not.ismissing(mjo_ts_index))     ; # non-missing
  nStrong = num(mjo_ts_index .ge. 1.0)
  print("nGood="+nGood+"   nStrong="+nStrong+"   nOther="+(nGood-nStrong))

;************************************************
; Write PC results to netCDF for use in another example.
;************************************************
  mjo_ts_index!0    = "time"
  mjo_ts_index&time = time 
  mjo_ts_index@long_name = "MJO PC INDEX" 
  mjo_ts_index@info      = "(PC1^2 + PC2^2)" 

  PC1  = eof_ts_cdata(0,:)
  PC1!0= "time"
  PC1&time      =  time
  PC1@long_name = "PC1"
  PC1@info      = "PC1/stddev(PC1)"

  PC2  = eof_ts_cdata(1,:)
  PC2!0= "time"
  PC2&time      =  time
  PC2@long_name = "PC2"
  PC2@info      = "PC2/stddev(PC2)"

  diro = "./"
  filo = "MJO_PC_INDEX.nc"
  system("/bin/rm -f "+diro+filo)   ; remove any pre-existing file
  ncdf = addfile(diro+filo,"c")     ; open output netCDF file
                                    ; make time an UNLIMITED dimension 
  filedimdef(ncdf,"time",-1,True)   ; recommended  for most applications
                                    ; output variables directly
  ncdf->MJO_INDEX = mjo_ts_index    
  ncdf->PC1       = PC1     
  ncdf->PC2       = PC2     

;------------------------------------------------------------
; PLOTS
;------------------------------------------------------------

  yyyymmdd = cd_calendar(time, -2)
  yrfrac   = yyyymmdd_to_yyyyfrac(yyyymmdd, 0.0)
  delete(yrfrac@long_name)
  delete(lon@long_name)

  day      = ispan(-mxlag, mxlag, 1)
 ;day@long_name = "lag (day)"

  if (pltType.eq."png") then
      pltTypeLocal = "eps"
  else
      pltTypeLocal = pltType
  end if

  pltPath = pltDir+pltName

  wks = gsn_open_wks(pltTypeLocal,pltPath)
  plot = new(3,graphic)                

;************************************************
; Multivariate EOF plots
;************************************************
                                      
  rts           = True
  rts@gsnDraw   = False       ; don't draw yet
  rts@gsnFrame  = False       ; don't advance frame yet
  rts@gsnScale  = True        ; force text scaling               

  rts@vpHeightF = 0.40        ; Changes the aspect ratio
  rts@vpWidthF  = 0.85
  rts@vpXF      = 0.10        ; change start locations
  rts@vpYF      = 0.75        ; the plot
  rts@xyLineThicknesses = (/2, 2, 2/)
  rts@gsnYRefLine            = 0.                  ; reference line   

  rts@pmLegendDisplayMode    = "Always"            ; turn on legend
  rts@pmLegendSide           = "Top"               ; Change location of 
  rts@pmLegendParallelPosF   = 0.86                ; move units right
  rts@pmLegendOrthogonalPosF = -0.50               ; move units down
  rts@pmLegendWidthF         = 0.15                ; Change width and
  rts@pmLegendHeightF        = 0.15                ; height of legend.
  rts@lgLabelFontHeightF     = 0.0175

  rtsP                       = True                ; modify the panel plot
  rtsP@gsnMaximize           = True                ; large format
  rtsP@txString              = "Multivariate EOF: 15S-15N: "+yrStrt+"-"+yrLast 
  
  rts@xyExplicitLegendLabels = (/"OLR", "U850", "U200" /)
  do n=0,neof-1
    rts@gsnLeftString  = "EOF "+(n+1)
    rts@gsnRightString = sprintf("%3.1f",ceof@pcvar(n))  +"%"
    plot(n) = gsn_csm_xy (wks,lon,ceof(:,n,:),rts)
  end do
  gsn_panel(wks,plot(0:1),(/2,1/),rtsP)     ; now draw as one plot

;************************************************
; cross correlation plots; delete unneeded resources 
;************************************************
  delete(rts@xyExplicitLegendLabels) 
  delete(rts@pmLegendDisplayMode)
  delete(rts@xyLineThicknesses)
  delete(rts@gsnLeftString)
  delete(rts@gsnRightString)

  lag              = ispan(-mxlag,mxlag,1)
  lag@long_name    = "lag (days)"
 ;ccr_12@long_name = "r"

  plot(0)          = gsn_csm_xy (wks, lag ,ccr_12,rts)
  rtsP@txString    = "Cross Correlation: Multivariate EOF: 15S-15N: " \
                   +  yrStrt+"-"+yrLast 
  rtsP@gsnPaperOrientation = "portrait"        ; force portrait
  gsn_panel(wks,plot(0),(/1,1/),rtsP)     ; now draw as one plot

;************************************************
; MJO "strong" index 
;************************************************
  rts@gsnYRefLine        = 1.0
  rts@gsnYRefLineColor   = "black"
  rts@xyMonoDashPattern  = True
  rts@xyLineColors       = (/"black", "blue"/)
  rts@xyLineThicknesses  = (/1, 2/)
  rts@pmLegendDisplayMode    = "Always"            ; turn on legend
  rts@pmLegendWidthF         = 0.12                ; Change width and
  rts@pmLegendHeightF        = 0.10                ; height of legend.
  rts@pmLegendParallelPosF   = 0.86                ; move units right
  rts@pmLegendOrthogonalPosF = -0.40               ; move units down
  rts@xyExplicitLegendLabels = (/"daily", "91-day runavg" /)

  mjo_ind_plt = new ( (/2,ntim/), typeof(mjo_ts_index))
  mjo_ind_plt(0,:) = mjo_ts_index
  mjo_ind_plt(1,:) = (/ mjo_ts_index_smt /)
  plot(0) = gsn_csm_xy(wks, yrfrac,mjo_ind_plt,rts)

  rtsP@txString  = "MJO Index: (PC1^2+ PC2^2) : 15S-15N: "+yrStrt+"-"+yrLast 
  gsn_panel(wks,plot(0),(/1,1/),rtsP)     ; now draw as one plot

;************************************************
; ? png ?             
;************************************************
   if (pltType.eq."png") then
       if (.not.isvar("pltConvert")) then
           pltConvert = " "               ; default
       end if
       system("convert "+pltConvert+" "+pltPath+".eps "+pltPath+".png")
       system("convert "+pltConvert+" "+pltPath+".eps "+pltPath+".png")
       system("/bin/rm -f "+pltPath+".eps")
   end if

end
