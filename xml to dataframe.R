library(tidyverse)
library(xml2)
library(magrittr)

#create some blank tibbles
data <- tibble()
categories <- tibble()
mechanics <- tibble()


#loop through potential game id's and hit the api to extract data
for(i in 1:1000){
  
  #read the xml file
  doc <- read_xml(paste0("https://www.boardgamegeek.com/xmlapi2/thing?id=", i, "&stats=1"))
  
  #pre-identify the number of votes in the best number of players poll
  best <- doc %>% xml_find_all("//items/item/poll/results/result") %>% xml_attr("value") == "Best"
  numvotes <- doc %>% xml_find_all("//items/item/poll/results/result") %>% xml_attr("numvotes") %>% as.numeric()
  
  #gather all of the game-level data
  data <- data %>% 
    bind_rows({
      tibble(
        id = doc %>% xml_find_all("//items/item") %>% xml_attr("id"),
        thumbnail = doc %>% xml_find_all("//items/item/thumbnail") %>% xml_text(),
        name = doc %>% xml_find_first("//items/item/name") %>% xml_attr("value"),
        description = doc %>% xml_find_first("//items/item/description") %>% xml_text(),
        yearpublished = doc %>% xml_find_first("//items/item/yearpublished") %>% xml_attr("value"),
        minplayers = doc %>% xml_find_first("//items/item/minplayers") %>% xml_attr("value"),
        maxplayers = doc %>% xml_find_first("//items/item/maxplayers") %>% xml_attr("value"),
        bestplayers = which.max(numvotes[best & numvotes > 0]),
        playingtime = doc %>% xml_find_first("//items/item/playingtime") %>% xml_attr("value"),
        minplaytime = doc %>% xml_find_first("//items/item/minplaytime") %>% xml_attr("value"),
        maxplaytime = doc %>% xml_find_first("//items/item/maxplaytime") %>% xml_attr("value"),
        minage = doc %>% xml_find_first("//items/item/minage") %>% xml_attr("value"),
        usersrated = doc %>% xml_find_first("//items/item//statistics/ratings/usersrated") %>% xml_attr("value"),
        average = doc %>% xml_find_first("//items/item//statistics/ratings/average") %>% xml_attr("value"),
        stddev = doc %>% xml_find_first("//items/item//statistics/ratings/stddev") %>% xml_attr("value"),
        numweights = doc %>% xml_find_first("//items/item//statistics/ratings/numweights") %>% xml_attr("value"),
        averageweight = doc %>% xml_find_first("//items/item//statistics/ratings/averageweight") %>% xml_attr("value")
      ) %>% 
        mutate_at(vars(-thumbnail, -name, -description), as.numeric)
    })
  
   
  
  
  #drill into categories and mechanics
  type_cat <- doc %>% xml_find_all("//items/item/link") %>% xml_attr("type") == "boardgamecategory"
  type_mech <- doc %>% xml_find_all("//items/item/link") %>% xml_attr("type") == "boardgamemechanic"
  values <- doc %>% xml_find_all("//items/item/link") %>% xml_attr("value")
  
  #store all possible categories for this game
  categories <- categories %>% 
    bind_rows({
      tibble(
        id = doc %>% xml_find_all("//items/item") %>% xml_attr("id") %>% as.numeric(),
        category = values[type_cat]
      )
    })
  
  #store all possible mechanics
  mechanics <- mechanics %>% 
    bind_rows({
      tibble(
        id = doc %>% xml_find_all("//items/item") %>% xml_attr("id") %>% as.numeric(),
        mechanic = values[type_mech]
      )
    })
  
  #sleep so we don't overload the api
  Sys.sleep(2)
}
rm(doc, type_cat, type_mech, values, numvotes, best, i)

saveRDS(data, "data/data.rds")
saveRDS(categories, "data/categories.rds")
saveRDS(mechanics, "data/mechanics.rds")


#append the first two principal components of separate analyses on categories and mechanics
data <- data %>% 
  select(-contains("_PC")) %>% 
  #Categories
  left_join({
    cat_dummies <- categories %>% 
      mutate(temp = 1) %>% 
      spread(category, temp, fill = 0)
    
    cat_dummies %>% 
      select(-id) %>% 
      princomp() %>% 
      extract2("scores") %>% 
      as_tibble() %>% 
      bind_cols(cat_dummies) %>% 
      select(id, Category_PC1 = Comp.1, Category_PC2 = Comp.2)
  }, by = "id") %>% 
  #Mechanics
  left_join({
    mech_dummies <- mechanics %>% 
      mutate(temp = 1) %>% 
      spread(mechanic, temp, fill = 0)
    
    mech_dummies %>% 
      select(-id) %>% 
      princomp() %>%
      extract2("scores") %>% 
      as_tibble() %>% 
      bind_cols(mech_dummies) %>% 
      select(id, Mechanic_PC1 = Comp.1, Mechanic_PC2 = Comp.2)
  }, by = "id")

saveRDS(data, "data/data.rds")
