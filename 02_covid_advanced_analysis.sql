/*
1. Vaccination progress using CTE
    - computes rolling vaccinations and percent of population vaccinated by location
*/
With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) 
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) AS RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
where dea.continent is not NULL 
)
SELECT *,
       (CAST(RollingPeopleVaccinated AS float) / population) * 100 AS PercentVaccinated
FROM PopvsVac;

/*
2. Vaccination progress using temp table
    - stores cumulative vaccinations and percent vaccinated in a temp table for downstream analysis
*/

DROP Table if exists #PercentPopulationVaccinated 

Create Table #PercentPopulationVaccinated 
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) AS RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
where dea.continent is not NULL 
order by dea.location, dea.date

SELECT *,
       (CAST(RollingPeopleVaccinated AS float) / population) * 100 AS PercentVaccinated
FROM #PercentPopulationVaccinated 


/*
3. View for Tableau / BI tools
    - creates a view with rolling vaccinations for easier visualizations 
*/
USE PortfolioProject
GO

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) AS RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
where dea.continent is not NULL 

-- quick check of the view
select * 
from PercentPopulationVaccinated



/*
4. Daily trend metrics (new cases)
    - adds previous-day cases, daily change, and 7-day moving average per location
*/
SELECT
    location,
    date,
    new_cases,
    LAG(new_cases) OVER (PARTITION BY location ORDER BY date) AS PrevDayCases,
    (new_cases - LAG(new_cases) OVER (PARTITION BY location ORDER BY date)) AS DailyIncrease,
    AVG(new_cases * 1.0) OVER (
        PARTITION BY location
        ORDER BY date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW  -- look at current day + the previous 6 days
    ) AS SevenDayAvgCases
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL;

/*
5. Aggregated totals with ROLLUP
    - includes continent-level, country-level, and a grand total row via ROLLUP
*/
SELECT
    continent,
    location,
    SUM(new_cases) AS TotalCases,
    SUM(new_deaths) AS TotalDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY ROLLUP (continent, location);


/*
6. Top 5 countries per day by new cases
    - ranks countries by new_cases for each date and returns top 5
*/
WITH RankedCases AS (
    SELECT
        location,
        date,
        new_cases,
        RANK() OVER (
            PARTITION BY date
            ORDER BY new_cases DESC
        ) AS CaseRank
    FROM PortfolioProject..CovidDeaths
    WHERE continent IS NOT NULL
      AND new_cases IS NOT NULL   
      AND new_cases > 0           
)
SELECT *
FROM RankedCases
WHERE CaseRank <= 5
ORDER BY date, CaseRank;