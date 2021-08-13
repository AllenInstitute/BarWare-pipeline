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
    echo $(stm "Found input ${pfile}") >&2
  fi
}

pipeline_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Parse command-line arguments

while getopts "b:s:w:o:" opt; do
  case $opt in
    b) barcode_list="$OPTARG"
    ;;
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

echo $(stm "START BarWare HTO Counting")
echo $(check_param "-b" "Valid Cell Barcode List" ${barcode_list})
echo $(check_param "-o" "Output Directory" ${output_dir})
echo $(check_param "-s" "Input samplesheet.csv" ${sample_sheet})
echo $(check_param "-w" "Input WellSheet.csv" ${well_sheet})
total_start_time="$(date -u +%s)"

echo $(stm "Checking Inputs")
split_start_time="$(date -u +%s)"

$(check_file ${barcode_list})
$(check_file ${sample_sheet})
$(check_file ${well_sheet})

wells=($(cat ${well_sheet} | awk -F',' 'NR>1 {print $1}'))
fq_paths=($(cat ${well_sheet} | awk -F',' 'NR>1 {print $2}'))
fq_prefixes=($(cat ${well_sheet} | awk -F',' 'NR>1 {print $3}'))

if [ ! -d ${output_dir} ]; then
  mkdir -p ${output_dir}
fi

# echo $(stm "$(elt $split_start_time $total_start_time)" )
# echo $(stm "Formatting Valid Barcode list")
# split_start_time="$(date -u +%s)"
# 
# barlist_path=${output_dir}/BarCounter_valid_bc_list.txt
# 
# cat ${barcode_list} \
#   | sed 's/-1//g' \
#   > ${barlist_path}

echo $(stm "$(elt $split_start_time $total_start_time)" )
echo $(stm "Building Taglist")
split_start_time="$(date -u +%s)"

taglist_path=${output_dir}/BarCounter_taglist.csv

cat ${sample_sheet} \
  | awk -F',' -v OFS=',' \
    'NR>1 { if(NF==4) { print $4,$3 } }' \
  > ${taglist_path}

echo $(stm "$(elt $split_start_time $total_start_time)" )
echo $(stm "Running BarCounter")
split_start_time="$(date -u +%s)"

for w in ${!wells[@]}; do
  well_out=${output_dir}/${wells[$w]}/hto_counts
  mkdir -p ${well_out}

  r1=$(ls -1 ${fq_paths[$w]}/${fq_prefixes[$w]}*R1*.fastq.gz | tr '\n' ',')
  r2=$(ls -1 ${fq_paths[$w]}/${fq_prefixes[$w]}*R2*.fastq.gz | tr '\n' ',')
  
  ${pipeline_dir}/BarCounter-release/barcounter \
    -w ${barcode_list} \
    -t ${taglist_path} \
    -1 ${r1} \
    -2 ${r2} \
    -o ${well_out}

  echo $(stm "$(elt $split_start_time $total_start_time)" )

done

echo $(stm "$(elt $split_start_time $total_start_time)" )
echo $(stm "END BarWare HTO Counting")
