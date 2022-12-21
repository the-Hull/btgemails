library(crul)
library(rvest)
library(dplyr)


# Info --------------------------------------------------------------------


# Rules
## collapse spaces in last names (Mohamed Ali, Amira = amira.mohamedali@)

## paste "de" to last name
## Can drop Freiherr von / von Notz
## Cant drop von Malottki, von Storch --> concatenate



# helper functions --------------------------------------------------------

drop_prefix <- function(x, prefix){
  
  for(pf in prefix){
    x <- stringr::str_remove_all(x, paste0(" ", pf))
    
  }
  return(x)
}

add_prefix <- function(x, lastname, prefix){
  
  for(ln in lastname){
    
    idx <- grep(ln, x)
    
    x[idx] <- stringr::str_remove(x[idx], paste0(' ', prefix))
    x[idx] <- paste0(prefix, x[idx])
    
  }
  
  return(x)
}



# User / Brwowser imitieren
HEADERS <- list(
  "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36",
  "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
  "Accept-Encoding" = "gzip, deflate, br",
  "Accept-Language" = "en-US,en;q=0.9"
)

# direkt die AJAX Datenbank abgfrage abgreifen 
url <- "https://www.bundestag.de/ajax/filterlist/de/abgeordnete/biografien/862712-862712?limit=9999&view=BTBiographyList"
response <- HttpClient$new(url, header=HEADERS)$get()


# HTML infos ziehen
abgeordnete_info_raw <- response$parse() %>% 
  read_html() %>% 
  html_elements(".bt-teaser-person-text")

# parteien extrahieren
abgeordnete_partei <- abgeordnete_info_raw %>% 
  html_elements("p.bt-person-fraktion") %>% 
  html_text2(preserve_nbsp = FALSE)


# vollen namen extrahieren
abgeordnete_namen <- abgeordnete_info_raw %>% 
  html_elements("h3") %>% 
  html_text2(preserve_nbsp = FALSE)


# "leerzeichen (orte)" entfernen
abgeordnete_namen <- stringr::str_remove(abgeordnete_namen, pattern = "[ ][(].*[)]")


# fix von/de
abgeordnete_namen <- add_prefix(abgeordnete_namen, lastname = c('Storch', 'Malottki'), "von")
abgeordnete_namen <- add_prefix(abgeordnete_namen, lastname = c('Vries'), "de")
abgeordnete_namen <- drop_prefix(abgeordnete_namen, c("Freiherr von", "von"))

abgeordnete_namen


# namen bereinigen
## Mapping vector erstellen
exchange <- c(
  "Ä" = "Ae",
  "Ö" = "Oe",
  "Ü" = "Ue",
  "ä" = "ae",
  "ö" = "oe",
  "ü" = "ue",
  "ß" = "ss",
  "é" = "e",
  "ó" = "o",
  "ć" = "c",
  "ğ" = "g")

abgeordnete_namen <- stringr::str_replace_all(string = abgeordnete_namen, pattern = exchange)

# check for non-standard characters in names, should be 0
abgeordnete_namen[grep('[^\\w^ ^[:punct:]]', abgeordnete_namen, perl = TRUE)]

# grab everything up to comma, including double names
# abgeordnete_nachname <- stringr::str_extract(abgeordnete_namen, "(\\w+([- ]\\w+){0,1})(?=[,])") %>% 
#   stringr::str_remove('[ ]')
abgeordnete_nachname <- stringr::str_extract(abgeordnete_namen, "(.*)(?=[,])") %>% 
  stringr::str_remove('[ ]')



abgeordnete_titel <- stringr::str_extract_all(abgeordnete_namen, "\\w+[.]", simplify = TRUE)

# grab everything after the comma and space
abgeordnete_vorname <- stringr::str_extract(abgeordnete_namen, "(?<=[,][ ])\\w+.*") %>% 
  # remove all titles
  stringr::str_remove_all("\\w+[.][-]?[ ]?") %>% 
  # remove 2nd (NOT double) names
  stringr::str_remove_all("[ ].*")


abgeordnete_titel_lang <- apply(abgeordnete_titel, MARGIN = 1, paste, collapse = " ") %>% 
  stringr::str_trim() %>% 
  {ifelse(. == "", NA_character_, .)}

# generate emails

abgeordnete_emails <- sprintf("%s.%s@bundestag.de", abgeordnete_vorname, abgeordnete_nachname)



# Unmodifizierte Namen -----------------------------------------------------------------

btg <- abgeordnete_info_raw %>% 
  html_elements("h3") %>% 
  html_text2(preserve_nbsp = FALSE)

nachname <- stringr::str_extract(btg, ".*(?=[,])")
nachname <- stringr::str_remove(nachname, "[(].*[)]")
nachname_prefix <- stringr::str_extract(btg, "(\\bvon\\b)|(\\bFreiherr von\\b)|(\\bde\\b)")

vorname <- 
  # grab everything after last name, 
  stringr::str_remove(btg, ".*[,][ ]") %>%
  # drop all titles
  stringr::str_remove_all("\\w+[.][-]?[ ]?") %>% 
  # remove special cases with Freiherr, etc.
  stringr::str_remove("(\\bvon\\b)|(\\bFreiherr von\\b)|(\\bde\\b)")





# Zusammenfuehren ---------------------------------------------------------


kontakt <- data.frame(
  titel = abgeordnete_titel_lang,
  nachname_prefix = nachname_prefix,
  nachname = nachname,
  vorname = vorname,
  email_nachname = abgeordnete_nachname,
  email_vorname = abgeordnete_vorname,
  email = abgeordnete_emails,
  partei = abgeordnete_partei
)


# Manuell saeubern -------------------------------------------------------

# Titel Bereinigung
kontakt$vorname <- ifelse(kontakt$titel == 'W.' & !is.na(kontakt$titel), "Matthias W.", kontakt$vorname)
kontakt$titel <- ifelse(kontakt$titel == 'W.' & !is.na(kontakt$titel), NA_character_, kontakt$titel)

# Ausgeschiedene MdBs entfernen (erkennbar an Stern in Partei)
kontakt[grepl("\\*", kontakt$partei), ]

kontakt <- kontakt[!grepl("\\*", kontakt$partei), ]




# Manuell Emails anpassen -------------------------------------------------


kontakt <- kontakt %>% 
  mutate(email = case_when(
    vorname == 'Karoline'	& nachname == 'Otte' ~ 'Karo.Otte@bundestag.de',
    vorname == 'Catarina dos'	& nachname == 'Santos-Wintz' ~ 'Catarina.dossantos@bundestag.de',
    vorname == 'Jan Wenzel' & nachname ==	'Schmidt' ~ 'Jan-Wenzel.Schmidt@bundestag.de',
    vorname == 'Matthias W.' & nachname == 'Birkwald' ~ 'Matthias-W.birkwald@bundestag.de',
    vorname == 'Ingeborg'	& nachname == 'Gräßle' ~ 'Inge.Graessle@bundestag.de',
    vorname == 'Anne Monika' &	nachname == 'Spallek' ~ 'Anne-Monika.Spallek@bundestag.de',
    vorname == 'Marja-Liisa' & nachname == 'Völlers' ~ 'Marja.Voellers@bundestag.de',
    vorname == 'Alexander Graf' & nachname == 'Lambsdorff' ~ 'Alexander.GrafLambsdorff@bundestag.de',
    vorname == 'Olaf' & nachname == 'in der Beek' ~ 'Olaf.inderBeek@bundestag.de',
    TRUE ~ email)
  )




# exportieren -------------------------------------------------------------

path_out <- "./data/kontakte_bundestagsabgeordnete.xlsx"
xlsx::write.xlsx(kontakt,
                 file = path_out,
                 row.names = FALSE,
                 col.names = TRUE)
                 