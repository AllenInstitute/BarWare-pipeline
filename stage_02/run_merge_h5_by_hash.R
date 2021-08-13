library(optparse)

option_list <- list(
  make_option(opt_str = c("-i","--in_dir"),
              type = "character",
              default = NULL,
              help = "Input directory containing HDF5 files",
              metavar = "character"),
  make_option(opt_str = c("-d","--out_dir"),
              type = "character",
              default = NULL,
              help = "Output Directory",
              metavar = "character"),
  make_option(opt_str = c("-o","--out_html"),
              type = "character",
              default = NULL,
              help = "Output HTML run summary file",
              metavar = "character")
)

opt_parser <- OptionParser(option_list = option_list)

args <- parse_args(opt_parser)

if(is.null(args$out_html)) {
  print_help(opt_parser)
  stop("ERROR: Missing parameters.")
}

if(!dir.exists(args$out_dir)) {
  dir.create(args$out_dir, recursive = TRUE)
}

rmd_path <- file.path(args$out_dir,"merge_h5_by_hash.Rmd")

copy_lgl <- file.copy(system.file("merge_h5_by_hash.Rmd", package = "BarMixer"),
                      rmd_path,
                      overwrite = TRUE)

rmarkdown::render(
  input = rmd_path,
  params = list(in_dir = args$in_dir,
                out_dir = args$out_dir),
  output_file = args$out_html,
  quiet = TRUE
)

rm_lgl <- file.remove(rmd_path)

BarMixer::stm(paste("HTML Report output:",args$out_html))
