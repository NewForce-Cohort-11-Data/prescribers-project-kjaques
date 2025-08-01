

-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?
(SELECT 
	COUNT(npi)
FROM
	prescriber)
EXCEPT
(SELECT
	npi
FROM 
	prescription);

-- Question 2
-- a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
SELECT 
	generic_name,
	SUM(total_claim_count) AS claims
FROM 
	prescription
INNER JOIN drug
	USING(drug_name)
WHERE npi IN (
	SELECT
		npi
	FROM
		prescriber
	WHERE specialty_description = 'Family Practice'
	)
GROUP BY generic_name
ORDER BY claims DESC
LIMIT 5;

-- b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
SELECT 
	generic_name,
	SUM(total_claim_count) AS claims
FROM 
	prescription
INNER JOIN drug
	USING(drug_name)
WHERE npi IN (
	SELECT
		npi
	FROM
		prescriber
	WHERE specialty_description = 'Cardiology'
	)
GROUP BY generic_name
ORDER BY claims DESC
LIMIT 5;

-- c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.
WITH family_cardio AS (
	(SELECT 
		generic_name,
		SUM(total_claim_count) AS claims
	FROM 
		prescription
	INNER JOIN drug
		USING(drug_name)
	WHERE npi IN (
		SELECT
			npi
		FROM
			prescriber
		WHERE specialty_description = 'Family Practice'
		)
	GROUP BY generic_name)
	UNION ALL
	(SELECT 
		generic_name,
		SUM(total_claim_count) AS claims
	FROM 
		prescription
	INNER JOIN drug
		USING(drug_name)
	WHERE npi IN (
		SELECT
			npi
		FROM
			prescriber
		WHERE specialty_description = 'Cardiology'
		)
	GROUP BY generic_name)
	)
SELECT 
	generic_name,
	SUM(claims) AS total_claims
FROM 
	family_cardio
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;

-- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee. 
-- a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
SELECT
	nppes_provider_city AS city,
	npi, 
	SUM(total_claim_count) AS claims
FROM 
	prescription
INNER JOIN 
	prescriber
	USING(npi)
WHERE nppes_provider_city ILIKE '%nashville%'
GROUP BY npi, city
ORDER BY claims DESC;

-- b. Now, report the same for Memphis.
SELECT
	nppes_provider_city AS city,
	npi, 
	SUM(total_claim_count) AS claims
FROM 
	prescription
INNER JOIN 
	prescriber
	USING(npi)
WHERE nppes_provider_city ILIKE '%memphis%'
GROUP BY npi, city
ORDER BY claims DESC;

-- c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
SELECT
	nppes_provider_city AS city,
	npi, 
	SUM(total_claim_count) AS claims
FROM 
	prescription
INNER JOIN 
	prescriber
	USING(npi)
WHERE nppes_provider_city ILIKE ANY(ARRAY['%nashville%','%memphis%', '%knoxville%', '%chattanooga%'])
GROUP BY npi, city
ORDER BY claims DESC;

-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.
SELECT
	county,
	overdose_deaths
FROM 
	fips_county AS f
LEFT JOIN 
	overdose_deaths AS o
	ON f.fipscounty::integer = o.fipscounty
WHERE overdose_deaths > (
	SELECT
		AVG(overdose_deaths)
	FROM
		overdose_deaths
	)

-- Question 5
-- a. Write a query that finds the total population of Tennessee.
SELECT 
	SUM(population)
FROM 
	population
INNER JOIN fips_county
	USING(fipscounty)
WHERE state = 'TN'

-- b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.

SELECT 
	county,
	population,
	((population / (
		SELECT 
			SUM(population) AS total
		FROM 
			population
		INNER JOIN fips_county
			USING(fipscounty)
		WHERE state = 'TN'
		))*100) AS tn_percent
FROM 
	fips_county
INNER JOIN population
	USING(fipscounty)
WHERE state = 'TN'
ORDER BY tn_percent DESC;