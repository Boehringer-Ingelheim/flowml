library("tidyverse")

## package lists
complete_vec <- c("ABCanalysis",
    "ada",
    "adabag",
    "arm",
    "bartMachine",
    "bst",
    "C50",
    "caret",
    "caTools",
    "class",
    "Cubist",
    "data.table",
    "dplyr",
    "e1071",
    "earth",
    "elasticnet",
    "evtree",
    "fastICA",
    "fastshap",
    # "flowml",
    "foreach",
    "frbs",
    "furrr",
    "future",
    "gam",
    "gbm",
    "ggplot2",
    "glmnet",
    "gpls",
    "hda",
    "ipred",
    "kernlab",
    "kknn",
    "klaR",
    "kohonen",
    "lars",
    "leaps",
    "LiblineaR",
    "LogicReg",
    "magrittr",
    "MASS",
    "Matrix",
    "mboost",
    "mda",
    "mgcv",
    "monomvn",
    "neuralnet",
    "nnet",
    "nnls",
    "optparse",
    "pamr",
    "parallel",
    "partDSA",
    "party",
    "partykit",
    "penalized",
    "penalizedLDA",
    "pls",
    "proxy",
    "purrr",
    "quantregForest",
    "R6",
    "randomForest",
    "ranger",
    "readr",
    "rFerns",
    "rjson",
    "rlang",
    "rpart",
    "rrcov",
    "rrcovHD",
    "rsample",
    "RSNNS",
    "sda",
    "spls",
    "stats",
    "stringr",
    "superpc",
    "tibble",
    "tidyr",
    "utils",
    "vbmp",
    "VGAM",
    "vip",
    "xgboost")

package_str <- ""
for (i in seq(length(complete_vec))){
  package_str <- sprintf("%sr-%s=%s,",package_str, complete_vec[i], packageVersion(complete_vec[i]))
}

print(package_str)
