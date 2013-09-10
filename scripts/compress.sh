#!/bin/bash 

if [ "$#" -eq 0 ]
then
  USAGE="Usage:
  scripts/compress.sh igl.h igl.cpp

Compresses all headers into igl.h and all sources into igl.cpp

Or:
  scripts/compress.sh igl.h

Compresses all headers *and* sources into igl.h (IGL_HEADER_ONLY)
";
  echo "$USAGE"
  exit 1
fi

if [ "$#" -eq 1 ]
then
  H_OUT=$1
  CPP_OUT=$H_OUT
fi

if [ "$#" -eq 2 ]
then
  H_OUT=$1
  CPP_OUT=$2
fi

# Prepare output files
#H_OUT=igl.h
#CPP_OUT=igl.cpp
rm -f $H_OUT
rm -f $CPP_OUT

HEADER="
libigl - A simple c++ geometry processing library

http://igl.ethz.ch/projects/libigl/

Copyright 2013 - Alec Jacobson, Daniele Panozzo, Olga Diamanti, Kenshi
Takayama, Leo Sacht, Interactive Geometry Lab - ETH Zurich

`cat $LIBIGL/VERSION.txt | sed -ne "s/^\([^\#]\)/VERSION \1/p"`

Compressed on `date`

"

echo "$HEADER" | sed -e "s/^/\/\/ /" >> $H_OUT

WIDGET_OPEN="
#ifndef IGL_HEADER_ONLY
#  define IGL_HEADER_ONLY
#  define IGL_HEADER_ONLY_WAS_NOT_DEFINED
#endif
";
WIDGET_CLOSE="
#ifdef IGL_HEADER_ONLY_WAS_NOT_DEFINED
#  undef IGL_HEADER_ONLY
#endif
";

# No cpp file, just header
if [ $H_OUT == $CPP_OUT ]
then
  echo "$WIDGET_OPEN" >> $H_OUT
fi

echo "" >> $H_OUT
echo "#ifndef IGL_H" >> $H_OUT
echo "#define IGL_H" >> $H_OUT
LIBIGL=/usr/local/igl/libigl
FIRST_H_FILES="\
$LIBIGL/include/igl/igl_inline.h \
";

H_FILES="$FIRST_H_FILES `ls $LIBIGL/include/igl/*.h`"
for h in $H_FILES
do
  short=`echo $h | sed -e 's/.*igl\///'`
  echo "//////////////////////////////////////////////////////////////////" >> $H_OUT
  echo "// $short begin" >> $H_OUT
  echo "//" >> $H_OUT
  # Remove "local" header or cpp files
  cat $h | sed -E '/^\# *include  *"*[A-z_]*.(cpp|h)"/d' >> $H_OUT
  echo "//" >> $H_OUT
  echo "// $short end" >> $H_OUT
  echo "//////////////////////////////////////////////////////////////////" >> $H_OUT
  echo "" >> $H_OUT
done
echo "#endif" >> $H_OUT

# Distinct h and cpp files
if [ $H_OUT != $CPP_OUT ]
then
  echo "$HEADER" | sed -e "s/^/\/\/ /" >> $CPP_OUT
  echo "#include \"igl.h\"" >> $CPP_OUT
  echo "" >> $CPP_OUT
fi

LAST_CPP_FILES="\
$LIBIGL/include/igl/MCTables.hh \
";
CPP_FILES=`ls $LIBIGL/include/igl/*.cpp $LAST_CPP_FILES`
for cpp in $CPP_FILES
do
  short=`echo $cpp | sed -e 's/.*igl\///'`
  echo "//////////////////////////////////////////////////////////////////" >> $CPP_OUT
  echo "// $short begin" >> $CPP_OUT
  echo "//" >> $CPP_OUT
  # Remove "local" header or cpp files
  cat $cpp | sed -E '/^\# *include  *"*[A-z_]*.(cpp|h)"/d' >> $CPP_OUT
  echo "//" >> $CPP_OUT
  echo "// $short end" >> $CPP_OUT
  echo "//////////////////////////////////////////////////////////////////" >> $CPP_OUT
  echo "" >> $CPP_OUT
done

# No cpp file, just header
if [ $H_OUT == $CPP_OUT ]
then
  echo "$WIDGET_CLOSE" >> $CPP_OUT
fi

# Try to compile it
echo "Compile with:"
echo ""
echo "    g++ -o igl.o -c igl.cpp -I/opt/local/include/eigen3"
echo "    ar cqs libigl.a igl.o"
echo "    rm igl.o"
echo ""
