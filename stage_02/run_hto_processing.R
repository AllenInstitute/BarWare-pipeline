library(optparse)

option_list <- list(
  make_option(opt_str = c("-i","--in_file"),
              type = "character",
              default = NULL,
              help = "Input HTO Tag_Counts.csv file",
              metavar = "character"),
  make_option(opt_str = c("-s","--in_samples"),
              type = "character",
              default = NULL,
              help = "Input HTO SampleSheet.csv",
              metavar = "character"),
  make_option(opt_str = c("-w","--in_well"),
              type = "character",
              default = NULL,
              help = "Input WellID",
              metavar = "character"),
  make_option(opt_str = c("-c","--in_min_cutoff"),
              type = "character",
              default = NULL,
              help = "(Optional) Min. Cutoff value",
              metavar = "character"),
  make_option(opt_str = c("-e","--in_eel"),
              type = "character",
              default = NULL,
              help = "(Optional) Expect equal loading (TRUE/FALSE)",
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

rmd_path <- file.path(args$out_dir,
                      paste0(args$in_well,
                             "_hto_processing.Rmd"))

copy_lgl <- file.copy(system.file("hto_processing.Rmd", package = "BarMixer"),
                      rmd_path,
                      overwrite = TRUE)

rmarkdown::render(
  input = rmd_path,
  params = list(in_file = args$in_file,
                in_samples  = args$in_samples,
                in_well = args$in_well,
                in_min_cutoff = args$in_min_cutoff,
                in_eel = args$in_eel,
                out_dir = args$out_dir),
  output_file = args$out_html,
  quiet = TRUE
)

rm_lgl <- file.remove(rmd_path)

BarMixer::stm(paste("HTML Report output:",args$out_html))
