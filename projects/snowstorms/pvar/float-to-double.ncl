begin

;filename = "/glade/scratch/zarzycki/erain_1993_pvar_one_side.nc"
f=addfile(filename,"w")

pvar = f->pvar

pvar_dbl = todouble(pvar)

copy_VarMeta(pvar,pvar_dbl)

eps = 1.e-6
pvar_dbl = where(pvar_dbl .lt. eps, 0.0, pvar_dbl)

f->pvar_dbl = pvar_dbl

end
