#' @name fml_train
#' @author Kolja Becker
#' @title fml_train
#' @description Pipeline function that performs a hyper-parameter screeing experiment.
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
#' @param parser_inst instance of fml_parser class that comprises command line arguments.
#'
#' @examples
#' \dontrun{
#'   flowml::fml_train(parser_inst)
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
  file.rds = sprintf("%s/%s.rds", parser_inst$result_dir, config$fit.id)
  file.log = sprintf("%s/%s.log", parser_inst$result_dir, config$fit.id)

  # data
  # NOTE: using fread because it's faster
  df.data = data.table::fread(file.data) %>%
    tibble::column_to_rownames(config$ml.sampleID)

  # samples
  list.samples = utils::read.csv(file.samples.train, header = FALSE)$V1

  # features
  list.features = utils::read.csv(file.features.train, header = FALSE)$V1

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
    x = df.data[list.samples, list.features, drop=FALSE],
    method = config$ml.method,
    preProcess = config$ml.preprocess,
    trControl = trControl,
    tuneGrid = list.grids[[config$ml.cv$tune.grid]], # NOTE: if NULL tuneLength is used
    tuneLength = as.numeric(config$ml.cv$tune.length)
  )

  # ml run time
  ml.run_time =
    cv_model$times$everything['elapsed'] + cv_model$times$final['elapsed']

  # save
  saveRDS(cv_model, file.rds)

  list(
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
    note.log = config$note
  ) %>%
    rjson::toJSON() %>%
    write(file = file.log)

  # this code gives a warning about row names.
  # utils::write.table(t(
  #   data.frame(
  #     name.out = config$fit.id,
  #     file.data = file.data,
  #     file.samples.train = file.samples.train,
  #     file.features.train = file.features.train,
  #     ml.sampleID = config$ml.sampleID,
  #     ml.seed = config$ml.seed,
  #     ml.type = config$ml.type,
  #     ml.method = config$ml.method,
  #     ml.response = config$ml.response,
  #     ml.preProcess = config$ml.preprocess,
  #     ml.fold = config$ml.cv$fold,
  #     ml.repeats = config$ml.cv$repeats,
  #     ml.grid = config$ml.cv$tune.grid,
  #     ml.run_time = ml.run_time,
  #     note.log = config$note)),
  #   file.log,
  #   row.names = FALSE,
  #   quote = FALSE,
  #   col.names = FALSE,
  #   sep='\t')

}
