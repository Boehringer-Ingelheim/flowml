#' @name fml_train
#' @author Kolja Becker
#' @title fml_train
#' @description Pipeline function that performs a hyperparameter screeing experiment.
#'
#' @importFrom rjson fromJSON
#' @importFrom data.table fread
#' @importFrom tibble column_to_rownames
#' @importFrom caret train trainControl
#' @importFrom utils read.csv write.table
#'
#' @include fml_grids.R
#' @include fml_format_response.R
#' @include fml_parser.R
#'
#' @keywords hyperparameter tuning, model training
#'
#' @param parser_inst instance of fml_parser class that comprises command line arguments.
#'
#' @examples
#' \dontrun{
#'   Rscript fml_interpret.R --config /path/to/config.json --data /path/to/data.csv --samples /path/to/samples_train.txt --features path/to/features.txt --trained /path/to/trained_model.rds --interpretation shap --cores 1
#'   Rscript fml_interpret.R --config /path/to/config.json --data /path/to/data.csv --samples /path/to/samples_train.txt --features path/to/features.txt --trained /path/to/trained_model.rds --interpretation permutation --cores 1
#' }
#'
#' @export
#'
fml_train = function(parser_inst){
  # pass arguments
  file.config = parser_inst$config
  file.data = parser_inst$data
  file.samples.train = parser_inst$samples_train
  file.features.train = parser_inst$features

  # read config file
  config = rjson::fromJSON(file = file.config)

  # output
  # TODO: find out how relative paths work with nf
  file.rds = paste0('./', config$fit.id, '.rds')
  file.log = paste0('./', config$fit.id, '.log')

  # data
  # NOTE: using fread because it's faster
  df.data = data.table::fread(file.data) %>%
    tibble::column_to_rownames(config$ml.sampleID)

  # samples
  list.samples = utils::read.csv(file.samples.train, header = F)$V1

  # features
  list.features = utils::read.csv(file.features.train, header = F)$V1

  # set up trainControl
  # TODO: implement other methods such as jackknife, bootstrap, ...
  trControl = caret::trainControl(
    method = config$ml.cv$method,
    number = as.numeric(config$ml.cv$fold),
    repeats = as.numeric(config$ml.cv$repeats))

  # train model
  set.seed(as.numeric(config$ml.seed))
  cv_model = caret::train(
    y = format_y(df.data[list.samples, config$ml.response], config$ml.type),
    x = df.data[list.samples, list.features, drop=F],
    method = config$ml.method,
    preProcess = config$ml.preprocess,
    trControl = trControl,
    tuneGrid = list.grids[[config$ml.cv$tune.grid]], # NOTE: if NULL tuneLength is used
    tuneLength = config$ml.cv$tune.length
  )

  # ml run time
  ml.run_time =
    cv_model$times$everything['elapsed'] + cv_model$times$final['elapsed']

  # save
  saveRDS(cv_model, file.rds)
  utils::write.table(t(
    data.frame(
      name.out = config$fit.id,
      file.data = file.data,
      file.samples.train = file.samples.train,
      file.features.train = file.features.train,
      ml.sampleID = config$ml.sampleID,
      ml.seed = config$ml.seed,
      ml.type = config$ml.type,
      ml.method = config$ml.method,
      ml.response = config$ml.response,
      ml.preProcess = config$ml.preprocess,
      ml.fold = config$ml.cv$fold,
      ml.repeats = config$ml.cv$repeats,
      ml.grid = config$ml.cv$tune.grid,
      ml.run_time = ml.run_time,
      note.log = config$note)),
    file.log, row.names = T, quote = F, col.names = F, sep='\t')

}
