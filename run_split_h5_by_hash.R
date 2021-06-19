library(optparse)

option_list <- list(
  make_option(opt_str = c("-i","--in_h5"),
              type = "character",
              default = NULL,
              help = "Input filtered_feature_bc_matrix.h5 file",
              metavar = "character"),
  make_option(opt_str = c("-h","--in_hto"),
              type = "character",
              default = NULL,
              help = "Input HTO processing results path",
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

in_pre <- sub(".h5","",basename(args$in_h5))

rmd_path <- file.path(args$out_dir,
                      paste0(in_pre,
                             "_split_h5_by_hash.Rmd"))

file.copy(system.file("split_h5_by_hash.Rmd", package = "BarMixer"),
          rmd_path,
          overwrite = TRUE)

rmarkdown::render(
  input = rmd_path,
  params = list(in_h5 = args$in_h5,
                in_hto = args$in_hto,
                out_dir = args$out_dir),
  output_file = args$out_html,
  quiet = TRUE
)

file.remove(rmd_path)
