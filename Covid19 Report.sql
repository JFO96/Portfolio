-- Covid 19 Report: How did Vaccine Uptake affect Death Rates in each Country? (Data Exploration)
--Import tables from "Ourworldindata" Excel files via SQL Server Import/Export Wizard

--Now to select the data to be used:
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidPortfolioProject..CovidDeaths
ORDER by 1,2

-- Total Cases vs Total Deaths = Mortality Rate (using the UK as an example):
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as mortality_rate
FROM CovidPortfolioProject..CovidDeaths
--WHERE location like 'United Kingdom'
ORDER by 1,2

-- Total Cases vs Population = Proportion of the Population Infected:
SELECT location, date, total_cases, population, (total_cases/population)*100 as proportion_infected
FROM CovidPortfolioProject..CovidDeaths
--WHERE location like 'United Kingdom'
ORDER by 1,2

-- Countries with the Highest Infection Rates compared to their Population:
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as proportion_positive
FROM CovidPortfolioProject..CovidDeaths
--WHERE location like 'United Kingdom'
GROUP BY location, population
ORDER by proportion_positive DESC

-- Countries with the Highest Death Count
SELECT location, MAX(cast(total_deaths as int)) as HighestDeathCount
FROM CovidPortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER by HighestDeathCount DESC

-- CONTINENTS with the Highest Death Count
SELECT location, MAX(cast(total_deaths as int)) as HighestDeathCount
FROM CovidPortfolioProject..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER by HighestDeathCount DESC


-- Worldwide Daily Mortality Rates:
SELECT date, SUM(new_cases) as global_new_cases,
	SUM(cast(new_deaths as int)) as global_new_deaths, 
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 as Global_daily_mortality
FROM CovidPortfolioProject..CovidDeaths
WHERE continent is not null
GROUP by date
ORDER by 1,2

SELECT SUM(new_cases) as global_new_cases,
	SUM(cast(new_deaths as int)) as global_new_deaths, 
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 as Global_daily_mortality
FROM CovidPortfolioProject..CovidDeaths
WHERE continent is not null
ORDER by 1,2
-- This query states that, to date, 2% of all those infected with Covid19 on a daily basis died.

-- Lets join the data for Covid Deaths and Vaccinations
-- Looking at Total Population vs Vaccinations
-- Setting up a Rolling Count for Daily Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingVaccCount
FROM CovidPortfolioProject..CovidDeaths dea
JOIN CovidPortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- Temp Table (To allow for a comparison beyween our RollingVacCount and Population)

Drop table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
Continent nvarchar(255), 
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingVaccCount numeric,
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingVaccCount
FROM CovidPortfolioProject..CovidDeaths dea
JOIN CovidPortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *, (RollingVaccCount/Population)*100 as ProportionVaccinated
FROM #PercentPopulationVaccinated




-- Creating View for Later Visualisation
GO
CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingVaccCount,
FROM CovidPortfolioProject..CovidDeaths dea
JOIN CovidPortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null

