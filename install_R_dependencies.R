installed <- rownames(installed.packages())

if(! "BiocManager" %in% installed) {
  install.packages("BiocManager")
}

if(! "rhdf5" %in% installed) {
  BiocManager::install("rhdf5")
}

