

# train
library("flowml")

parser_inst <-  flowml::create_parser()


parser_inst$pipeline_segment <- "train"
parser_inst$config <- flowml::fml_example(file = "reg_config.json")
parser_inst$data <- flowml::fml_example(file = "reg_data.csv")
parser_inst$samples_train <- flowml::fml_example(file = "reg_samples_train.txt")
parser_inst$samples_test <- flowml::fml_example(file = "reg_samples_test.txt")
parser_inst$features <- flowml::fml_example(file = "reg_features.txt")
parser_inst$extended_features <- flowml::fml_example(file = "reg_features_extended.txt")
parser_inst$result_dir <- tempdir()

flowml::fml_train(parser_inst = parser_inst)


# validate
library("flowml")

parser_inst <-  flowml::create_parser()


parser_inst$pipeline_segment <- "validate"
parser_inst$config <- flowml::fml_example(file = "reg_config.json")
parser_inst$data <- flowml::fml_example(file = "reg_data.csv")
parser_inst$samples_train <- flowml::fml_example(file = "reg_samples_train.txt")
parser_inst$samples_test <- flowml::fml_example(file = "reg_samples_test.txt")
parser_inst$features <- flowml::fml_example(file = "reg_features.txt")
parser_inst$extended_features <- flowml::fml_example(file = "reg_features_extended.txt")
parser_inst$trained <- flowml::fml_example(file = "reg_fit.rds")
parser_inst$permutation <- "none"
parser_inst$result_dir <- tempdir()

flowml::fml_validate(parser_inst = parser_inst)

# bootstrap
library("flowml")

parser_inst <-  flowml::create_parser()


parser_inst$pipeline_segment <- "bootstrap"
parser_inst$config <- flowml::fml_example(file = "reg_config.json")
parser_inst$data <- flowml::fml_example(file = "reg_data.csv")
parser_inst$samples_train <- flowml::fml_example(file = "reg_samples_train.txt")
parser_inst$samples_test <- flowml::fml_example(file = "reg_samples_test.txt")
parser_inst$features <- flowml::fml_example(file = "reg_features.txt")
parser_inst$extended_features <- flowml::fml_example(file = "reg_features_extended.txt")
parser_inst$trained <- flowml::fml_example(file = "reg_fit.rds")
parser_inst$permutation <- "none"
parser_inst$result_dir <- tempdir()

flowml::fml_bootstrap(parser_inst = parser_inst)

# interpret
library("flowml")

parser_inst <-  flowml::create_parser()


parser_inst$pipeline_segment <- "interpret"
parser_inst$config <- flowml::fml_example(file = "reg_config.json")
parser_inst$data <- flowml::fml_example(file = "reg_data.csv")
parser_inst$samples_train <- flowml::fml_example(file = "reg_samples_train.txt")
parser_inst$samples_test <- flowml::fml_example(file = "reg_samples_test.txt")
parser_inst$features <- flowml::fml_example(file = "reg_features.txt")
parser_inst$extended_features <- flowml::fml_example(file = "reg_features_extended.txt")
parser_inst$trained <- flowml::fml_example(file = "reg_fit.rds")
parser_inst$interpretation <- "shap"
parser_inst$result_dir <- tempdir()

flowml::fml_interpret(parser_inst = parser_inst)


