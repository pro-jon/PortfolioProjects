
--Select data to be used for analysis

SELECT *
FROM CovidProject..CovidDeaths
--WHERE location = ''
ORDER BY location, date;


--Total Cases vs Total Deaths
--Shows likelihood of death if a person were to contract COVID in their countyr

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE location like '%States'
ORDER BY location, date;


--Looking at Total Cases vs Population
--Shows percentage of population contracting COVID

SELECT location, population, total_cases, (total_cases/population) * 100 AS PercentPopInfected
FROM CovidProject..CovidDeaths
WHERE location like '%States'
ORDER BY location, date;


--Countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)) * 100 AS PercentPopInfected
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopInfected DESC;


--Countries with highest death rate per population

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;


--Starting to look at continents as opposed to specific countries

--Continents with highest death count

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent IS NULL 
AND location NOT IN ('World', 'European Union', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY TotalDeathCount DESC;


--Global Numbers

--Death percentage by day. NULLIF needed to do a 'Divide by zero' error.

SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths)/NULLIF(SUM(new_cases), 0))*100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

--Global death percentage up to date with data

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;


--Introducing CovidVaccinations table 

SELECT *
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date;


--Looking at total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinated
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;


--Use CTE to find percentage of population vaccinated

WITH PopVsVac (Continent, Location, Date, Population, new_vaccinations, RollingVaccinated) AS
	(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinated
	FROM CovidProject..CovidDeaths dea
	JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL)
SELECT *, (RollingVaccinated/Population)*100 AS PercentPopVaccinated
FROM PopVsVac;


--Use Temp Table to find percentage of population vaccinated

--DROP TABLE IF EXISTS #PercentPopVaccinated
CREATE TABLE #PercentPopVaccinated
	(continent nvarchar(255);
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	RollingVaccinated numeric);

INSERT INTO #PercentPopVaccinated
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinated
	FROM CovidProject..CovidDeaths dea
	JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL;

SELECT *, (RollingVaccinated/Population)*100 AS PercentPopVaccinated
FROM #PercentPopVaccinated;



--Create VIEWs to store data for later visualizations

CREATE VIEW PercentPopVaccinated AS
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinated
	FROM CovidProject..CovidDeaths dea
	JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL;