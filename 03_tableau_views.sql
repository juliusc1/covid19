/* Queries used for Tableau - COVID19 */

/*
1. Global totals for cases & deaths (entire dataset) 
   - Calculates total global cases, total global deaths, and overall global death percentage
   - CAST + NULLIF used to avoid integer division and errors
*/

select SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths, SUM(cast(new_deaths as float))/NULLIF(SUM(new_cases), 0)*100 AS DeathPercentage
from PortfolioProject..CovidDeaths
where continent is not NULL 
order by 1,2

/*
2. Total deaths by region-like locations (e.g., "Asia", "Africa)
   - continent is NULL filters out true countries
   - excludes 'World', 'European Union',and 'International' for consistency with other queries
*/

select location, SUM(cast(new_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is NULL and location not in ('World', 'European Union', 'International')
group by location 
order by TotalDeathCount desc

/*
3. Highest infection count and percent infected per location
   - MAX(total_cases) gives peak cumulative infections
   - percent of population infected uses max(total_cases/population)
*/

select location, population, 
	MAX(total_cases) as HighestInfectionCount, 
	MAX((total_cases * 1.0 / population))*100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
--where location like '%states%'
group by location, population
order by PercentPopulationInfected desc 

/*
4. Daily infection percentage per location
   - shows infection progression over time by date
   - same logic as query 3 but broken down per day
*/

select location, population, date,
	MAX(total_cases) as HighestInfectionCount,
	MAX((total_cases * 1.0 /population)) * 100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
--where location like '%states%' --optional filter
group by location, population, date
order by PercentPopulationInfected desc 
