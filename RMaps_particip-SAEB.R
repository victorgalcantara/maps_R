# Maps : participa��o de escolas no SAEB
# Author: Victor G Alcantara
# date : 21.11.21

# 0. Packages and setup -------------------------------------------------------

library(tidyverse)
library(readxl)
library(geobr)
require(sf)

wd <- "C:/Users/Victor/estatistica/dados/"
setwd(wd)

# 1. Import data --------------------------------------------------------------
# Escolas no SAEB2017, Escolas no cat�logo INEP,

saeb2017 <- read_csv("EDUCACAO/SAEB/2017/DADOS/TS_ESCOLA.csv")

catalogo  <-  read_delim("EDUCACAO/catalogo_esc.csv", delim = ";")

Censo2016  <-  read_delim("EDUCACAO/CENSO/2016/DADOS/ESCOLAS.csv",
                          delim = "|")

muniRJ <- read_municipality(code_muni = "RJ", year = 2017)

Brasil <- read_state(year = 2017)

# 2. Data management -------------------------------------------------------

#SAEB

saeb_brasil <- saeb2017 %>% select(ID_ESCOLA,ID_UF,
                               ID_MUNICIPIO, MEDIA_9EF_LP, MEDIA_9EF_MT, 
                               ID_DEPENDENCIA_ADM, NIVEL_SOCIO_ECONOMICO,ID_DEPENDENCIA_ADM) 

saeb_rj <- saeb2017 %>% select(ID_ESCOLA,ID_UF,
                                   ID_MUNICIPIO, MEDIA_9EF_LP, MEDIA_9EF_MT, 
                                   ID_DEPENDENCIA_ADM, NIVEL_SOCIO_ECONOMICO,
                                   ID_DEPENDENCIA_ADM) %>%
  filter(ID_UF == '33') # P�blicas: ID_DEPENDENCIA_ADM == c(1,2,3)

saeb_rj <- mutate(saeb_rj, desempenho = (MEDIA_9EF_LP+MEDIA_9EF_LP)/2)

saeb_brasil <- mutate(saeb_brasil, desempenho = (MEDIA_9EF_LP+MEDIA_9EF_LP)/2)

#Cat�logo

catalogo <- catalogo %>% select(UF,`C�digo INEP`, Munic�pio,
                                `Categoria Administrativa`) 

# Censo

censo_brasil <- Censo2016 %>% select(CO_ENTIDADE,NO_ENTIDADE, CO_UF,CO_MUNICIPIO) 

censo_rj <- Censo2016 %>% select(CO_ENTIDADE,NO_ENTIDADE, CO_UF,CO_MUNICIPIO) %>%
  filter(CO_UF == "33") #`Categoria Administrativa` == 'P�blica'


# Merge data
saeb_rj <- merge(saeb_rj,muniRJ, by.x = "ID_MUNICIPIO", by.y = "code_muni",
                all.x = T, all.y = T)

censo_rj <- merge(censo_rj,muniRJ, by.x = "CO_MUNICIPIO", by.y = "code_muni",
                  all.x = T, all.y = T)

# Computando frequ�ncias

freq_aval_muni <- table(saeb_rj$name_muni)
freq_aval_muni <- as.vector(freq_aval_muni)

sum(freq_aval_muni) #H� c�digo de munic�pios na base do SAEB diferentes da base do cat�logo

freq_absol_muni <- table(censo_rj$name_muni)
freq_absol_muni <- as.vector(freq_absol_muni)

#### Frequencies by states

freq_aval_states <- table(saeb_brasil$ID_UF)
freq_aval_states <- as.vector(freq_aval_states)

sum(freq_aval_states) #H� c�digo de munic�pios na base do SAEB diferentes da base do cat�logo

freq_absol_states <- table(censo_brasil$CO_UF)
freq_absol_states <- as.vector(freq_absol_states)

sum(freq_absol_states)

# Adicionando qtds Escolas participantes, Escolas no cat�logo e propor��o relativa
# de escolas participantes por munic�pios

muniRJ <- mutate(muniRJ, "escolas_absoluto" = freq_absol_muni)

muniRJ <- mutate(muniRJ, "escolas_aval" = freq_aval_muni)

muniRJ <- mutate(muniRJ, freq_rel = round(freq_aval_muni*100/freq_absol_muni, 1))

# de escolas por Estados

Brasil <- mutate(Brasil, "escolas_absoluto" = freq_absol_states)

Brasil <- mutate(Brasil, "escolas_aval" = freq_aval_states)

Brasil <- mutate(Brasil, freq_rel_states = round(freq_aval_states*100/freq_absol_states, 1))

##### Nova var com n�veis de participa��o

muniRJ$nivel_particip <- cut(muniRJ$freq_rel,
                             breaks = c(0,5, 25, 50, 75,100),
                             labels = c("Muito Baixa (< 0.05)", "Baixa (0.05 - 0.25)",
                                        "M�dia (0.25 - 0.50)", "Alta (0.50 - 0.75)", "Muito Alta (> 0.75)"),
                             ordered_result = TRUE, # Try without this #
                             right = FALSE) # Try without this (default is TRUE) #

Brasil$nivel_particip <- cut(Brasil$freq_rel_states,
                             breaks = c(0,5, 25, 50, 75,100),
                             labels = c("Muito Baixa (< 0.05)", "Baixa (0.05 - 0.25)",
                                        "M�dia (0.25 - 0.50)", "Alta (0.50 - 0.75)", "Muito Alta (> 0.75)"),
                             ordered_result = TRUE, # Try without this #
                             right = FALSE) # Try without this (default is TRUE) #

# 3. Maps ---------------------------------------------------------------------

# We have to remove axis from the ggplot layers
no_axis <- theme(axis.title=element_blank(),
                 axis.text=element_blank(),
                 axis.ticks=element_blank())

#### Mapas de participa��o

# Mapa Munic�pios

ggplot() +
  geom_sf(data=muniRJ, aes(fill=nivel_particip), color= "Black", size=0.01) + #try color = "Grey"
  labs(title="Participa��o de Escolas P�blicas no SAEB", subtitle = "Munic�pios do RJ, 2017", size=8,
       caption = "Fonte: Instituto de Pesquisas Educacionais An�sio Teixeira (INEP)") +
  scale_fill_manual(values = heat.colors(5, alpha = 1.0), name="N�vel de participa��o \nPropor��o relativa ao Munic�pio") +
  theme_minimal() +
  no_axis

# Mapa Brasil

ggplot() +
  geom_sf(data=Brasil, aes(fill=nivel_particip), color= "Black", size=0.01) + #try color = "Grey"
  labs(title="Participa��o de Escolas P�blicas no SAEB", subtitle = "Estados do Brasil, 2017", size=8,
       caption = "Fonte: Instituto de Pesquisas Educacionais An�sio Teixeira (INEP)") +
  scale_fill_manual(values = heat.colors(5, alpha = 1.0), name="N�vel de participa��o \nPropor��o relativa ao Estado") +
  theme_minimal() +
  no_axis

# Mapas de desempenho

mean_rj <- saeb_rj %>% group_by(ID_MUNICIPIO) %>% 
  summarize(media = mean(desempenho, na.rm = T))

muniRJ <- merge(muniRJ, mean_rj, by.x = "code_muni",by.y = "ID_MUNICIPIO")

ggplot() +
  geom_sf(data=muniRJ, aes(fill=media), color= "Black", size=0.01) + #try color = "Grey"
  labs(title="Participa��o de Escolas P�blicas no SAEB", subtitle = "Munic�pios do RJ, 2017", size=8,
       caption = "Fonte: Instituto de Pesquisas Educacionais An�sio Teixeira (INEP)") +
  scale_fill_distiller(name="N�vel de participa��o \nPropor��o relativa ao Munic�pio") +
  theme_minimal() +
  no_axis

mean_brasil <- saeb_brasil %>% group_by(ID_UF) %>% 
  summarize(media = mean(desempenho, na.rm = T))

Brasil <- merge(Brasil, mean_brasil, by.x = "code_state",by.y = "ID_UF")

ggplot() +
  geom_sf(data=Brasil, aes(fill=media), color= "Black", size=0.01) + #try color = "Grey"
  labs(title="M�dia de desempenho das Escolas no SAEB", subtitle = "Estados do Brasil, 2017", size=8,
       caption = "Fonte: Instituto de Pesquisas Educacionais An�sio Teixeira (INEP)") +
  scale_fill_distiller(name="M�dia de desempenho \nRelativa ao Estado") +
  theme_minimal() +
  no_axis
