library(optparse)

option_list <- list(
  make_option(opt_str = c("-i","--in_h5"),
              type = "character",
              default = NULL,
              help = "Input filtered_feature_bc_matrix.h5 file",
              metavar = "character"),
  make_option(opt_str = c("-l","--in_mol"),
              type = "character",
              default = NULL,
              help = "Input molecule_info.h5 file (Ignored/Deprecated)",
              metavar = "character"),
  make_option(opt_str = c("-m","--in_mat"),
              type = "character",
              default = NULL,
              help = "Input HTO count matrix file",
              metavar = "character"),
  make_option(opt_str = c("-c","--in_tbl"),
              type = "character",
              default = NULL,
              help = "Input HTO category table file",
              metavar = "character"),
  make_option(opt_str = c("-w","--in_well"),
              type = "character",
              default = NULL,
              help = "Well",
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

if(is.null(args$in_h5)) {
  print_help(opt_parser)
  stop("No parameters supplied.")
}

if(!dir.exists(args$out_dir)) {
  dir.create(args$out_dir)
}

rmd_path <- file.path(args$out_dir,
                      paste0(args$in_well,
                             "_split_h5_by_hash.Rmd"))

file.copy(system.file("rmarkdown/split_h5_by_hash.Rmd", package = "H5weaver"),
          rmd_path,
          overwrite = TRUE)

rmarkdown::render(
  input = rmd_path,
  params = list(in_h5 = args$in_h5,
                in_mol = args$in_mol,
                in_mat = args$in_mat,
                in_tbl  = args$in_tbl,
                in_well = args$in_well,
                out_dir = args$out_dir),
  output_file = args$out_html,
  quiet = TRUE
)

file.remove(rmd_path)
