#!/bin/bash

ncl gen-hist_precip.ncl 'nlfile="nl.PRECL_MASKI.tau3600"'
ncl gen-hist_precip.ncl 'nlfile="nl.PRECL_MASKI.dtime900"'
ncl gen-hist_precip.ncl 'nlfile="nl.PRECL_MASKI.dtime1800"'
ncl gen-hist_precip.ncl 'nlfile="nl.PRECL_MASKI.tau900"'
ncl gen-hist_precip.ncl 'nlfile="nl.PRECL_MASKI.dtime450tau1800"'
ncl gen-hist_precip.ncl 'nlfile="nl.PRECL_MASKI.tau3600_lowdmpdz2"'

ncl gen-hist_precip.ncl 'nlfile="nl.PRECC_MASKI.tau3600"'
ncl gen-hist_precip.ncl 'nlfile="nl.PRECC_MASKI.dtime900"'
ncl gen-hist_precip.ncl 'nlfile="nl.PRECC_MASKI.dtime1800"'
ncl gen-hist_precip.ncl 'nlfile="nl.PRECC_MASKI.tau900"'
ncl gen-hist_precip.ncl 'nlfile="nl.PRECC_MASKI.dtime450tau1800"'
ncl gen-hist_precip.ncl 'nlfile="nl.PRECC_MASKI.tau3600_lowdmpdz2"'

ncl gen-hist_precip.ncl 'nlfile="nl.OMEGA500_MASKI.tau3600"'
ncl gen-hist_precip.ncl 'nlfile="nl.OMEGA500_MASKI.dtime900"'
ncl gen-hist_precip.ncl 'nlfile="nl.OMEGA500_MASKI.dtime1800"'
ncl gen-hist_precip.ncl 'nlfile="nl.OMEGA500_MASKI.tau900"'
ncl gen-hist_precip.ncl 'nlfile="nl.OMEGA500_MASKI.dtime450tau1800"'
ncl gen-hist_precip.ncl 'nlfile="nl.OMEGA500_MASKI.tau3600_lowdmpdz2"'

