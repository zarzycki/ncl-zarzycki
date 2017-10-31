load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

    ;src_file = "/glade/u/home/zarzycki/scratch/gulf_48_x8/run/2005082600/gulf_48_x8.cam.h1.2005-08-26-21600.nc"
    ;src_file = "/glade/u/home/zarzycki/scratch/cam5_work/varres_seedTCs/camrun.cam.i.2000-04-01-00000.nc"
    src_file = "/glade/p/cgd/ccr/f.e13.FAMIPC5.ne120_ne120.1979_2012.002/atm/proc/tseries/monthly/f.e13.FAMIPC5.ne120_ne120.1979_2012.002.cam.h0.PRECL.197901-201212.nc"
    var_name = "PRECL"

;---Data file containing source grid
    
    sfile    = addfile(src_file,"r")

;---Get variable to regrid
    var      = sfile->$var_name$(0,:)
    src_lat  = sfile->lat
    src_lon  = sfile->lon

;---Set up regridding options
    Opt                = True

;---"bilinear" is the default. "patch" and "conserve" are other options.
    Opt@SrcFileName = "/glade/scratch/zarzycki/regrid/srcgrid.nc"
    Opt@DstFileName = "/glade/scratch/zarzycki/regrid/dstgrid.nc"
    Opt@InterpMethod     = "patch"        ;;---Change (maybe)
    Opt@WgtFileName      = "/glade/scratch/zarzycki/regrid/ne120np4_to_0.25deg.nc"

    Opt@SrcGridLat       = src_lat
    Opt@SrcGridLon       = src_lon
    Opt@SrcRegional      = False            ;;--Change (maybe)
    Opt@SrcInputFileName = src_file          ; optional, but good idea
    Opt@SrcMask2D        = where(.not.ismissing(var),1,0) ; Necessary if has
                                                          ; missing values.
    ;regRes = 0.1
    regRes = 0.25

    Opt@DstGridType      = tostring(regRes)+"deg"
    Opt@DstTitle         = "World Grid 1 degree resolution"
    ;Opt@DstLLCorner      = (/-90.d,   0.00d /)      ;;--Change (maybe)
    ;Opt@DstURCorner      = (/ 90.d, 359.d /)      ;;--Change (maybe)

    Opt@ForceOverwrite   = True
    Opt@Debug            = True
    Opt@PrintTimings     = True

    var_regrid = ESMF_regrid(var,Opt)     ; Do the regridding
    
    printVarSummary(var_regrid)

end
