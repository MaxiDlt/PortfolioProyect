SELECT * 
FROM dbo.CovidDeaths
ORDER BY 3,4

--SELECT *
--FROM dbo.CovidVaccination
-- ORDER BY 3,4
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM dbo.CovidDeaths
ORDER BY 1,2

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM dbo.CovidDeaths
ORDER BY 1,2

-- Total Cases vs Total Deaths in Argentina
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM dbo.CovidDeaths
WHERE Location LIKE '%Argentina%'
ORDER BY 1,2

-- Total Cases vs Population in Argentina
-- Shows percentage of people that had COVID vs total population
SELECT Location, date, total_cases, population, (total_cases/population)*100 AS DeathPercentage
FROM dbo.CovidDeaths
WHERE Location LIKE '%Argentina%'
ORDER BY 1,2

-- Ranking of Countries with more population infected
SELECT Location, Population, MAX(total_cases) AS HighiestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM dbo.CovidDeaths
--WHERE Location LIKE '%Argentina%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

-- Ranking of countries with more deaths
SELECT Location, Population, MAX(cast(total_deaths as int)) AS HighiestDeathCount, MAX((total_deaths/population))*100 AS PercentOfDeaths
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY HighiestDeathCount DESC

-- Ranking od deaths by continent
SELECT location, MAX(cast(total_deaths as int)) AS HighiestDeathCount
FROM dbo.CovidDeaths
WHERE continent IS NULL AND location NOT IN('World', 'International')
GROUP BY location
ORDER BY HighiestDeathCount DESC

-- Total new cases and deaths
SELECT SUM(new_cases) AS NewCases, SUM(cast(new_deaths as int)) AS NewDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathNewPercentage 
FROM dbo.CovidDeaths
--WHERE Location LIKE '%Argentina%'
WHERE continent IS NOT NULL
--GROUP BY Date
ORDER BY 1,2

-- Join deaths Table with vaccination table
SELECT *
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date

-- Loooking at total population vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, 
		vac.new_vaccinations,
		SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1,2,3

-- Create a CTE from the previouse query
WITH PopvsVac (continent, location, date, population, 
		new_vaccinations, RollingPeopleVaccinated)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, 
		vac.new_vaccinations,
		SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 1,2,3
)
-- Calculate the percentage of people vaccinated vs total population
SELECT * , (RollingPeopleVaccinated/population)*100
FROM PopvsVac

-- Makeing a TEMP Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
date datetime,
Population numeric,
New_vaccination numeric,
RollingPeopleVaccinated numeric,
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, 
		vac.new_vaccinations,
		SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

-- Creating View to store date for later visualizations
CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, 
		vac.new_vaccinations,
		SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL