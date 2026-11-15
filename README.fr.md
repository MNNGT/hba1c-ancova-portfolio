
**Langue / Language :** [Français](README.fr.md) | [English](README.md)

---

**📊 [Rapport scientifique – Français](https://mnngt.github.io/hba1c-ancova-portfolio/report.fr.html)**

**📊 [Scientific Report – English](https://mnngt.github.io/hba1c-ancova-portfolio/report.html)**


---

# ANCOVA de l’HbA1c avec R — Réanalyse d’un travail universitaire

**Analyse statistique | R | Régression linéaire | ANCOVA | Quarto | Recherche reproductible**

## Accéder au rapport scientifique

**[Consulter le rapport scientifique en ligne — R et Quarto](https://mnngt.github.io/hba1c-ancova-portfolio/report.html)**

Le rapport actuellement publié est en anglais. Une version française pourra être ajoutée ultérieurement.

---

**Réanalyse pédagogique indépendante d’un jeu de données fourni dans le cadre d’un enseignement universitaire ; il ne s’agit pas de résultats originaux issus d’un essai clinique.** Le fichier `data/hb.csv` n’est pas constitué de données synthétiques. Son origine scientifique et les unités de mesure ne sont pas documentées indépendamment dans le fichier CSV. L’énoncé universitaire initial décrit une comparaison de deux groupes parallèles, avec une mesure de l’HbA1c à l’inclusion et au suivi.

## Question de recherche

Le taux d’HbA1c mesuré au suivi diffère-t-il entre les groupes A et B, après ajustement sur le taux d’HbA1c initial ?

## Méthodes statistiques présentées

- Validation des données et importation correcte d’un fichier **séparé par des points-virgules et utilisant la virgule décimale**, avec `read.csv2()`.
- Statistiques descriptives et visualisations exploratoires avec `ggplot2`.
- Régression linéaire / ANCOVA : `lm(hb1 ~ groupe + hb0)`.
- Interprétation des coefficients et des intervalles de confiance à 95 %.
- Diagnostics du modèle : résidus en fonction des valeurs ajustées, graphique quantile-quantile (QQ-plot), graphique *scale-location*, observations à fort levier et distance de Cook.
- Vérification de l’hypothèse de pentes communes à l’aide de l’interaction entre l’HbA1c initial et le groupe.
- Erreurs standards robustes à l’hétéroscédasticité de type HC3, calculées en R de base.
- Analyses exploratoires des variations d’HbA1c par les tests de Welch et de Wilcoxon pour échantillons indépendants.
- Rapport scientifique généré avec **Quarto**.

## Résultats vérifiés indépendamment

Après l’importation correcte des nombres utilisant une virgule décimale, le jeu de données comprend **75 observations**, dont **37 dans le groupe A** et **38 dans le groupe B**, sans valeur manquante ni identifiant dupliqué.

Le coefficient ajusté associé au **groupe B** est d’environ **−1,15** (IC à 95 % : **−1,58 à −0,72** ; **p < 0,001**). Ces valeurs ont été vérifiées indépendamment sous Python à l’aide d’un modèle équivalent de régression par les moindres carrés ordinaires ; elles doivent pouvoir être reproduites en exécutant le script R.

Une version antérieure du travail universitaire avait importé les mesures à virgule décimale comme des nombres beaucoup plus élevés, ce qui avait conduit à des résultats trompeurs. La présente réanalyse documente et corrige cette erreur.

Le jeu de données, à lui seul, ne permet pas d’étayer une conclusion causale sur l’effet d’une intervention.

## Rapport scientifique

L’analyse statistique complète est disponible sous la forme d’un rapport HTML généré avec **R et Quarto**.

Il comprend :

- Les statistiques descriptives et les vérifications de qualité des données.
- L’ANCOVA ajustée sur la mesure initiale.
- Les diagnostics du modèle et la vérification de ses hypothèses.
- L’analyse de sensibilité utilisant des erreurs standards robustes HC3.
- L’interprétation des résultats et les limites de l’étude.

**[Consulter le rapport scientifique](https://mnngt.github.io/hba1c-ancova-portfolio/report.html)**

## Exécution locale

Depuis la racine du projet dans RStudio ou dans un terminal R :

```r
install.packages("ggplot2") # À exécuter une seule fois si nécessaire
source("R/analysis.R")
```

Puis générer le rapport avec Quarto (qui doit être installé) :

```bash
quarto render report.qmd
```

L’analyse crée des graphiques et des tableaux dans le dossier `outputs/`.

## Structure du projet

```text
hba1c-ancova-portfolio/
├── data/
│   └── hb.csv           # Jeu de données fourni pour l'enseignement, format original
├── R/
│   └── analysis.R      # Analyse reproductible complète
├── outputs/
│   ├── figures/        # Graphiques générés par R
│   └── tables/         # Tableaux générés par R
├── report.qmd          # Rapport scientifique Quarto en anglais
├── README.md           # Présentation en anglais
└── README.fr.md        # Présentation en français
```

## Provenance et périmètre

Ce projet constitue une adaptation indépendante, destinée à un portfolio, d’un travail réalisé dans le cadre de l’UE **STA-LOMX (Master MQERS)**. L’énoncé du devoir et le corrigé de l’enseignant ne sont pas inclus.

**L’origine du jeu de données et l’autorisation de sa redistribution publique doivent être vérifiées.** Le fait de réanalyser les données d’un enseignement ne signifie pas que l’autrice les a collectées ou qu’elle a conduit un essai clinique.

Ce projet est indépendant des données institutionnelles confidentielles de surveillance sanitaire.
