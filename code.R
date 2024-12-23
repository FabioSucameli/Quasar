
# Caricamento delle librerie
library(dplyr)     # Per manipolare i dati
library(ggplot2)   # Per creare grafici
library(corrplot)  # Per visualizzare matrici di correlazione come heatmap
library(psych)     # Fornisce funzioni per analisi psicometriche
library(tidyr)     # Per riorganizzare i dati
library(gRim)      # Per modelli grafici
library(gridExtra) # Per modelli grafici
library(igraph)    # Per operazioni su grafi
library(qgraph)    # Per visualizzare grafi di correlazione e reti grafiche
library(glasso)    # Per la stima di grafi con Lasso 
library(bnlearn)   # Per l'apprendimento di strutture di Reti Bayesiane 

# Caricamento del dataset
dataset <- read.csv("SDSS_QSO.csv")

# Dimensione iniziale del dataset
cat("Dimensione del dataset iniziale:", dim(dataset), "\n")

summary(dataset)

# Pulizia dei dati
dataset_cleaned <- dataset %>%
  filter(Mp > -30 & Mp < 0 & z > 0) %>%  
  filter(ROSAT != -9, FIRST >= 0)        

# Rimuove valori mancanti
dataset_cleaned <- na.omit(dataset_cleaned)

cat("Dimensione del dataset dopo la pulizia:", dim(dataset_cleaned), "\n")

non_numeric_vars <- names(dataset_cleaned)[!sapply(dataset_cleaned, is.numeric)]
cat("Colonne non numeriche:\n", non_numeric_vars, "\n")

# Divisone SDSS gestendo sia il separatore "+" che "-"
dataset_cleaned <- dataset_cleaned %>%
  separate(SDSS, into = c("RA", "DEC"), sep = "[+-]", remove = FALSE, fill = "right") %>%
  mutate(
    DEC_sign = ifelse(grepl("\\+", SDSS), "+", "-"), 
    DEC = paste0(DEC_sign, DEC)
  ) %>%
  select(-DEC_sign) 

# Conversione RA e DEC in numeri
dataset_cleaned <- dataset_cleaned %>%
  mutate(
    RA = as.numeric(RA),  
    DEC = as.numeric(DEC)  
  )

# Rimozione della colonna SDSS
dataset_cleaned <- dataset_cleaned %>% select(-SDSS)

cat("Colonna SDSS rimossa. Dimensione attuale del dataset:", dim(dataset_cleaned), "\n")

# Scatterplot z vs Mp (prima)
ggplot(dataset, aes(x = z, y = Mp)) +
  geom_point(alpha = 0.5, color = "blue") +
  theme_minimal() +
  labs(title = "Prima della rimozione degli outliers",
       x = "Redshift (z)",
       y = "Magnitudine Assoluta (Mp)")


boxplot_b_Mp <- ggplot(dataset, aes(y = Mp)) +
  geom_boxplot(fill = "lightblue", alpha = 0.6) +
  theme_minimal() +
  labs(title = "Magnitudine Assoluta (Mp)",
       y = "Magnitudine Assoluta (Mp)")


boxplot_b_z <- ggplot(dataset, aes(y = z)) +
  geom_boxplot(fill = "lightblue", alpha = 0.6) +
  theme_minimal() +
  labs(title = " Redshift (z)",
       y = "Redshift (z)")

grid.arrange(boxplot_b_Mp, boxplot_b_z, nrow = 1)

Q1_Mp <- quantile(dataset_cleaned$Mp, 0.25)
Q3_Mp <- quantile(dataset_cleaned$Mp, 0.75)
IQR_Mp <- Q3_Mp - Q1_Mp

lower_bound_Mp <- Q1_Mp - 1.5 * IQR_Mp
upper_bound_Mp <- Q3_Mp + 1.5 * IQR_Mp

Q1_z <- quantile(dataset_cleaned$z, 0.25)
Q3_z <- quantile(dataset_cleaned$z, 0.75)
IQR_z <- Q3_z - Q1_z

lower_bound_z <- Q1_z - 1.5 * IQR_z
upper_bound_z <- Q3_z + 1.5 * IQR_z

dataset_cleaned <- dataset_cleaned %>%
  filter(Mp >= lower_bound_Mp & Mp <= upper_bound_Mp) %>%
  filter(z >= lower_bound_z & z <= upper_bound_z)

cat("Dimensione del dataset dopo rimozione outliers:", dim(dataset_cleaned), "\n")

# Creazione dei grafici
boxplot_Mp <- ggplot(dataset_cleaned, aes(y = Mp)) +
  geom_boxplot(fill = "orange", alpha = 0.6) +
  theme_minimal() +
  labs(title = "Magnitudine Assoluta (Mp)",
       y = "Magnitudine Assoluta (Mp)")

boxplot_z <- ggplot(dataset_cleaned, aes(y = z)) +
  geom_boxplot(fill = "orange", alpha = 0.6) +
  theme_minimal() +
  labs(title = " Redshift (z)",
       y = "Redshift (z)")


grid.arrange(boxplot_Mp, boxplot_z, nrow = 1)

# Identifica outliers "fisicamente plausibili" in Mp e z
potentially_significant <- dataset_cleaned %>%
  filter(Mp < -28 | z > 3.5)


cat("Outliers fisicamente significativi (Mp < -28 o z > 3.5):", 
    nrow(potentially_significant), "\n")


# Percentuale di outliers significativi rispetto al totale
total_data <- nrow(dataset)
significant_outliers <- nrow(potentially_significant)
percent_outliers <- (significant_outliers / total_data) * 100
cat("Percentuale di outliers significativi (Mp < -28 o z > 3.5):", 
    round(percent_outliers, 2), "%\n")

# Scatterplot con evidenza degli outliers
ggplot(dataset_cleaned, aes(x = z, y = Mp)) +
  geom_point(alpha = 0.5, color = "blue") +
  geom_point(data = potentially_significant, aes(x = z, y = Mp), color = "red", size = 3)+
  theme_minimal() +
  labs(title = "Scatterplot con evidenza degli outliers significativi",
       x = "Redshift (z)", y = "Magnitudine Assoluta (Mp)")

dataset_cleaned <- dataset_cleaned %>%
  select(-RA, -DEC)

cat("Dimensione del dataset dopo la rimozione di RA e DEC:", dim(dataset_cleaned), "\n")

numerical_vars <- dataset_cleaned

dataset_standardized <- as.data.frame(scale(numerical_vars))

print(head(dataset_standardized))

par(mfrow = c(3, 3)) 

for (var in colnames(dataset_standardized)) {
  hist(dataset_standardized[[var]], 
       main = paste( var),
       xlab = var, col = "gray", border = "black")
}
par(mfrow = c(1, 1))  

# Modelli preliminari con tutte le variabili
lm_model_full_mp <- lm(Mp ~ ., data = dataset_standardized)

# Matrice di correlazione per identificare multicollinearità
numeric_vars <- select(dataset_standardized, where(is.numeric))
cor_matrix <- cor(numeric_vars, use = "complete.obs")

# Soglia per identificare correlazioni elevate
correlation_threshold <- 0.9

high_corr_pairs <- which(abs(cor_matrix) > correlation_threshold, arr.ind = TRUE)
high_corr_pairs <- high_corr_pairs[high_corr_pairs[, 1] < high_corr_pairs[, 2], ]

# Variabili collineari identificate
collinear_vars <- unique(colnames(cor_matrix)[high_corr_pairs[, 2]])
cat("\nVariabili collineari identificate:\n")
print(collinear_vars)

dataset_no_collinear <- dataset_standardized %>% select(-all_of(collinear_vars))

# Confronto grafico delle matrici di correlazione
par(mfrow = c(1, 2), mar = c(5, 5, 5, 5))

# Matrice di correlazione prima della rimozione
corrplot(cor_matrix, method = "color", type = "upper", 
         tl.col = "black", tl.srt = 45, tl.cex = 0.8, 
         main = "Prima della Rimozione", mar = c(0, 0, 2, 0))

# Matrice di correlazione dopo la rimozione
cor_matrix_cleaned <- cor(select(dataset_no_collinear, where(is.numeric)), 
                          use = "complete.obs")
corrplot(cor_matrix_cleaned, method = "color", type = "upper", 
         tl.col = "black", tl.srt = 45, tl.cex = 0.8, 
         main = "Dopo la Rimozione", mar = c(0, 0, 2, 0))

par(mfrow = c(1, 1))

# Test del rapporto di verosimiglianza per Mp
lm_model_reduced_mp <- lm(Mp ~ ., data = dataset_no_collinear)
logLik_full_mp <- logLik(lm_model_full_mp)
logLik_reduced_mp <- logLik(lm_model_reduced_mp)
likelihood_ratio_mp <- -2 * (logLik_reduced_mp - logLik_full_mp)
df_mp <- attr(logLik_full_mp, "df") - attr(logLik_reduced_mp, "df")
p_value_lrt_mp <- pchisq(likelihood_ratio_mp, df = df_mp, lower.tail = FALSE)
cat("\nTest del Rapporto di Verosimiglianza per variabili collineari (Mp):\n")
cat("Likelihood Ratio Statistic (Mp):", likelihood_ratio_mp, "\n")
cat("Gradi di Libertà (Mp):", df_mp, "\n")
cat("p-value (Mp):", p_value_lrt_mp, "\n")


if ( p_value_lrt_mp > 0.05) {
  dataset_standardized <- dataset_no_collinear
  cat("\nLe variabili collineari non sono significative e vengono rimosse dal dataset.\n")
} else {
  cat("\nLe variabili collineari sono significative e non vengono rimosse dal dataset.\n")
}

# Dimensione finale del dataset
cat("\nDimensione finale del dataset:", dim(dataset_standardized), "\n")


S_data <- cov.wt(dataset_standardized, method = "ML")$cov
K_data <- solve(S_data)
PC_data <- cov2pcor(S_data)
diag(PC_data) <- 1

cat("Matrice di Concentrazione (x100):\n")
print(round(100 * K_data, 2))
cat("Matrice di Correlazione Parziale (x100):\n")
print(round(100 * PC_data, 2))

sat_model <- cmod(~ .^., data = dataset_standardized)

aic_backward <- stepwise(cmod(~ .^., data = dataset_standardized), 
                         direction = "backward", k = 2)

bic_backward <- stepwise(cmod(~ .^., data = dataset_standardized), 
                         direction = "backward", k = log(nrow(dataset_standardized)))


AIC_graph <- aic_backward$modelinfo$ug
BIC_graph <- bic_backward$modelinfo$ug
V(AIC_graph)$name <- aic_backward$varNames
V(BIC_graph)$name <- bic_backward$varNames


plot_graph <- function(graph, title, color) {
  plot(graph, main = title,
       vertex.size = 30, vertex.label.cex = 0.8,
       vertex.color = color, edge.color = "gray50")
}

plot_graph(AIC_graph, "Grafo Selezionato da AIC", "lightblue")
plot_graph(BIC_graph, "Grafo Selezionato da BIC", "lightgreen")


count_edges <- function(model) {
  graph <- model$modelinfo$ug
  return(length(E(graph)))
}

num_edges_aic <- count_edges(aic_backward)
cat("Numero di archi nel grafo AIC:", num_edges_aic, "\n")

num_edges_bic <- count_edges(bic_backward)
cat("Numero di archi nel grafo BIC:", num_edges_bic, "\n")


lambda <- 0.1  # Valore di penalizzazione
glasso_result <- glasso(S_data, rho = lambda)
precision_matrix <- glasso_result$wi

# Creazione della matrice di adiacenza e del grafo GLASSO
threshold <- 0.1  
adj_matrix <- (abs(precision_matrix) > threshold) * 1  # Soglia per sparsità
diag(adj_matrix) <- 0
glasso_graph <- graph_from_adjacency_matrix(adj_matrix, mode = "undirected")
V(glasso_graph)$name <- colnames(dataset_standardized)

plot_graph(glasso_graph, "Grafo stimato con GLASSO", "lightblue")

count_edges_glasso <- function(graph) {
  return(length(E(graph)))  # Conta gli archi del grafo
}

# Conteggio degli archi nel grafo GLASSO
num_edges_glasso <- count_edges_glasso(glasso_graph)
cat("Numero di archi nel grafo GLASSO:", num_edges_glasso, "\n")

find_max_cliques_glasso <- function(graph) {
  max_cliques <- max_cliques(graph)
  return(max_cliques)
}

max_cliques_glasso <- find_max_cliques_glasso(glasso_graph)

cat("Clique massimali nel grafo GLASSO:\n")
print(max_cliques_glasso)

get_edges_from_adj <- function(adj_matrix, nodes) {
  edges <- which(adj_matrix == 1, arr.ind = TRUE)
  data.frame(from = nodes[edges[, 1]], to = nodes[edges[, 2]])
}
nodes <- colnames(dataset_standardized)
edges_glasso <- get_edges_from_adj(adj_matrix, nodes)

# Creazione della blacklist
all_possible_edges <- expand.grid(from = nodes, to = nodes)
all_possible_edges <- subset(all_possible_edges, from != to)
blacklist <- setdiff(all_possible_edges, edges_glasso)

hc_dag <- hc(dataset_standardized, blacklist = blacklist, score = "bic-g")

# Visualizza il DAG risultante
dag_adj <- amat(hc_dag)
qgraph(dag_adj, 
       layout = "spring", 
       labels = colnames(dataset_standardized), 
       title = "Rete Bayesiana orientata dal GLASSO")

full_model <- lm(Mp ~ ., data = dataset_standardized)
summary(full_model)

reduced_model <- lm(Mp ~ z + g_mag + r_mag + ROSAT + z_mag + i_mag + u_mag + sig_u_mag, 
                    data = dataset_standardized)
summary(reduced_model)

zgr_model <- lm(Mp ~ z + g_mag + r_mag, data = dataset_standardized)
summary(zgr_model)

z_model <- lm(Mp ~ z, data = dataset_standardized)
summary(z_model)
