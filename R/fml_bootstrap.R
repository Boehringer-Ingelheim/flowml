#' @name fml_bootstrap
#' @author Sebastian Malkusch
#' @title fml_bootstrap
#' @description Pipeline function that sets up and runs a resampling experiment.
#' @details The experiment is run in parallel.
#' All results are written to files.
#'
#' @importFrom parallel detectCores
#' @importFrom future plan
#' @importFrom rjson fromJSON
#' @importFrom data.table fread
#' @importFrom tibble column_to_rownames tibble
#' @importFrom dplyr mutate select all_of
#' @importFrom furrr future_map furrr_options
#' @importFrom purrr map possibly
#' @importFrom tidyr unnest
#' @importFrom readr write_csv
#' @importFrom caret train trainControl
#' @importFrom stringr str_flatten
#' @importFrom rlang :=
#' @importFrom utils read.csv write.table
#'
#' @include fml_parser.R
#' @include fml_resampler.R
#' @include fml_format_response.R
#' @include fml_resample.R
#'
#' @param parser_inst Instance of fml_parser class that comprises command line arguments.
#' @return none
#'
#' @keywords bootstrap, resmapling, permutation, hypothesis testing
#'
#'
#' @examples
#' \dontrun{
#'   Rscript fml_bootstrap.R --config /path/to/config.json --data /path/to/data.csv --samples /path/to/samples_train.txt --features path/to/features.txt --trained /path/to/trained_model.rds --permutation none --cores 1
#'   Rscript fml_bootstrap.R --config /path/to/config.json --data /path/to/data.csv --samples /path/to/samples_train.txt --features path/to/features.txt --trained /path/to/trained_model.rds --permutation response --cores 1
#'   Rscript fml_bootstrap.R --config /path/to/config.json --data /path/to/data.csv --samples /path/to/samples_train.txt --features path/to/features.txt --trained /path/to/trained_model.rds --permutation features --cores 1 --extended_features /path/to/extended_features.txt
#' }
#'
#' @export
#'
fml_bootstrap = function(parser_inst){
  # set up environment for parallel computing
  n_cores <- parallel::detectCores()
  if(parser_inst$cores == 1){
    print("running sequential")
    future::plan(strategy = "sequential")
  }
  else if(n_cores < parser_inst$cores){
    print(sprintf("running in parallel on %i cores", n_cores))
    future::plan(strategy = "multisession", workers = n_cores)
  }else{
    print(sprintf("running in parallel on %i cores", parser_inst$cores))
    future::plan(strategy = "multisession", workers = parser_inst$cores)
  }

  # define start time
  start_time <- Sys.time()

  # read config
  config_inst <- rjson::fromJSON(file = parser_inst$config)

  # read model
  model_inst <- readRDS(file = parser_inst$trained)

  # read data
  data_df <- data.table::fread(parser_inst$data) %>%
    tibble::column_to_rownames(config_inst$ml.sampleID) %>%
    as.data.frame()

  # read samples
  samples_lst <- utils::read.csv(parser_inst$samples_train, header = FALSE)$V1

  # read features
  train_features_lst <- utils::read.csv(parser_inst$features, header = FALSE)$V1
  resample_features_lst <- c()
  if(parser_inst$permutation == "features"){
    resample_features_lst <- utils::read.csv(parser_inst$extended_features, header = FALSE)$V1
  }
  complete_features_lst <- append(train_features_lst, resample_features_lst)
  n_features <- length(train_features_lst)
  # filter data
  filtered_df <- switch (parser_inst$permutation,
                         'none' = {
                           data_df[samples_lst,] %>%
                             dplyr::mutate(!!as.symbol(config_inst$ml.response) := format_y(!!as.symbol(config_inst$ml.response), config_inst$ml.type)) %>%
                             dplyr::select(dplyr::all_of(append(train_features_lst, config_inst$ml.response))) %>%
                             return()
                         },
                         'response' = {
                           data_df[samples_lst,] %>%
                             dplyr::mutate(!!as.symbol(config_inst$ml.response) := format_y(!!as.symbol(config_inst$ml.response), config_inst$ml.type)) %>%
                             dplyr::select(dplyr::all_of(append(train_features_lst, config_inst$ml.response))) %>%
                             return()
                         },
                         'features' = {
                           data_df[samples_lst,] %>%
                             dplyr::mutate(!!as.symbol(config_inst$ml.response) := format_y(!!as.symbol(config_inst$ml.response), config_inst$ml.type)) %>%
                             dplyr::select(dplyr::all_of(append(complete_features_lst, config_inst$ml.response))) %>%
                             return()
                         },
                         stop(sprintf("Permutation method %s is unknown. Needs to be none, features or response.", parser_inst$permutation))
  )


  # run permutation experiment
  bootstrap_df <- tibble::tibble(permutations = seq(as.integer(config_inst$ml.bootstrap$n.permutations)), seed = as.integer(config_inst$ml.seed) + seq(as.integer(config_inst$ml.bootstrap$n.permutations))) %>%
    dplyr::mutate(permutation_type = parser_inst$permutation) %>%
    dplyr::mutate(resample_obj = furrr::future_map(.options = furrr::furrr_options(seed = TRUE), .x = seed, .f = purrr::possibly(.f = create_resample_experiment, otherwise = NULL), filtered_df, parser_inst,  model_inst, config_inst, n_features)) %>%
    dplyr::mutate(metrics = purrr::map(.x = resample_obj, .f = purrr::possibly(.f = function(x){x$metrics_df}, otherwise = NULL))) %>%
    dplyr::mutate(confusion = purrr::map(.x = resample_obj, .f = purrr::possibly(.f = function(x){x$confusion_df}, otherwise = NULL)))

  # extract metrics
  metrics_df <- bootstrap_df %>%
    dplyr::select(permutation_type, permutations, seed, metrics) %>%
    tidyr::unnest(metrics)

  # This result will go to the multiQC section
  path_to_metrics_file <- sprintf("./%s_permute_%s_bootstrap_metrics.csv", config_inst$fit.id,  parser_inst$permutation)
  readr::write_csv(metrics_df, path_to_metrics_file)


  # write confusion
  if(config_inst$ml.type == "classification"){
    confusion_df <- bootstrap_df %>%
      dplyr::select(permutation_type, permutations, seed, confusion) %>%
      tidyr::unnest(confusion)
    # This result will go to the multiQC section
    path_to_confusion_file <- sprintf("./%s_permute_%s_bootstrap_confusion.csv", config_inst$fit.id,  parser_inst$permutation)
    readr::write_csv(confusion_df, path_to_confusion_file)
  }

  # log computation time
  end_time = Sys.time()
  run_time = end_time - start_time

  # save experimental conditions
  # may be redundant, same as log in fml_train

  extended_features_file <- "null"
  if(!is.null(parser_inst$extended_features)){
    extended_features_file <- parser_inst$extended_features
  }

  file.log = sprintf("./%s_permute_%s_bootstrap.log", config_inst$fit.id,  parser_inst$permutation)
  data.frame(
    name.out = config_inst$fit.id,
    file.data = parser_inst$data,
    file.samples.train = parser_inst$samples,
    file.features.train = parser_inst$features,
    file.features.resample = extended_features_file,
    ml.model = parser_inst$trained,
    ml.seed = config_inst$ml.seed,
    ml.type = config_inst$ml.type,
    ml.method = config_inst$ml.method,
    ml.response = config_inst$ml.response,
    ml.preProcess = stringr::str_flatten(config_inst$ml.preprocess, collapse = "; "),
    boot.permutation.method = parser_inst$permutation,
    boot.n.resamples = config_inst$ml.bootstrap$n.resamples,
    boot.n.permutations = config_inst$ml.bootstrap$n.permutations,
    boot.n.cores = parser_inst$cores,
    boot.run_time = sprintf("%.3f", run_time),
    note.log = config_inst$note) %>%
    t() %>%
    utils::write.table(file.log, row.names = TRUE, quote = FALSE, col.names = FALSE, sep='\t')

  # closing remarks
  cat(sprintf("\n\nRan bootstrap experiment with permutation type %s in %.3f seconds on %i cores.\n%s\n", parser_inst$permutation, run_time, parser_inst$cores, config_inst$note))
}
