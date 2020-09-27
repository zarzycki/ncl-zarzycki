;f=addfile("/glade/p/cesmdata/cseg/inputdata/atm/cam/scam/iop/CESM2.F2000climo.IOP_SITES.cam.i.0003-06-01-00000.nc","r")
f=addfile("/glade/p/cesmdata/cseg/inputdata/atm/cam/scam/iop/BOMEX_5day_4scam_c180703.nc","r")

print(f->lev)

V = f->u(1,:,0,0)

print(V)