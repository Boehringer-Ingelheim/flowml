library("tidyverse")
library("usethis")

complete_vec <- c("ABCanalysis,
    ada,
    adabag,
    arm,
    bartMachine,
    bst,
    C50,
    caret,
    caTools,
    class,
    Cubist,
    data.table,
    dplyr,
    e1071,
    earth,
    elasticnet,
    evtree,
    fastICA,
    fastshap,
    foreach,
    frbs,
    furrr,
    future,
    gam,
    gbm,
    ggplot2,
    glmnet,
    gpls,
    h2o,
    hda,
    ipred,
    keras,
    kernlab,
    kknn,
    klaR,
    kohonen,
    lars,
    leaps,
    LiblineaR,
    LogicReg,
    magrittr,
    MASS,
    Matrix,
    mboost,
    mda,
    mgcv,
    monomvn,
    neuralnet,
    nnet,
    nnls,
    optparse,
    pamr,
    parallel,
    partDSA,
    party,
    partykit,
    penalized,
    penalizedLDA,
    pls,
    plyr,
    proxy,
    purrr,
    quantregForest,
    R6,
    randomForest,
    ranger,
    readr,
    rFerns,
    rjson,
    rlang,
    rpart,
    rrcov,
    rrcovHD,
    rsample,
    RSNNS,
    RWeka,
    sda,
    spls,
    stats,
    stringr,
    superpc,
    tibble,
    tidyr,
    utils,
    vbmp,
    VGAM,
    vip,
    xgboost") %>%
  stringr::str_remove_all(pattern = " ") %>%
  stringr::str_split(pattern = ",\n") %>%
  .[[1]]



suggests_vec <- c("‘C50’ ‘Cubist’ ‘LiblineaR’ ‘LogicReg’ ‘MASS’ ‘Matrix’ ‘RSNNS’ ‘RWeka’
‘VGAM’ ‘ada’ ‘adabag’ ‘arm’ ‘bartMachine’ ‘bst’ ‘caTools’ ‘class’
‘e1071’ ‘earth’ ‘elasticnet’ ‘evtree’ ‘fastICA’ ‘foreach’ ‘frbs’
‘gam’ ‘gbm’ ‘ggplot2’ ‘glmnet’ ‘gpls’ ‘h2o’ ‘hda’ ‘ipred’ ‘keras’
‘kernlab’ ‘kknn’ ‘klaR’ ‘kohonen’ ‘lars’ ‘leaps’ ‘mboost’ ‘mda’
‘mgcv’ ‘monomvn’ ‘neuralnet’ ‘nnet’ ‘nnls’ ‘pamr’ ‘partDSA’ ‘party’
‘partykit’ ‘penalized’ ‘penalizedLDA’ ‘pls’ ‘plyr’ ‘proxy’
‘quantregForest’ ‘rFerns’ ‘randomForest’ ‘ranger’ ‘rpart’ ‘rrcov’
‘rrcovHD’ ‘sda’ ‘spls’ ‘superpc’ ‘vbmp’ ‘xgboost’") %>%
  stringr::str_remove_all(pattern = "‘") %>%
  stringr::str_remove_all(pattern = "\n") %>%
  stringr::str_remove_all(pattern = " ") %>%
  stringr::str_split(pattern = "’") %>%
  .[[1]]
suggests_vec <- suggests_vec[1:length(suggests_vec)-1]

imports_vec <- complete_vec[!complete_vec %in% suggests_vec]


for (i in seq(length(imports_vec))){
  usethis::use_package(imports_vec[i], type = "Imports")
}

for (i in seq(length(suggests_vec))){
  usethis::use_package(suggests_vec[i], type = "Suggests")
}

