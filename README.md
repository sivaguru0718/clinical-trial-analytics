Clinical Trial Analytics Using PostgreSQL and Power BI
About the Project
This project explores a synthetic Phase III clinical trial dataset using PostgreSQL and Power BI. I built it to practise a realistic analytics workflow: checking data quality, preparing data for analysis, answering clinical-trial-related questions with SQL, and presenting the results in an interactive dashboard.

The dashboard is organised into three pages: Trial Overview, Patient Outcomes, and Site Audit & Optimization. Each page focuses on a different set of questions so that the same information is not repeated unnecessarily.

Project Goals
Review adverse-event patterns across treatment groups.
Explore patient dropout patterns by demographic and adverse-event categories.
Compare systolic and diastolic blood pressure across treatment arms.
Review recruitment and dropout patterns across clinical sites.
Identify invalid blood pressure records and summarise data validity.
Present the analysis in a clear Power BI report.
Tools Used
PostgreSQL for storing, cleaning, validating, and analysing data.
SQL for data preparation, aggregations, analytical queries, and ranking.
Microsoft Power BI for interactive reporting and visualisation.
DAX for dashboard measures and KPIs.
Dataset
The project uses a synthetic Phase III clinical trial dataset. The analysis includes patient, treatment, enrollment, adverse-event, dropout, clinical-site, and blood-pressure fields.

Dataset source: [Add the original dataset URL here]

The dataset and its licence or usage terms should be checked before sharing the raw data publicly. No real patient information should be included in this repository.

Dashboard Pages
1. Trial Overview
This page gives a high-level view of trial enrollment, treatment groups, adverse events, and patient dropout. It is intended to help readers understand the overall dataset before exploring specific outcomes.

Screenshot: screenshots/trial-overview.png

2. Patient Outcomes
This page explores dropout patterns across selected patient groups and adverse-event categories. It also compares blood-pressure measurements and high blood-pressure prevalence across treatment arms.

Screenshot: screenshots/patient-outcomes.png

3. Site Audit and Optimization
This page focuses on site-level recruitment, monthly enrollment, dropout patterns, and blood-pressure data quality. The Pareto chart ranks the ten sites with the highest enrollment in the dataset. Its cumulative percentage is calculated within those ten selected sites, not across all clinical sites.

Screenshot: screenshots/site-operations.png

SQL Analysis
The SQL script contains the queries used during the project, including data checks, cleaning steps, summary calculations, treatment-group comparisons, patient dropout analysis, site-level analysis, and window-function examples.

Main SQL file: sql/clinical_trial_analysis.sql

Before running the script, review the table names and execution order. The script expects the relevant source table and cleaned table or views to be available in the PostgreSQL database. Update any local database-specific settings before running it in another environment.

Main Observations
The current dashboard reports the following descriptive results. These values should be checked against the final SQL outputs before publication.

The dataset contains 1,000 patients across 50 clinical sites.
The dashboard reports an overall patient dropout count of 161.
The ten highest-enrollment sites shown in the Pareto chart account for 183 patients, or 18.3% of the total trial population.
The dashboard flags 14 blood-pressure records as invalid and reports 98.60% blood-pressure data validity.
The dashboard compares observed adverse-event rates across the placebo and active treatment groups.
These results describe this dataset only. They do not establish that one treatment is safer or more effective than another.

How to Review the Project
Review the SQL script to understand the data checks and calculations.
Check the data dictionary for column definitions and metric meanings.
Open the Power BI file to explore the three report pages.
Compare important dashboard KPIs with the SQL query results.
Refer to the screenshots if Power BI is not available.
Repository Structure
clinical-trial-analytics/
├── README.md
├── sql/
│   └── clinical_trial_analysis.sql
├── powerbi/
│   └── Clinical_Trial_Analytics.pbix
├── screenshots/
│   ├── trial-overview.png
│   ├── patient-outcomes.png
│   └── site-operations.png
├── docs/
│   └── Data_Dictionary.md
└── data/
    └── README.md
Add the master analysis document to the repository if it helps explain the work. Only include the raw dataset if its source terms permit redistribution; otherwise, document where it came from and how to obtain it.

Limitations
The dataset is synthetic and may not represent real clinical-trial populations.
The analysis is descriptive. No causal conclusions or treatment-superiority claims are made.
The interpretation of each metric depends on its definition, denominator, and data-validation rules.
Site recruitment counts and dropout rates alone do not prove that a site is performing well or poorly.
Results should be reconciled with the final SQL output before they are presented as project findings.
Conclusion
This project demonstrates how PostgreSQL and Power BI can be used together to prepare, analyse, and present clinical-trial-related data. It combines data-quality checks, patient outcome analysis, treatment-arm comparisons, and site-level recruitment reporting in one documented workflow.

This is an educational portfolio project using synthetic data. It is not intended for clinical, regulatory, or treatment decision-making.
