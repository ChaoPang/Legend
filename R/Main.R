# Copyright 2018 Observational Health Data Sciences and Informatics
#
# This file is part of Legend
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Execute OHDSI LEGEND study
#'
#' @details
#' This function executes the OHDSI LEGEND study.
#'
#' @param connectionDetails                    An object of type \code{connectionDetails} as created
#'                                             using the
#'                                             \code{\link[DatabaseConnector]{createConnectionDetails}}
#'                                             function in the DatabaseConnector package.
#' @param cdmDatabaseSchema                    Schema name where your patient-level data in OMOP CDM
#'                                             format resides. Note that for SQL Server, this should
#'                                             include both the database and schema name, for example
#'                                             'cdm_data.dbo'.
#' @param oracleTempSchema                     Should be used in Oracle to specify a schema where the
#'                                             user has write priviliges for storing temporary tables.
#' @param cohortDatabaseSchema                 Schema name where intermediate data can be stored. You
#'                                             will need to have write priviliges in this schema. Note
#'                                             that for SQL Server, this should include both the
#'                                             database and schema name, for example 'cdm_data.dbo'.
#' @param outputFolder                         Name of local folder to place results; make sure to use
#'                                             forward slashes (/). Do not use a folder on a network
#'                                             drive since this greatly impacts performance.
#' @param indicationId                         A string denoting the indicationId.
#' @param tablePrefix                          A prefix to be used for all table names created for this
#'                                             study.
#' @param databaseId                           A short string for identifying the database (e.g.
#'                                             'Synpuf').
#' @param databaseName                         The full name of the database (e.g. 'Medicare Claims
#'                                             Synthetic Public Use Files (SynPUFs)').
#' @param databaseDescription                  A short description (several sentences) of the database.
#' @param minCellCount                         The minimum cell count for fields contains person counts
#'                                             or fractions when exporting to CSV.
#' @param imputeExposureLengthWhenMissing      For PanTher: impute length of drug exposures when the
#'                                             length is missing?
#' @param createExposureCohorts                Create the tables with the exposure cohorts?
#' @param createOutcomeCohorts                 Create the tables with the outcome cohorts?
#' @param fetchAllDataFromServer               Fetch all relevant data from the server?
#' @param synthesizePositiveControls           Inject signals to create synthetic controls?
#' @param generateAllCohortMethodDataObjects   Create the cohortMethodData objects from the fetched
#'                                             data and injected signals?
#' @param runCohortMethod                      Run the CohortMethod package to produce the outcome
#'                                             models?
#' @param computeIncidence                     Compute incidence rates?
#' @param fetchChronographData                 Fetch the data for constructing chronographs?
#' @param computeCovariateBalance              Compute covariate balance?
#' @param exportToCsv                          Export all results to CSV files?
#' @param maxCores                             How many parallel cores should be used? If more cores
#'                                             are made available this can speed up the analyses.
#'
#' @export
execute <- function(connectionDetails,
                    cdmDatabaseSchema,
                    oracleTempSchema,
                    cohortDatabaseSchema,
                    outputFolder,
                    indicationId = "Depression",
                    tablePrefix = "legend",
                    databaseId = "Unknown",
                    databaseName = "Unknown",
                    databaseDescription = "Unknown",
                    minCellCount = 5,
                    imputeExposureLengthWhenMissing = FALSE,
                    createExposureCohorts = TRUE,
                    createOutcomeCohorts = TRUE,
                    fetchAllDataFromServer = TRUE,
                    synthesizePositiveControls = TRUE,
                    generateAllCohortMethodDataObjects = TRUE,
                    runCohortMethod = TRUE,
                    computeIncidence = TRUE,
                    fetchChronographData = TRUE,
                    computeCovariateBalance = TRUE,
                    exportToCsv = TRUE,
                    maxCores = 4) {

    indicationFolder <- file.path(outputFolder, indicationId)
    if (!file.exists(indicationFolder)) {
        dir.create(indicationFolder, recursive = TRUE)
    }
    ParallelLogger::addDefaultFileLogger(file.path(indicationFolder, "log.txt"))
    on.exit(ParallelLogger::unregisterLogger("DEFAULT"))

    sinkFile <- file(file.path(indicationFolder, "console.txt"), open = "wt")
    sink(sinkFile, split = TRUE)
    on.exit(sink(), add = TRUE)

    if (createExposureCohorts) {
        createExposureCohorts(connectionDetails = connectionDetails,
                              cdmDatabaseSchema = cdmDatabaseSchema,
                              cohortDatabaseSchema = cohortDatabaseSchema,
                              tablePrefix = tablePrefix,
                              indicationId = indicationId,
                              oracleTempSchema = oracleTempSchema,
                              outputFolder = outputFolder,
                              imputeExposureLengthWhenMissing = imputeExposureLengthWhenMissing)
        filterByExposureCohortsSize(outputFolder = outputFolder, indicationId = indicationId)
    }
    if (createOutcomeCohorts) {
        createOutcomeCohorts(connectionDetails = connectionDetails,
                             cdmDatabaseSchema = cdmDatabaseSchema,
                             cohortDatabaseSchema = cohortDatabaseSchema,
                             tablePrefix = tablePrefix,
                             indicationId = indicationId,
                             oracleTempSchema = oracleTempSchema,
                             outputFolder = outputFolder)
    }
    if (fetchAllDataFromServer) {
        fetchAllDataFromServer(connectionDetails = connectionDetails,
                               cdmDatabaseSchema = cdmDatabaseSchema,
                               oracleTempSchema = oracleTempSchema,
                               cohortDatabaseSchema = cohortDatabaseSchema,
                               tablePrefix = tablePrefix,
                               indicationId = indicationId,
                               outputFolder = outputFolder)
    }
    if (synthesizePositiveControls) {
        synthesizePositiveControls(connectionDetails = connectionDetails,
                                   cdmDatabaseSchema = cdmDatabaseSchema,
                                   oracleTempSchema = oracleTempSchema,
                                   cohortDatabaseSchema = cohortDatabaseSchema,
                                   tablePrefix = tablePrefix,
                                   indicationId = indicationId,
                                   outputFolder = outputFolder,
                                   maxCores = maxCores)
    }
    if (generateAllCohortMethodDataObjects) {
        generateAllCohortMethodDataObjects(outputFolder = outputFolder,
                                           indicationId = indicationId,
                                           maxCores = maxCores)
    }
    if (runCohortMethod) {
        runCohortMethod(outputFolder = outputFolder,
                        indicationId = indicationId,
                        databaseId = databaseId,
                        maxCores = maxCores)
    }

    if (computeIncidence) {
        computeIncidence(outputFolder = outputFolder, indicationId = indicationId)
    }
    if (fetchChronographData) {
        fetchChronographData(connectionDetails = connectionDetails,
                             cdmDatabaseSchema = cdmDatabaseSchema,
                             oracleTempSchema = oracleTempSchema,
                             cohortDatabaseSchema = cohortDatabaseSchema,
                             tablePrefix = tablePrefix,
                             indicationId = indicationId,
                             outputFolder = outputFolder)
    }
    if (computeCovariateBalance) {
        computeCovariateBalance(outputFolder = outputFolder,
                                indicationId = indicationId,
                                maxCores = maxCores)
    }

    if (exportToCsv) {
        exportResults(indicationId = indicationId,
                      outputFolder = outputFolder,
                      databaseId = databaseId,
                      databaseName = databaseName,
                      databaseDescription = databaseDescription,
                      minCellCount = minCellCount,
                      maxCores = maxCores)
    }
    ParallelLogger::logFatal("Finished")
}
