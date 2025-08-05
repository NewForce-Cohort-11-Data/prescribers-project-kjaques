-- Question 1
-- a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT 
	npi,
	SUM(total_claim_count) AS claim_total
FROM
	prescription
GROUP BY
	npi
ORDER BY claim_total DESC
LIMIT 1;

-- b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.
SELECT 
	nppes_provider_first_name, 
	nppes_provider_last_org_name, 
	specialty_description,
	SUM(total_claim_count) AS claim_total
FROM
	prescriber
INNER JOIN prescription
	USING(npi)
GROUP BY
	nppes_provider_first_name, 
	nppes_provider_last_org_name, 
	specialty_description
ORDER BY claim_total DESC
LIMIT 1;

-- Question 2
-- a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT 
	specialty_description,
	SUM(total_claim_count) AS claim_total
FROM
	prescriber
INNER JOIN prescription
	USING(npi)
GROUP BY
	specialty_description
ORDER BY claim_total DESC
LIMIT 1;

-- b. Which specialty had the most total number of claims for opioids?
SELECT 
	specialty_description, 
	SUM(total_claim_count) AS opioid_claims
FROM 
	prescription
INNER JOIN prescriber
	USING(npi)
INNER JOIN drug
	USING(drug_name)
WHERE 
	opioid_drug_flag = 'Y'
GROUP BY 
	specialty_description
ORDER BY 
	opioid_claims DESC
LIMIT 1;

-- c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT DISTINCT
	specialty_description,
	COUNT(
		CASE 
			WHEN npi IN(
				SELECT DISTINCT npi
				FROM prescription
				) THEN npi
		END
	) AS prescription_count
FROM 
	prescriber
GROUP BY specialty_description
ORDER BY prescription_count;
	
-- d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
WITH claims AS (
	SELECT
		specialty_description,
		COALESCE(SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count END), 0) AS opioid_claims,
		COALESCE(SUM(total_claim_count), 0) AS total_claims
	FROM prescriber
	LEFT JOIN prescription
		USING(npi)
	LEFT JOIN drug
		USING(drug_name)
	GROUP BY specialty_description
)
SELECT 
	specialty_description,
	CASE
		WHEN total_claims = 0 THEN 0
		ELSE ROUND(((opioid_claims / total_claims)*100), 2)
	END AS opioid_percentage
FROM claims
ORDER BY specialty_description;

-- Question 3
-- a. Which drug (generic_name) had the highest total drug cost?
SELECT 
	generic_name,
	SUM(total_drug_cost) AS total_cost
FROM 
	prescription
INNER JOIN
	drug
	USING(drug_name)
GROUP BY 
	generic_name, total_drug_cost
ORDER by total_cost DESC NULLS LAST
LIMIT 1;

-- b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.
WITH cost_per_day AS (
	SELECT 
		drug_name,
		ROUND((SUM(total_drug_cost) / SUM(total_day_supply)), 2) AS daily_cost
	FROM prescription
	GROUP BY drug_name
	ORDER BY daily_cost DESC
)
SELECT 
	generic_name
FROM cost_per_day
INNER JOIN drug
	USING(drug_name)
LIMIT 1;

-- Question 4
-- a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. Hint: You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/
SELECT 
	drug_name,
	CASE
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
	END AS drug_type
FROM drug;

-- b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT 
	CASE
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
	END AS drug_type,
	SUM(total_drug_cost)::money AS total_cost
FROM 
	drug
INNER JOIN prescription
	USING(drug_name)
WHERE 
	antibiotic_drug_flag = 'Y' OR opioid_drug_flag = 'Y'
GROUP BY 
	drug_type
ORDER BY 
	total_cost DESC;
	
-- Question 5
-- a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.
SELECT 
	COUNT(*)
FROM 
	cbsa
INNER JOIN 
	fips_county
	USING(fipscounty)
WHERE 
	state = 'TN';

-- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
(SELECT 
	cbsaname,
	SUM(population) AS pop
FROM 
	cbsa
INNER JOIN 
	population
	USING(fipscounty)
GROUP BY 
	cbsaname
ORDER BY 
	pop DESC
LIMIT 1)
UNION
(SELECT 
	cbsaname,
	SUM(population) AS pop
FROM 
	cbsa
INNER JOIN 
	population
	USING(fipscounty)
GROUP BY 
	cbsaname
ORDER BY 
	pop 
LIMIT 1)

-- c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT 
	county,
	population
FROM fips_county
INNER JOIN population
	USING(fipscounty)
WHERE fipscounty NOT IN (
	SELECT fipscounty
	FROM cbsa
	)
GROUP BY 
	county, population
ORDER BY population DESC
LIMIT 1;

-- Question 6
-- a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT 
	drug_name,
	total_claim_count
FROM
	prescription
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;

-- b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT 
	drug_name,
	total_claim_count,
	opioid_drug_flag
FROM
	prescription
INNER JOIN drug
	USING(drug_name)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;

-- c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT 
	drug_name,
	total_claim_count,
	opioid_drug_flag,
	nppes_provider_first_name, 
	nppes_provider_last_org_name
FROM
	prescription
INNER JOIN drug
	USING(drug_name)
INNER JOIN prescriber
	USING(npi)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;

-- Question 7
-- The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.

-- a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT 
	npi,
	drug_name
FROM 
	drug
CROSS JOIN 
	prescriber
WHERE 
	specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y';

-- b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
WITH pain_specialists AS (
SELECT 
	npi,
	drug_name
FROM 
	drug
CROSS JOIN 
	prescriber
WHERE 
	specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
)
SELECT 
	npi,
	drug_name,
	SUM(total_claim_count) AS claim_count
FROM 
	pain_specialists AS p1
LEFT JOIN 
	prescription AS p2
	USING(npi, drug_name)
GROUP BY npi, drug_name
ORDER BY claim_count DESC NULLS LAST;

-- c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
WITH pain_specialists AS (
	SELECT 
		npi,
		drug_name
	FROM 
		drug
	CROSS JOIN 
		prescriber
	WHERE 
		specialty_description = 'Pain Management'
		AND nppes_provider_city = 'NASHVILLE'
		AND opioid_drug_flag = 'Y'
)
SELECT 
	npi,
	drug_name,
	COALESCE(SUM(total_claim_count), 0) AS claim_count
FROM 
	pain_specialists AS p1
LEFT JOIN 
	prescription AS p2
	USING(npi, drug_name)
GROUP BY npi, drug_name
ORDER BY claim_count DESC;