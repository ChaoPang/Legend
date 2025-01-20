/************************************************************************
Copyright 2018 Observational Health Data Sciences and Informatics

This file is part of Legend

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
************************************************************************/
{DEFAULT @cohort_database_schema = 'scratch.dbo'}
{DEFAULT @paired_cohort_table = 'cohort'}

--HINT DISTRIBUTE_ON_KEY(subject_id)
SELECT ROW_NUMBER() OVER (
		ORDER BY subject_id,
			cohort_start_date
		) AS row_id,
	subject_id,
	cohort_start_date,
	cohort_end_date,
	cohort_definition_id
INTO #exposure_cohorts
FROM (
	SELECT DISTINCT subject_id,
		cohort_start_date,
		cohort_end_date,
		cohort_definition_id
	FROM @cohort_database_schema.@paired_cohort_table paired_cohort
	INNER JOIN #comparisons comparisons
		ON paired_cohort.target_id = comparisons.target_id
			AND paired_cohort.comparator_id = comparisons.comparator_id
	) tmp;
