#' Rate a penguin
#'
#' Assigns a completely unjustified score out of 10. The methodology is that
#' longer names are more impressive and chinstraps get a bonus because of the
#' little hat.
#'
#' @param name Character. The penguin's name.
#' @param species Character. One of "adelie", "gentoo", "chinstrap".
#' @return A numeric score between 1 and 10.
#' @export
rate_penguin <- function(name, species = "adelie") {
  if (!is.character(name) || length(name) != 1L) {
    stop("`name` must be a single string.")
  }

  species <- tolower(species)
  bonus <- switch(species,
    chinstrap = 2,   # the hat
    gentoo    = 1,   # fast swimmer
    adelie    = 0,   # solid, dependable
    stop("Unknown species: ", species)
  )

  score <- nchar(name) / 2 + bonus
  min(max(score, 1), 10)
}

#' Rate several penguins at once
#'
#' @param names Character vector of penguin names.
#' @param species Character vector, recycled against `names`.
#' @return A data.frame of names, species and scores, best first.
#' @export
rate_colony <- function(names, species = "adelie") {
  scores <- mapply(rate_penguin, names, species)
  out <- data.frame(
    name    = names,
    species = species,
    score   = as.numeric(scores),
    stringsAsFactors = FALSE
  )
  out[order(-out$score), ]
}
