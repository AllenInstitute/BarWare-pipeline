## BarWare-pipeline


## Installing and running the pipeline

### Repository retrieval and installation

```
git clone git@github.com:AllenInstitute/BarWare-pipeline
cd BarWare-pipeline
git submodule update --init
R -e 'install.packages("BarMixer", type = "source", repos = NULL)'
chmod +x BarCounter-release/barcounter
```

### Running the pipeline

#### Stage 0: Run cellranger count

The BarWare pipeline is currently configured to demultiplex 10x Genomics 3' scRNA-seq data. Before analysis with BarCounter and BarMixer, we recommend that you run cellranger count to obtain the necessary scRNA-seq inputs for use with this pipeline.

If you are using a different analysis pipeline or method and would like to utilize BarWare, please let us know in the Issues page.

#### Before you run BarWare

You'll need 3 critical input files before running the BarWare pipeline:

**1: A Valid Cell Barcode list**  
To run BarCounter, you'll need the list of valid cell barcodes used by cellranger for analysis. This can be found in the cellranger software directory, and may vary based on your 10x Genomics application:  
```
cellranger-3.1.0/cellranger-cs/3.1.0/lib/python/cellranger/barcodes/
cellranger-4.0.0/lib/python/cellranger/barcodes/
cellranger-5.0.0/lib/python/cellranger/barcodes/
```

**2: A Well Sheet .csv file**

You will need to generate a Well Sheet .csv file to specify which wells will be demultiplexed. This .csv should have the following columns:
- well_id: An identifier for each well
- fastq_path: The path to the directory containing the HTO FASTQ files for your well
- fastq_prefix: The prefix for your well that is appended to your HTO FASTQ files (multiple lanes will be automatically identified)
- cellranger_outs: The full path to the cellranger count outs/ directory for each well

**Example well_sheet.csv**
```
well_id,bar_counts,cellranger_outs
X017-P1C1W1,/mnt/barware-manuscript/X017_fastq/,Pool-16-HTO,/mnt/barware-manuscript/code-testing/X017-P1C1W1/outs/
X017-P1C1W2,/mnt/barware-manuscript/X017_fastq/,Pool-24-HTO,/mnt/barware-manuscript/code-testing/X017-P1C1W2/outs/
X017-P1C1W3,/mnt/barware-manuscript/X017_fastq/,Pool-32-HTO,/mnt/barware-manuscript/code-testing/X017-P1C1W3/outs/
```

**3: A Sample Sheet .csv file**

The samplesheet.csv file specifies which samples are associated with which barcodes. This .csv should have the following columns:  
- sample_id: The name of each multiplexed sample
- pool_id: An identifier for the pool of samples to demultiplex
- hash_name: The name of the HTOs used for hashing
- hash_tag: The sequence of the HTO barcodes used for hashing

**example sample_sheet.csv**
```
sample_id,pool_id,hash_name,hash_tag
2735BW-MEM-1,X017-P1,HT1,GTCAACTCTTTAGCG
2735BW-MEM-2,X017-P1,HT2,TGATGGCCTATTGGG
2735BW-NIV-1,X017-P1,HT3,TTCCGCCTCTCTTTG
2735BW-NIV-2,X017-P1,HT4,AGTAAGTTCAGCGTA
2735BW-NON-1,X017-P1,HT5,AAGTATCGTTTCGCA
2735BW-NON-2,X017-P1,HT6,GGTTGCCAGATGTCA
```

With these in hand, you're ready for the BarWare pipeline.

#### Stage 1: Counting HTOs with BarCounter

A convenient wrapper script is provided in BarWare to run multiple wells in sequence using BarCounter: `01_run_BarCounter.sh`. This script has 4 parameters:
- `-b`: the *full path* to the valid barcode list file
- `-s`: the *full path* to the sample_sheet.csv file
- `-w`: the *full path* to the well_sheet.csv file
- `-o`: the *full path* of a directory to use for outputs

For example:
```
bash BarWare-pipeline/01_run_BarCounter.sh \
  -b /shared/apps/cellranger-4.0.0/lib/python/cellranger/barcodes/3M-february-2018.txt.gz
  -s $(pwd)/X017_samplesheet.csv
  -w $(pwd)/X017_WellSheet.csv \
  -o $(pwd)/X017_demultiplex_results
```

Stage 1 will generate outputs for each well:
```
<output_dir>/
  <well_id>/
    hto_counts/
      <fastq_prefix>_Tag_Counts.csv
      <fastq_prefix>_BarCounter.log
```

#### Stage 2: Demultiplexing and QC with BarMixer

BarMixer demultiplexing can be run using the `02_run_BarMixer.sh` shell script. This script has 3 parameters:
- `-s`: the *full path* to the sample_sheet.csv file
- `-w`: the *full path* to the well_sheet.csv file
- `-o`: the *full path* of a directory to use for outputs

Note that the parameters `-s`, `-w`, and `-o` should be the same for both Stage 1 and Stage 2.

```
bash BarWare-pipeline/02_run_BarMixer.sh \
  -s $(pwd)/X017_samplesheet.csv
  -w $(pwd)/X017_WellSheet.csv \
  -o $(pwd)/X017_demultiplex_results
```

Stage 2 will generate outputs for each well, and combined results for all wells. Final outputs separated by sample for downstream use are in the merged_h5/ subfolder.
```
<output_dir>/
  <well_id>/
    hto_processed/
      <well_id>_hto_category_table.csv.gz
      <well_id>_hto_count_matrix.csv.gz
      <well_id>_hto_processing_metrics.json
      <well_id>_hto_report.html
    rna_metadata/
      <well_id>.h5
      <well_id>_well_metadata_report.html
      <well_id>_well_metrics.json
  split_h5/
    <well_id>_<hash_tag>.h5
    <well_id>_multiplet.h5
    <well_id>_split_h5_metrics.json
    <well_id>_split_report.html
  merged_h5/
    merge_report.html
    <pool_id>_<sample_id>.h5
    <pool_id>_multiplet.h5
```

## Using a docker image

**Image retrieval**  
A pre-built docker image containing the BarWare pipeline can be downloaded from dockerhub using:
```
docker pull hypercompetent/barware:latest
```

**Image building**  
If you would like to re-build the Docker image, the Dockerfile is provided in the BarWare-pipeline repository:
```
cd BarWare-pipeline
docker build ./ -t barware:v1.0
```

