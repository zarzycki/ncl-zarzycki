#!/bin/bash
  
find . -name "*.nc" | parallel --progress -j8 'ncks -4 -L 1 -O --dbg_lvl 0 {} {}'
