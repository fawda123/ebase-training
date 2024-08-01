library(tibble)

agenda <- frame_matrix(
  ~Time, ~Topic,
   '10:00', '[Introduction](intro.qmd)',
   '3:00', 'adjourn'
)

save(agenda, file = 'data/agenda.RData')
