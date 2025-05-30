#!/bin/bash

ncl scatter-changes.ncl MINCAT=1 MAXCAT=1 'SNOWPRECT="SNOW"' 'REFTIME="1990"' 'TESTTIME="2026"'
ncl scatter-changes.ncl MINCAT=2 MAXCAT=2 'SNOWPRECT="SNOW"' 'REFTIME="1990"' 'TESTTIME="2026"'
ncl scatter-changes.ncl MINCAT=3 MAXCAT=3 'SNOWPRECT="SNOW"' 'REFTIME="1990"' 'TESTTIME="2026"'
ncl scatter-changes.ncl MINCAT=4 MAXCAT=4 'SNOWPRECT="SNOW"' 'REFTIME="1990"' 'TESTTIME="2026"'
ncl scatter-changes.ncl MINCAT=5 MAXCAT=5 'SNOWPRECT="SNOW"' 'REFTIME="1990"' 'TESTTIME="2026"'
ncl scatter-changes.ncl MINCAT=1 MAXCAT=2 'SNOWPRECT="SNOW"' 'REFTIME="1990"' 'TESTTIME="2026"'
ncl scatter-changes.ncl MINCAT=3 MAXCAT=5 'SNOWPRECT="SNOW"' 'REFTIME="1990"' 'TESTTIME="2026"'

ncl scatter-changes.ncl MINCAT=1 MAXCAT=1 'SNOWPRECT="SNOW"' 'REFTIME="1990"' 'TESTTIME="2071"'
ncl scatter-changes.ncl MINCAT=2 MAXCAT=2 'SNOWPRECT="SNOW"' 'REFTIME="1990"' 'TESTTIME="2071"'
ncl scatter-changes.ncl MINCAT=3 MAXCAT=3 'SNOWPRECT="SNOW"' 'REFTIME="1990"' 'TESTTIME="2071"'
ncl scatter-changes.ncl MINCAT=4 MAXCAT=4 'SNOWPRECT="SNOW"' 'REFTIME="1990"' 'TESTTIME="2071"'
ncl scatter-changes.ncl MINCAT=5 MAXCAT=5 'SNOWPRECT="SNOW"' 'REFTIME="1990"' 'TESTTIME="2071"'
ncl scatter-changes.ncl MINCAT=1 MAXCAT=2 'SNOWPRECT="SNOW"' 'REFTIME="1990"' 'TESTTIME="2071"'
ncl scatter-changes.ncl MINCAT=3 MAXCAT=5 'SNOWPRECT="SNOW"' 'REFTIME="1990"' 'TESTTIME="2071"'

ncl scatter-changes.ncl MINCAT=1 MAXCAT=1 'SNOWPRECT="PRECT"' 'REFTIME="1990"' 'TESTTIME="2026"'
ncl scatter-changes.ncl MINCAT=2 MAXCAT=2 'SNOWPRECT="PRECT"' 'REFTIME="1990"' 'TESTTIME="2026"'
ncl scatter-changes.ncl MINCAT=3 MAXCAT=3 'SNOWPRECT="PRECT"' 'REFTIME="1990"' 'TESTTIME="2026"'
ncl scatter-changes.ncl MINCAT=4 MAXCAT=4 'SNOWPRECT="PRECT"' 'REFTIME="1990"' 'TESTTIME="2026"'
ncl scatter-changes.ncl MINCAT=5 MAXCAT=5 'SNOWPRECT="PRECT"' 'REFTIME="1990"' 'TESTTIME="2026"'
ncl scatter-changes.ncl MINCAT=1 MAXCAT=2 'SNOWPRECT="PRECT"' 'REFTIME="1990"' 'TESTTIME="2026"'
ncl scatter-changes.ncl MINCAT=3 MAXCAT=5 'SNOWPRECT="PRECT"' 'REFTIME="1990"' 'TESTTIME="2026"'

ncl scatter-changes.ncl MINCAT=1 MAXCAT=1 'SNOWPRECT="PRECT"' 'REFTIME="1990"' 'TESTTIME="2071"'
ncl scatter-changes.ncl MINCAT=2 MAXCAT=2 'SNOWPRECT="PRECT"' 'REFTIME="1990"' 'TESTTIME="2071"'
ncl scatter-changes.ncl MINCAT=3 MAXCAT=3 'SNOWPRECT="PRECT"' 'REFTIME="1990"' 'TESTTIME="2071"'
ncl scatter-changes.ncl MINCAT=4 MAXCAT=4 'SNOWPRECT="PRECT"' 'REFTIME="1990"' 'TESTTIME="2071"'
ncl scatter-changes.ncl MINCAT=5 MAXCAT=5 'SNOWPRECT="PRECT"' 'REFTIME="1990"' 'TESTTIME="2071"'
ncl scatter-changes.ncl MINCAT=1 MAXCAT=2 'SNOWPRECT="PRECT"' 'REFTIME="1990"' 'TESTTIME="2071"'
ncl scatter-changes.ncl MINCAT=3 MAXCAT=5 'SNOWPRECT="PRECT"' 'REFTIME="1990"' 'TESTTIME="2071"'

ncl scatter-changes.ncl MINCAT=1 MAXCAT=5 'SNOWPRECT="SNOW"' 'REFTIME="1990"' 'TESTTIME="2071"'

echo "-----------------------------------------------------------------" >> bootstrap-stats.txt

