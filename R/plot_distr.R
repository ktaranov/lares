####################################################################
#' Plot Target's Distribution vs Another Variable
#' 
#' Study the distribution of a target variable vs another variable. This
#' function is quite similar to the funModeling's corrplot function.
#' 
#' @param data Dataframe
#' @param target Character. Name of the Main -target- variable
#' @param values Character. Name of the Secondary variable
#' @param top Integer. Filter and plot the most n frequent for categorical values
#' @param breaks Integer. Number of splits for numerical values
#' @param custom_colours Boolean. Use custom colours function?
#' @param abc Boolean. Do you wish to sort by alphabetical order?
#' @param na.rm Boolean. Ignore NAs if needed
#' @param print Boolean. Print the table's result
#' @param save Boolean. Save the output plot in our working directory
#' @param subdir Character. Into which subdirectory do you wish to save the plot to?
#' @export
plot_distr <- function(data, target, values, 
                       top = 10, 
                       breaks = 10, 
                       custom_colours = FALSE,
                       abc = FALSE,
                       na.rm = FALSE, 
                       print = FALSE,
                       save = FALSE, 
                       subdir = NA) {
  
  require(ggplot2)
  require(gridExtra)
  require(dplyr)
  
  targets <- data[[target]]
  value <- data[[values]]
  
  targets_name <- colnames(data[target[1]])
  variable_name <- colnames(data[values[1]])
  
  if (length(targets) != length(value)) {
    message("The targets and value vectors should be the same length.")
    stop(message(paste("Currently, targets has",length(targets),"rows and value has",length(value))))
  }
  
  if (length(unique(value)) <= breaks & !is.numeric(value)) {
    message(paste0("You can't split ", values, " in ", breaks, 
                   "! Trying with ", length(unique(value)), " instead..."))
    breaks <- length(unique(value))
  }
  
  if (length(unique(targets)) > 9) {
    stop("You should use a targets variable with max 9 different value!")
  }
  
  if (is.numeric(value)) {
    value <- cut(value, quantile(value, prob = seq(0, 1, length = breaks), type = 7, na.rm = T))
  }
  
  if (length(unique(value)) > top & (is.character(value) | is.factor(value))) {
    top <- min(rbind(top, breaks))
    value <- lares::categ_reducer(value, top = top)
  }
  
  df <- data.frame(targets = targets, value = value)
  
  if (na.rm == TRUE) {
    df <- df[complete.cases(df), ]
    if (sum(is.na(df$value)) > 0) {
      breaks <- breaks + 1 
    }
  }
  
  freqs <- df %>% group_by(value, targets) %>% 
    tally() %>% arrange(desc(n)) %>% 
    mutate(p = round(100*n/sum(n),2)) %>% ungroup() %>%
    mutate(row = row_number(),
           order = ifelse(grepl("\\(|\\)", value), 
                          as.numeric(as.character(substr(gsub(",.*", "", value), 2, 100))), row))
  if (abc == TRUE) {
    freqs <- freqs %>% mutate(order = rank(as.character(value)))
  }
  
  distr <- df %>% group_by(targets) %>% 
    tally() %>% arrange(-n) %>% 
    mutate(p = round(100*n/sum(n),2), 
           pcum = cumsum(p))
  
  count <- ggplot(freqs, aes(x=reorder(as.character(value), order), y=n, 
                             fill=tolower(as.character(targets)), 
                             label=n, ymax=max(n)*1.1)) + 
    geom_col(position = "dodge") +
    geom_text(check_overlap = TRUE, position = position_dodge(0.9), size=3, vjust = -0.15) +
    labs(x = "", y = "Counter") + theme_minimal() + 
    theme(legend.position="top", legend.title=element_blank())
  
  if (length(unique(value)) >= 10) {
    count <- count + theme(axis.text.x = element_text(angle = 45, hjust=1))
  }
  
  prop <- ggplot(freqs, aes(x = reorder(as.character(value), -order), 
                            y = as.numeric(p/100),
                            fill=tolower(as.character(targets)), 
                            label = p)) + 
    geom_col(position = "fill") +
    geom_text(check_overlap = TRUE, size = 3.2,
              position = position_stack(vjust = 0.5)) +
    geom_hline(yintercept = distr$pcum[1:(nrow(distr)-1)]/100, 
               colour = "purple", linetype = "dotted", alpha = 0.8) +
    theme_minimal() + coord_flip() + guides(fill=FALSE) + 
    labs(x = "Proportions", y = "") + 
    labs(caption = paste("Variables:", targets_name, "vs.", variable_name))
  
  if (length(unique(value)) > top) {
    showed <- max(c(length(unique(value)), top))
    count <- count + labs(caption = paste("Showing only the top", showed, "frequent values"))
  }
  
  if (custom_colours == TRUE) {
    count <- count + gg_fill_customs()
    prop <- prop + gg_fill_customs()
  } else {
    count <- count + scale_fill_brewer(palette = "Blues")
    prop <- prop + scale_fill_brewer(palette = "Blues")
  }
  
  if (print == TRUE) {
    print(freqs %>% select(-order))
  }
  
  if (save == TRUE) {
    
    file_name <- paste0("viz_distr_", targets_name, ".vs.", variable_name, ".png")
    
    if (!is.na(subdir)) {
      dir.create(file.path(getwd(), subdir))
      file_name <- paste(subdir, file_name, sep="/")
    }
    
    png(file_name, height = 1500, width = 2000, res = 300)
    grid.arrange(count, prop, ncol = 1, nrow = 2)
    dev.off()
  }
  
  # Plot the result
  return(grid.arrange(count, prop, ncol = 1, nrow = 2))
  
}
