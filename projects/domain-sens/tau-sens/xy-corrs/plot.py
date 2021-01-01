import matplotlib 
import matplotlib.pyplot as plt 
import xarray as xr
import numpy as np

## Font stuff from S-O
## Say, "the default sans-serif font is COMIC SANS"
matplotlib.rcParams['font.sans-serif'] = "Helvetica"
## Then, "ALWAYS use sans-serif fonts"
matplotlib.rcParams['font.family'] = "sans-serif"
matplotlib.rcParams['pdf.fonttype'] = 42

tcfreqarr = [10.7,13.2,19.5]
#thisvar="OMEGA500"
config="dtime1800"
varslist = ['OMEGA500', 'PRECL', 'PRECC']
configlist = ['dtime1800', 'dtime900', 'tau3600']
ourvals=np.empty([len(varslist), len(configlist)])
for ii, thisvar in enumerate(varslist):
  for jj, config in enumerate(configlist):
    filename="../freq-hist/OUT_{}_{}_MASKI.nc".format(config, thisvar)
    print(filename)
    ds_disk = xr.open_dataset(filename)
    if thisvar == 'OMEGA500':
      ourvals[ii,jj] = ds_disk['stats'][22].values
    else:
      ourvals[ii,jj] = ds_disk['stats'][27].values

# Create dicts of nice pretty names
varprettynames = {
    'OMEGA500': '$\u03C9_{500}$',
    'PRECL': 'PRECL',
    'PRECC': 'PRECC'
}
configprettynames = {
    'dtime1800': '$dt_{1800}$',
    'dtime900': '$dt_{900}$',
    'tau3600': '$dt_{450}$'
}

fig = plt.figure()
host = fig.add_subplot(111)

## Create precip axis that shares x axis with host (omega)
prcp1 = host.twinx()

## Set axis limits
host.set_xlim(10., 20.)
host.set_ylim(-1.95, -0.75)
prcp1.set_ylim(0, 220.)

## Set labels for axes
host.set_xlabel("TC freq. per year")
host.set_ylabel("500 hPa vertical pressure velocity (Pa/s)")
prcp1.set_ylabel("Precipitation rate (mm/day)")

## Select colors
#color1 = plt.cm.viridis(0)
#color2 = plt.cm.viridis(0.5)
#color3 = plt.cm.viridis(.9)
color1 = (0.375, 0.5390625, 0.9609375)
color3 = (0.83203125, 0.14453125, 0.48046875)
color2 = (0.9453125, 0.65234375,  0)

## Plot each line
p1, = host.plot(tcfreqarr, ourvals[0,:], 's:', color=color1,label=varprettynames[varslist[0]])
p2, = prcp1.plot(tcfreqarr, ourvals[1,:], 's:', color=color2, label=varprettynames[varslist[1]])
p3, = prcp1.plot(tcfreqarr, ourvals[2,:], 's:', color=color3, label=varprettynames[varslist[2]])

## Add legend, specify loc with 2x tuple of bottom left corner of box in 0->1 coords
lns = [p1, p2, p3]
host.legend(handles=lns, loc=(0.52,0.81))

## Annotate with config names above line "clusters"
for jj, config in enumerate(configlist):
  host.annotate(configprettynames[configlist[jj]],
            xy=(tcfreqarr[jj],-0.83),
            xytext=(tcfreqarr[jj],-0.83),
            textcoords="data",
            ha='center', va='center', rotation=45)

## Set color of axis labels
#host.yaxis.label.set_color(p1.get_color())
#prcp1.yaxis.label.set_color(p2.get_color())

plt.savefig("xy-prob-corr.pdf", bbox_inches='tight')
