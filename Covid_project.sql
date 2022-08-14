/*
Covid-19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
Project is based on guided tutorial from @Alex The Analyst
14.08.2022
*/

-- Select project that we are going to be using 
USE Portfolio_Project
GO


-- Add population to the fist table
ALTER TABLE Portfolio_Project.dbo.Covid_deaths ADD population bigint NULL, column_c INT NULL;

UPDATE Portfolio_Project.dbo.Covid_deaths
SET Portfolio_Project.dbo.Covid_deaths.population = vaccs.population
FROM Portfolio_Project.dbo.Covid_deaths AS deaths
LEFT JOIN Portfolio_Project.dbo.Covid_vaccinations AS vaccs ON deaths.location = vaccs.location AND deaths.date = vaccs.date


-- Peek at the data that we are going to be starting with
SELECT TOP 20 location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio_Project.dbo.Covid_deaths
WHERE continent is not null
ORDER BY 1,2


-- Looking at total cases vs total deaths in US
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_perc
FROM Portfolio_Project.dbo.Covid_deaths AS deaths
WHERE location like '%States%'
AND continent is not null
ORDER BY 1,2


-- Looking at total cases vs population in my country (Georgia)
SELECT location, date, total_cases, population, (total_cases/population)*100 AS cases_per_capita
FROM Portfolio_Project.dbo.Covid_deaths AS deaths
WHERE location = 'Georgia'
ORDER BY 1,2


-- Countries with the highest infection rates compared to population
SELECT location, MAX(total_cases) AS Highest_Infection_Count, population, MAX((total_cases/population))*100 AS max_cases_per_capita
FROM Portfolio_Project.dbo.Covid_deaths
GROUP BY location, population
ORDER BY 4 DESC


-- Showing countries with highest death count per population
SELECT location, MAX(cast(total_deaths AS int)) AS Total_death_Count
FROM Portfolio_Project.dbo.Covid_deaths
WHERE continent is not null
GROUP BY location
ORDER BY 2 DESC


-- BREAKDOWN BY CONTINENTS

-- Showing continents with the highest death count per population
SELECT location, MAX(cast(total_deaths AS int)) AS Total_death_Count
FROM Portfolio_Project.dbo.Covid_deaths
WHERE continent is null AND location not like '%income%'
GROUP BY location
ORDER BY 2 DESC


-- GLOBAL NUMBERS

SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths as int)) AS total_deaths, (SUM(CAST(new_deaths as int))/SUM(new_cases))*100 AS death_perc
FROM Portfolio_Project.dbo.Covid_deaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2


-- Looking at vaccinations vs total population
-- Joining datasets

SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations AS new_vaccs,
	SUM(CONVERT(bigint, vacc.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS cummulative_vaccs,
	(cummulative_vaccs/deaths.population)*100 AS percent_vacc
FROM Portfolio_Project.dbo.Covid_deaths AS deaths
JOIN Portfolio_Project.dbo.Covid_vaccinations AS vacc
	ON deaths.location = vacc.location AND deaths.date = vacc.date
WHERE deaths.continent is not null
ORDER BY 2,3


-- > Looking at vaccinations using CTE to perform calculation on partition by
WITH vacc_pop (continent, location, date, population, new_vaccinations, cummulative_vaccs)
AS
(
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations AS new_vaccs,
	SUM(CONVERT(bigint, vacc.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS cummulative_vaccs
FROM Portfolio_Project.dbo.Covid_deaths AS deaths
JOIN Portfolio_Project.dbo.Covid_vaccinations AS vacc
	ON deaths.location = vacc.location AND deaths.date = vacc.date
WHERE deaths.continent is not null
)
SELECT *, (cummulative_vaccs/CAST(population as float))*100 AS percent_vacc
FROM vacc_pop
ORDER BY 2,3


-- > Looking at vaccinations using Temp Tables to perform calculation on partition by
DROP TABLE IF EXISTS #vacc_pop_perc
CREATE TABLE #vacc_pop_perc
(
continent nvarchar(255), 
location nvarchar(255), 
date datetime, 
population numeric, 
new_vaccinations numeric, 
cummulative_vaccs numeric
)

INSERT INTO #vacc_pop_perc
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations AS new_vaccs,
	SUM(CONVERT(bigint, vacc.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS cummulative_vaccs
FROM Portfolio_Project.dbo.Covid_deaths AS deaths
JOIN Portfolio_Project.dbo.Covid_vaccinations AS vacc
	ON deaths.location = vacc.location AND deaths.date = vacc.date
WHERE deaths.continent is not null

SELECT *, (cummulative_vaccs/CAST(population as float))*100 AS percent_vacc
FROM #vacc_pop_perc
ORDER BY 2,3


-- Creating views to store data for using in visualizations
DROP VIEW IF EXISTS vacc_pop_perc
CREATE VIEW vacc_pop_perc AS
(
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations AS new_vaccs,
	SUM(CONVERT(bigint, vacc.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS cummulative_vaccs
FROM Portfolio_Project.dbo.Covid_deaths AS deaths
JOIN Portfolio_Project.dbo.Covid_vaccinations AS vacc
	ON deaths.location = vacc.location AND deaths.date = vacc.date
WHERE deaths.continent is not null
)
GO

--
DROP VIEW IF EXISTS cont_breakdown
CREATE VIEW cont_breakdown AS
(
SELECT location, MAX(cast(total_deaths AS int)) AS Total_death_Count
FROM Portfolio_Project.dbo.Covid_deaths
WHERE continent is null AND location not like '%income%'
GROUP BY location
)
GO

--
DROP VIEW IF EXISTS deaths
CREATE VIEW deaths AS
(
SELECT location, MAX(cast(total_deaths AS int)) AS Total_death_Count
FROM Portfolio_Project.dbo.Covid_deaths
WHERE continent is not null
GROUP BY location
)
GO

--
DROP VIEW IF EXISTS infection_rates
CREATE VIEW infection_rates AS
(
SELECT location, MAX(total_cases) AS Highest_Infection_Count, population, MAX((total_cases/population))*100 AS max_cases_per_capita
FROM Portfolio_Project.dbo.Covid_deaths
GROUP BY location, population
)
GO

--
DROP VIEW IF EXISTS cases_pop_perc
CREATE VIEW cases_pop_perc AS
(
SELECT location, date, total_cases, population, (total_cases/population)*100 AS cases_per_capita
FROM Portfolio_Project.dbo.Covid_deaths AS deaths
WHERE continent is not null
)
GO



