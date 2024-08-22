library(EBASE)
library(dplyr)
library(lubridate)
library(doParallel)
library(tidyr)
library(ggplot2)
library(tibble)
library(patchwork)

url <- 'http://tampabay.loboviz.com/cgi-data/nph-data.cgi?node=82&min_date=20210701&max_date=20210801&y=salinity,temperature,oxygen,par,pressure&data_format=text'

lobo <- read.table(url, skip = 2, sep = '\t', header = T) |> 
  select(
    DateTimeStamp = date..EST.,
    DO_obs = dissolved.oxygen..mg.L.,
    Temp = temperature..C.,
    Sal = salinity..PSU.,
    PAR = PAR..uM.m.2.sec.,
    Tide = pressure..dBar.
  ) |> 
  mutate(
    DateTimeStamp = lubridate::ymd_hms(DateTimeStamp, tz = 'America/Jamaica'),
    PAR = PAR * 0.2175, 
    Tide = Tide + 2.4
  )

vrs <- c('wind', 'air_pressure', 'air_temperature')
urls <- glue::glue('https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?product={vr}&application=NOS.COOPS.TAC.MET&begin_date=20210701&end_date=20210801&station=8726520&time_zone=LST&units=metric&format=CSV', vr = vrs)

ports <- purrr::map(urls, function(x){
  read.table(x, sep = ',', header = T) |> 
    select(1:2) |> 
    pivot_longer(cols = -Date.Time, names_to = 'Variable', values_to = 'Value') 
  }) |> 
  enframe() |> 
  unnest('value') |> 
  select(-name) |> 
  pivot_wider(names_from = Variable, values_from = Value) |> 
  rename(
    DateTimeStamp = Date.Time,
    ATemp = Air.Temperature,
    BP = Pressure,
    WSpd = Speed
  ) |> 
  mutate(
    DateTimeStamp = lubridate::ymd_hm(DateTimeStamp, tz = 'America/Jamaica')
  )

tbdat <- left_join(lobo, ports, by = 'DateTimeStamp')

# setup parallel backend
cl <- makeCluster(6)
registerDoParallel(cl)

res <- ebase(tbdat, interval = 3600, Z = tbdat$Tide, ndays = 1)

stopCluster(cl)

toplo <- res |> 
  select(
    DateTimeStamp, 
    Date, 
    Pg = P, 
    Rt = R
  ) |> 
  summarise(
    Pg = mean(Pg, na.rm = T),
    Rt = mean(Rt, na.rm = T), 
    .by = Date
  ) |> 
  mutate(
    NEM = Pg - Rt, 
    Rt = -Rt
  ) |> 
  pivot_longer(cols = c(Pg, Rt, NEM), names_to = 'Variable', values_to = 'Value')

p1 <- ggplot(toplo, aes(x = Date, y = Value, color = Variable)) +
  geom_hline(yintercept = 0) +
  geom_line() + 
  geom_point() + 
  theme_bw() + 
  labs(
    x = NULL, 
    y = expression(paste('mmol ', O [2], ' ', m^-2, d^-1)), 
    color = 'Estimate'
  )

tz <- attr(tbdat$DateTimeStamp, which = 'tzone')
lat <- 27.6594677
long <- -82.6043877

tbeco <- WtRegDO::ecometab(tbdat, DO_var = "DO_obs", tz = tz, lat = lat, long = long, depth_val = NULL, depth_vec = tbdat$Tide)

p2 <- plot(tbeco, by = 'days') + 
  geom_hline(yintercept = 0) 

p1 + p2 + plot_layout(ncol = 1, guides = 'collect')
