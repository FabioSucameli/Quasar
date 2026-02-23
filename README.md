#  Absolute Magnitude vs Redshift in Quasars

![R](https://img.shields.io/badge/R-4.x-blue)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen)
![Dataset](https://img.shields.io/badge/Dataset-SDSS_QSO-orange)
![Modeling](https://img.shields.io/badge/Methods-GLASSO%20%7C%20Bayesian%20Network%20%7C%20Regression-purple)

---



##  Introduction

Quasars are among the most luminous objects in the universe, powered by accretion onto supermassive black holes.  
Because they are visible across vast cosmological distances, they provide a unique window into the early universe.

This project investigates the statistical relationship between:

- **Redshift (z)** → proxy for cosmological distance and look-back time  
- **Absolute Magnitude (Mp)** → intrinsic luminosity  

Astrophysical theory suggests:

> As redshift increases, quasars observed tend to be intrinsically more luminous (lower Mp values).

This repository explores and validates this relationship using statistical modeling and graphical techniques.

------------------------------------------------------------------------

## Dataset

Source: **SDSS_QSO (Sloan Digital Sky Survey)**  

- Initial observations: **77,429**
- Final cleaned dataset: **3,713**
- Variables:
  - Redshift (`z`)
  - Absolute magnitude (`Mp`)
  - Photometric bands (u, g, r, i, z)
  - Measurement errors (`sig_*`)
  - Radio (FIRST) and X-ray (ROSAT) luminosities


------------------------------------------------------------------------

## Data Preparation

- Removed invalid redshift and magnitude values
- Excluded non-detections (FIRST < 0, ROSAT = -9)
- Removed missing values
- Outliers filtered using **IQR rule**
- Preserved physically extreme quasars (`Mp < -28` or `z > 3.5`)
- Standardized all numerical variables (z-score)

------------------------------------------------------------------------

## Exploratory Analysis

### Scatterplot: Redshift vs Absolute Magnitude

![Scatterplot](images/scatter_z_mp.png)

This plot clearly shows a strong negative relationship: higher redshift
quasars tend to have lower (more negative) absolute magnitudes.

------------------------------------------------------------------------

### Correlation Matrix

![Correlation Matrix](images/correlation_matrix.png)

Photometric bands are highly correlated, indicating potential
multicollinearity that must be handled carefully.

------------------------------------------------------------------------

### GLASSO Sparse Graph

![GLASSO Graph](images/glasso_graph.png)

Using Graphical LASSO (λ = 0.1), a sparse conditional dependency network
was estimated.

Key insight: - Direct structural edge between **z and Mp** - Strong
clique among photometric bands - Measurement errors form a separate
cluster

------------------------------------------------------------------------

### Bayesian Network

![Bayesian Network](images/bayesian_network.png)

A directed acyclic graph (Hill Climbing + BIC) confirms:

-   Redshift acts as a primary driver of absolute magnitude
-   Photometric bands mediate secondary effects

------------------------------------------------------------------------

## Regression Models

| Model   | Predictors                  | R²    |
|----------|----------------------------|-------|
| Full     | All variables              | 0.863 |
| Reduced  | Selected key predictors    | 0.834 |
| Minimal  | z + g + r                  | 0.796 |
| Simple   | z only                     | 0.642 |

Across all models:

> Redshift (**z**) has a strong negative and highly significant coefficient  
> *(p < 2e-16)*.


🚩 **For detailed statistical results and full methodological discussion, see [`report.pdf`](report.pdf).**


------------------------------------------------------------------------

##  Key Findings

-   Strong negative association between **z** and **Mp**
-   Photometric bands (g and r especially) enhance prediction
-   Graphical and regression models independently confirm the same
    structure
-   Measurement errors cluster but do not drive the primary relationship

------------------------------------------------------------------------

## Final Observation

What makes these results compelling is the convergence of multiple
independent methodologies.

Linear regression quantifies the relationship.\
GLASSO isolates the direct conditional structure.\
The Bayesian Network assigns directionality.

All approaches point to the same conclusion:

> Redshift is structurally and statistically central in explaining
> quasar intrinsic luminosity.

From a cosmological perspective, this aligns with observational theory:
at greater distances (earlier epochs), only the most luminous quasars
remain detectable.

The consistency between statistical modeling and astrophysical
expectations strengthens the robustness of the findings.


