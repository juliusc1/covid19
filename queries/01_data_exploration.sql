/*
1. Total Cases vs Total Deaths
	- Shows the cumulative case fatality rate (CFR) over time in the United States
*/
select location, date, total_cases, total_deaths, (total_deaths * 1.0 / total_cases) * 100 AS DeathPercentage
from PortfolioProject..CovidDeaths
where location like '%states' and continent is not NULL 
order by 1,2

/*
2. Total Cases vs Population 
	- Shows the percentage of the population has been infected over time
*/
select location, date, population, total_cases, (total_cases * 1.0 / population) * 100 AS PercentPopulationInfected
from PortfolioProject..CovidDeaths
where location like '%states'
order by 1,2

/*
3. Countries with Highest Infection Rate vs Population
	- Finding which countries have the highest share of population infected 
*/
select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases * 1.0 / population)) * 100 AS PercentPopulationInfected
from PortfolioProject..CovidDeaths
--where location like '%states'
group by location, population
order by PercentPopulationInfected DESC

/*
4. Countries with Highest Death Count
	- Shows countries total death count and ordered by highest to lowest
*/
select location, MAX(total_deaths) as TotalDeathCount
from PortfolioProject..CovidDeaths
--where location like '%states'
where continent is not NULL 
group by location
order by TotalDeathCount desc

/*
5. Continents with Highest Death Count
	- Similar to query 4, but aggregate total deaths at the continent level by showing
	  continents with the highest death count per population 
*/
select continent, MAX(total_deaths) as TotalDeathCount
from PortfolioProject..CovidDeaths
--where location like '%states'
where continent is not NULL 
group by continent 
order by TotalDeathCount desc

/*
6. Global Totals and Overall Fatality Percentage
	- Shows global totals of cases and deaths for the entire dataset
*/
select SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths, SUM(cast(new_deaths as float))/NULLIF(SUM(new_cases), 0)*100 AS DeathPercentage
from PortfolioProject..CovidDeaths
where continent is not NULL 

/*
7. Population vs New Vaccinations (Rolling)
	- Track vaccination progress over time by country by looking at total population vs new vaccinations per day
*/

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) AS RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
where dea.continent is not NULL 
order by 2,3