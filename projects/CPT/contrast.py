import xarray as xr
import numpy as np
import matplotlib.pyplot as plt
from scipy.interpolate import griddata
import cartopy.crs as ccrs
import glob

import sys
sys.path.insert(0, '/glade/u/home/zarzycki/sw/great_circle_calculator')
from gc_funcs.gc_functions import *

# module load conda
# conda activate npl-2023b

# Set the directory
dir_path = "/glade/derecho/scratch/stepheba/archive/"

# List of cases
#cases = ["b1850.054.f_outofbox"]
cases = [ "flthist134_outofbox", "b1850.054.f_ztest2e_2b", "b1850.054.f_outofbox", "b1850.054.f_ztest2"]
labels = [ "F_Lscale","B_taus_2b","B_Lscale","B_taus" ]
colors = ['blue', 'red', 'blue', 'red']
dashes = [(1, 0), (1, 0), (1, 1), (1, 1)]  # Dash patterns: (line, space).

var = "wp3"

# Initialize storage for the mean values
mean_store = None

for case in cases:
    print(f"{dir_path}/{case}")

    # Reading the files using xarray
    fils = f"{dir_path}/{case}/atm/hist/*h0*.nc"

    # CMZ print some diagnostics
    print(fils)
    matching_files = glob.glob(fils)
    for thisfile in matching_files:
        print(thisfile)
    print(f"Count of matching files: {len(matching_files)}")

    ds = xr.open_mfdataset(fils, combine='by_coords', parallel=True, data_vars="minimal", coords="minimal", compat="override")

    # Extracting the variable
    myvar = ds[var]
    print(myvar)

    # Storing lat, lon, and lev from the first case
    if mean_store is None:
        lat = ds['lat']
        lon = ds['lon']
        lev = ds['lev']
        nlat = lat.size
        nlon = lon.size
        nlev = lev.size
        var_units = myvar.attrs.get('units', 'No units found')

        # Check if 'lev' is a dimension in myvar
        do_levs = 'lev' in myvar.dims or 'ilev' in myvar.dims
        if do_levs:
            mean_store = np.zeros((len(cases), nlev, nlat, nlon))
        else:
            mean_store = np.zeros((len(cases), nlat, nlon))
        print(f"Does 'myvar' have a 'lev' dimension? {do_levs}")

    if do_levs:
        mean_store[cases.index(case), :, :, :] = myvar[:,0:nlev,:,:].mean(dim='time').values
    else:
        mean_store[cases.index(case), :, :] = myvar[:,:,:].mean(dim='time').values

# Get transect stuff
leftlat, leftlon = 20.0, 195.0-360.0
rightlat, rightlon = 30.0, 235.0-360.0
npts = 60

distance, gclats, gclons = gc_latlon(leftlat, leftlon, rightlat, rightlon, npts, 2)

target_points = np.array([gclats, gclons]).T

src_lats, src_lons = np.meshgrid(lat, lon, indexing='ij')
src_lons = src_lons - 360.0
src_points = np.array([src_lats.flatten(), src_lons.flatten()]).T


if do_levs:
    merge_trans = np.zeros((len(cases), nlev, npts))
else:
    merge_trans = np.zeros((len(cases), npts))


# Further processing and plotting
for ii in range(len(cases)):

    print(f"Interpolating case number {ii}")

    if do_levs:

        if ii == 0:
            merge_trans = np.zeros((len(cases), nlev, npts))
            interpolated_values_all_levels = np.empty((nlev, npts))

        for level in range(nlev):
                print(f"Interpolating level: {level}")
                src_values = mean_store[ii, level, :, :].flatten()
                interpolated_values = griddata(src_points, src_values, target_points, method='nearest')
                interpolated_values_all_levels[level, :] = interpolated_values

        merge_trans[ii, :, :] = interpolated_values_all_levels

    else:

        if ii == 0:
            merge_trans = np.zeros((len(cases), npts))

        src_values = mean_store[ii,:,:].flatten()
        interpolated_values = griddata(src_points, src_values, target_points, method='linear')

        merge_trans[ii, :] = interpolated_values



default_min, default_max = -1, 1
vmin_vmax_mapping = {
    "CLOUD": (0, 0.30),
    "T": (190, 310),
    "wp3": (0, 0.12),
}

if do_levs:

    # Create a 2x2 grid of subplots
    fig, axs = plt.subplots(2, 2, figsize=(11, 8.5), layout='compressed')

    # Flatten the axs array for easy iteration
    axs = axs.flatten()

    # Get vmin and vmax from the dictionary
    #vmin, vmax = vmin_vmax_mapping.get(var, (default_min, default_max))
    vmin = np.min(merge_trans)
    vmax = np.max(merge_trans)

    # Plotting each cross-section for each case
    for i in range(4):
        ax = axs[i]
        case_data = merge_trans[i, :, :]  # Data for the current case
        X, Y = np.meshgrid(range(npts), lev)  # Create meshgrid for X (transect points) and Y (levels)

        # Choose the contour levels (if needed, based on your data range)
        contour_levels = np.linspace(vmin, vmax, num=25)

        # Plot the cross-section using contourf (could also use pcolormesh)
        ctf = ax.contourf(X, Y, case_data, levels=contour_levels, cmap='viridis')

        # Set the labels and titles
        ax.set_title(labels[i])
        ax.set_xlabel('Transect Points')
        ax.set_ylabel('Levels')

        ax.invert_yaxis()

    fig.suptitle(var)

    # Draw the colorbar
    fig.colorbar(ctf, ax=axs[1:3], orientation='vertical')


    # Show the plot
    plt.show()

else:
    points = np.linspace(0, npts-1, npts)
    plt.figure()
    for i in range(merge_trans.shape[0]):
        line, = plt.plot(points, merge_trans[i, :], label=labels[i], color=colors[i])
        line.set_dashes(dashes[i])  # Set the dash pattern

    plt.xlabel('Points')
    plt.ylabel(var + " (" + var_units + ")")
    plt.legend()

    plt.xlim(0, 100)

    plt.show()





sys.quit()




fig, axs = plt.subplots(2, 2, figsize=(11, 8.5),
        subplot_kw={'projection': ccrs.PlateCarree()})

# Set the min/max contours
vmin, vmax = -80, 0

# Reversed magma colormap
cmap = plt.cm.magma_r

# Flatten axs so we can iterate over it
axs = axs.flatten()

for ii, ax in enumerate(axs):
    ax.set_title(labels[ii])
    ax.coastlines()

    # Customize gridlines, only label lats/lons on left and bottom
    gl = ax.gridlines(draw_labels=True)
    gl.top_labels = False  # Disable the top labels
    gl.right_labels = False  # Disable the right labels

    # Extract data at this index
    data = mean_store[ii, :, :]
    mesh = ax.pcolormesh(lon, lat, data, shading='auto', vmin=vmin, vmax=vmax, cmap=cmap)

    # Add transect markers and dashed line
    ax.plot([leftlon, rightlon], [leftlat, rightlat], color='lime',
            linewidth=2, linestyle='--',
            transform=ccrs.Geodetic())  # Use Geodetic transform for plotting
    ax.plot(leftlon, leftlat, marker='o', color='lime',
            markersize=5, transform=ccrs.Geodetic())
    ax.plot(rightlon, rightlat, marker='o', color='lime',
            markersize=5, transform=ccrs.Geodetic())

# Adjust the location of the subplots on the page to make room for the colorbar
fig.subplots_adjust(bottom=0.2, top=1.0, left=0.0, right=1.0,
                    wspace=0.1, hspace=0.0)

# Add a colorbar axis at the bottom of the graph
cbar_ax = fig.add_axes([0.2, 0.15, 0.6, 0.02])

# Draw the colorbar
cbar=fig.colorbar(mesh, cax=cbar_ax,orientation='horizontal')

plt.show()