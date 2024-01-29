#!/usr/bin/env Rscript
#
# You can learn more about package authoring with RStudio at:
#
#   http://r-pkgs.had.co.nz/
#
# Some useful keyboard shortcuts for package authoring:
#
#   Install Package:           'Ctrl + Shift + B'
#   Check Package:             'Ctrl + Shift + E'
#   Test Package:              'Ctrl + Shift + T'

library("flowml")

main = function(){
  # measure time
  start_time <- proc.time()

  # collect command line arguments
  parser_inst <-  flowml::create_parser()

  # define experiment
  pipeline_segment <- factor(x = parser_inst$pipeline_segment, levels = c("train", "validate", "bootstrap", "interpret"))

  # run experiment
  switch (as.character(pipeline_segment),
    "train" = flowml::fml_train(parser_inst),
    "validate" = flowml::fml_validate(parser_inst),
    "bootstrap" = flowml::fml_bootstrap(parser_inst),
    "interpret" = flowml::fml_interpret(parser_inst),
  )

  # log computation time
  end_time = proc.time()
  run_time = end_time - start_time

  # closing remarks
  message(sprintf("\n\nRan %s experiment in flowml in %.3f minutes.\n\n", pipeline_segment, run_time[[3]]/60))
}

main()
