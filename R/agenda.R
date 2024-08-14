library(tibble)

agenda <- frame_matrix(
  ~Time, ~Topic,
   '10:00', '[Introduction](01_intro.qmd)',
   '10:30', '[Data Preparation](02_dataprep.qmd)',
   '11:30', 'Break',
   '12:00', '[Using EBASE](03_ebase.qmd)',
   '1:30', '[Interpreting Results](04_interpret.qmd)',
   '3:00', 'Adjourn'
)

save(agenda, file = 'data/agenda.RData')
