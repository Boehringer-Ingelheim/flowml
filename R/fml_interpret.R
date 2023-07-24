#' @name fml_interpret
#' @author Sebastian Malkusch
#' @title fml_interpret
#' @description Pipeline function that sets up and runs a post-hoc interpretation of an ml experiment.
#' All results are written to rds files.
#'
#' @importFrom rjson fromJSON
#' @importFrom data.table fread
#' @importFrom tibble column_to_rownames
#' @importFrom dplyr all_of mutate rename select
#' @importFrom vip vi_permute
#' @importFrom fastshap explain
#' @importFrom caret train trainControl
#' @importFrom utils read.csv
#'
#' @include fml_parser.R
#' @include fml_format_response.R
#' @include fml_categorize.R
#'
#' @keywords model interpretation, feature importance, item categorization
#'
#' @examples
#' \dontrun{
#'   Rscript fml_interpret.R --config /path/to/config.json --data /path/to/data.csv --samples /path/to/samples_train.txt --features path/to/features.txt --trained /path/to/trained_model.rds --interpretation shap --cores 1
#'   Rscript fml_interpret.R --config /path/to/config.json --data /path/to/data.csv --samples /path/to/samples_train.txt --features path/to/features.txt --trained /path/to/trained_model.rds --interpretation permutation --cores 1
#' }
#'
#' @export
#'
fml_interpret = function(){
  # get command line arguments
  parser_inst <- create_parser()

  # read config
  config_inst <- rjson::fromJSON(file = parser_inst$config)

  # read tuned model
  model_inst <- readRDS(file = parser_inst$trained)

  # read data
  data_df <- data.table::fread(parser_inst$data) %>%
    tibble::column_to_rownames(config_inst$ml.sampleID) %>%
    as.data.frame()

  # read samples
  samples_lst <- utils::read.csv(parser_inst$samples_train, header = FALSE)$V1

  # read features
  train_features_lst <- utils::read.csv(parser_inst$features, header = FALSE)$V1
  n_features <- length(train_features_lst)

  # filter data
  filtered_df <- data_df[samples_lst,] %>%
    dplyr::mutate(!!as.symbol(config_inst$ml.response) := format_y(!!as.symbol(config_inst$ml.response), config_inst$ml.type)) %>%
    dplyr::select(dplyr::all_of(append(train_features_lst, config_inst$ml.response)))


  # analysis parameters
  fml_resamples <- as.integer(config_inst$ml.interpret$n.repeats)
  fml_response <- config_inst$ml.response
  fml_mode <- config_inst$ml.type
  fml_metric <- switch(fml_mode,
                      "regression" = "rmse",
                      "classification" = "accuracy")
  fml_seed <- as.integer(config_inst$ml.seed)

  # run interpretation experiment.
  set.seed(fml_seed)
  interpret_inst <- switch (parser_inst$interpretation,
                            "permutation" = {
                              vip::vi_permute(object = model_inst,
                                              target = fml_response,
                                              metric = fml_metric,
                                              pred_wrapper = predict,
                                              train = filtered_df,
                                              smaller_is_better = TRUE,
                                              type = "difference",
                                              nsim = fml_resamples) %>%
                                dplyr::rename(Feature = Variable) %>%
                                return()
                            },
                            "shap" = {
                              fastshap::explain(object = model_inst,
                                                feature_names = train_features_lst,
                                                pred_wrapper = predict,
                                                nsim = fml_resamples,
                                                X = as.data.frame(dplyr::select(filtered_df, dplyr::all_of(train_features_lst))),
                                                newdata = NULL,
                                                adjust = FALSE) %>%
                                return()
                            },
                            stop(sprintf("Interpretation method %s is unknown. Needs to be permutation or shap.", parser_inst$interpretation))
  )

  # perform item categorization
  categorize_df <- run_abc_analysis(interpret_inst, parser_inst$interpretation)

  # save results to the multiQC section
  result_obj <- list("interpretation" = interpret_inst, "catrgorization" = categorize_df)

  path_to_result <- sprintf("./%s_interpretation_%s.rds", parser_inst$interpretation, config_inst$fit.id)
  saveRDS(result_obj, file = path_to_result)
}
