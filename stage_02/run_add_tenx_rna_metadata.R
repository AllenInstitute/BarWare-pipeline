library(optparse)

option_list <- list(
  make_option(opt_str = c("-i","--in_tenx"),
              type = "character",
              default = NULL,
              help = "Input 10x outs/ path",
              metavar = "character"),
  make_option(opt_str = c("-w","--in_well"),
              type = "character",
              default = NULL,
              help = "Well",
              metavar = "character"),
  make_option(opt_str = c("-s","--in_sample_sheet"),
              type = "character",
              default = NULL,
              help = "Sample Sheet",
              metavar = "character"),
  make_option(opt_str = c("-d","--out_dir"),
              type = "character",
              default = NULL,
              help = "Output directory",
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

rmd_loc <- file.path(args$out_dir,
                     paste0(args$in_well,
                            "_add_tenx_rna_metadata.Rmd"))

copy_lgl <- file.copy(system.file("add_tenx_rna_metadata.Rmd", package = "BarMixer"),
                      rmd_loc,
                      overwrite = TRUE)

rmarkdown::render(
  input = rmd_loc,
  params = list(in_tenx = args$in_tenx,
                in_well = args$in_well,
                in_sample = args$in_sample_sheet,
                out_dir = args$out_dir),
  output_file = args$out_html,
  quiet = TRUE
)

rm_lgl <- file.remove(rmd_loc)

BarMixer::stm(paste("HTML Report output:",args$out_html))
