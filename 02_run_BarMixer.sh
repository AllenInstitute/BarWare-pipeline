#!/bin/bash

# Trap exit 1 to allow termination within the check_param() function.
trap "exit 1" TERM
export TOP_PID=$$

# Time statement function

stm() {
	local ts=$(date +"%Y-%m-%d %H:%M:%S")
	echo "["$ts"] "$1
}

# Elapsed time function

format_time() {
  local h=$(($1/60/60%24))
  local m=$(($1/60%60))
  local s=$(($1%60))
  
  printf "%02d:%02d:%02d" $h $m $s
}

elt() {
  local end_time="$(date -u +%s)"
  local split_diff="$(($end_time-$1))"
  local total_diff="$(($end_time-$2))"
  
  echo "Total time: " $(format_time $total_diff) "| Split time: " $(format_time $split_diff)
}

# Parameter check function

check_param() {
  local pflag=$1
  local pname=$2
  local pvar=$3
  
  if [ -z ${pvar} ]; then
    echo $(stm "ERROR ${pflag} ${pname}: parameter not set. Exiting.") >&2
    kill -s TERM $TOP_PID 
  else
    echo  $(stm "PARAM ${pflag} ${pname}: ${pvar}") >&2
  fi
}

# File check functions

check_file() {
  local pfile=$1
  
  if [ ! -f ${pfile} ]; then
    echo $(stm "ERROR ${pfile}: File Not Found. Exiting.") >&2
    kill -s TERM $TOP_PID
  else
    echo $(stm "Found input ${pfile}")
  fi
}

check_tenx() {
  local ptenx=$1

  local bc=${ptenx}/filtered_feature_bc_matrix/barcodes.tsv.gz
  echo $(check_file ${bc}) >&2
  local h5=${ptenx}/filtered_feature_bc_matrix.h5
  echo $(check_file ${h5}) >&2
  local mol=${ptenx}/molecule_info.h5
  echo $(check_file ${mol}) >&2
  local summary=${ptenx}/metrics_summary.csv
  echo $(check_file ${summary}) >&2

}

pipeline_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Parse command-line arguments

while getopts "s:w:o:" opt; do
  case $opt in
    s) sample_sheet="$OPTARG"
    ;;
    w) well_sheet="$OPTARG"
    ;;
    o) output_dir="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

echo $(stm "START BarcodeTender Cell Hashing")
echo $(check_param "-o" "Output Directory" ${output_dir})
echo $(check_param "-s" "Input samplesheet.csv" ${sample_sheet})
echo $(check_param "-w" "Input WellSheet.csv" ${well_sheet})
total_start_time="$(date -u +%s)"

$(check_file ${sample_sheet})
$(check_file ${well_sheet})

wells=($(cat ${well_sheet} | awk -F',' 'NR>1 {print $1}'))
counts=($(cat ${well_sheet} | awk -F',' 'NR>1 {print $2}'))
outs=($(cat ${well_sheet} | awk -F',' 'NR>1 {print $3}'))

echo $(stm "Checking Inputs")
split_start_time="$(date -u +%s)"

for count in ${counts}; do
  $(check_file ${count})
done

for out in ${outs}; do
  $(check_tenx ${out})
done

echo $(stm "Processing HTO counts per well")
split_start_time="$(date -u +%s)"

for w in ${!wells[@]}; do
  out_path=${output_dir}/${wells[$w]}/hto_processed
  mkdir -p ${out_path}

  Rscript --vanilla \
      ${pipeline_dir}/stage_02/run_hto_processing.R \
        -i ${counts[$w]} \
        -s ${sample_sheet} \
        -w ${wells[$w]} \
        -d ${out_path} \
        -o ${out_path}/${wells[$w]}_hto_report.html
done

echo $(stm "$(elt $split_start_time $total_start_time)" )

echo $(stm "Adding metadata to 10x matrix .h5 per well")
split_start_time="$(date -u +%s)"

for w in ${!wells[@]}; do
  out_path=${output_dir}/${wells[$w]}/rna_metadata
  mkdir -p ${out_path}

  Rscript --vanilla \
    ${pipeline_dir}/stage_02/run_add_tenx_rna_metadata.R \
      -i ${outs[$w]} \
      -w ${wells[$w]} \
      -d ${out_path} \
      -o ${out_path}/${wells[$w]}_well_metadata_report.html
done

echo $(stm "$(elt $split_start_time $total_start_time)" )

echo $(stm "Splitting matrices per well by sample")
split_start_time="$(date -u +%s)"

for w in ${!wells[@]}; do
  hto_processed=${output_dir}/${wells[$w]}/hto_processed
  rna_meta=${output_dir}/${wells[$w]}/rna_metadata
  out_path=${output_dir}/split_h5

  mkdir -p ${out_path}

  Rscript --vanilla \
    ${pipeline_dir}/stage_02/run_split_h5_by_hash.R \
      -i ${rna_meta}/${wells[$w]}.h5 \
      -h ${hto_processed} \
      -d ${out_path} \
      -o ${out_path}/${wells[$w]}_split_report.html
done

echo $(stm "$(elt $split_start_time $total_start_time)" )

echo $(stm "Merging matrices across wells")
split_start_time="$(date -u +%s)"

split_path=${output_dir}/split_h5
out_path=${output_dir}/merged_h5
mkdir -p ${out_path}

Rscript --vanilla \
    ${pipeline_dir}/stage_02/run_merge_h5_by_hash.R \
      -i ${split_path} \
      -d ${out_path} \
      -o ${out_path}/merge_report.html

echo $(stm "$(elt $split_start_time $total_start_time)" )
echo $(stm "END BarcodeTender Cell Hashing")
