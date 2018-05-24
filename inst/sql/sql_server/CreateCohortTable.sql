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
IF OBJECT_ID('@cohort_database_schema.@cohort_table', 'U') IS NOT NULL
  DROP TABLE @cohort_database_schema.@cohort_table;
  
CREATE TABLE @cohort_database_schema.@cohort_table (
	subject_id BIGINT, 
	cohort_definition_id BIGINT,
	cohort_start_date DATE,
	cohort_end_date DATE
);
