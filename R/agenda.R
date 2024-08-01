library(tibble)

agenda <- frame_matrix(
  ~Time, ~Topic,
   '10:00', '[R Basics](rbasics.qmd)',
   '11:00', '[Data Preparation](dataprep.qmd)',
   '12:00', 'Lunch',
   '1:00', '[Using EBASE](ebase.qmd)',
   '2:00', '[Interpreting Results](interpret.qmd)',
   '3:00', 'adjourn'
)

save(agenda, file = 'data/agenda.RData')
