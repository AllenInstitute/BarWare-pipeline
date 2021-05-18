#!/bin/bash

echo "Building BarCounter"

cd BarCounter-release
gcc Bar_Count.c barcodes.c tags.c umis.c -lz -o barcounter
cd ../

echo "Installing BarMixer to R library"
Rscript --vanilla -e 'install.packages("./BarMixer/", repos = NULL, type = "source")'

echo "BarcodeTender setup complete"
