-- INPUT: 
	-- NATURA2000SITES
	-- AREA_EU_OBOJI
-- OUTPUT:
	-- COUNTRY_AREA_INC_FRESH
	-- COUNTRY_AREA_EXC_FRESH
	-- NATURA2000SITES_CLEAN

----------------------------
-- TRANSFORMACE: NATURA2000SITES_CLEAN
----------------------------


-- VÝSLEDKEM JE TABULKA NATURA2000SITES S ÚDAJEM O ROZLOZE STÁTŮ (S I BEZ VODNÍCH PLOCH)

-- KROK 1

-- vytvoření tabulky s rozlohami zemí VČETNĚ FRESHWATER = T2
-- COUNTRY_AREA_INC_FRESH ZNAMENA údaj "Total area" (s pevninskými vodními plochami - freshwater)
-- ec.europa.eu/eurostat/databrowser/view/REG_AREA3__custom_18483361/default/table
CREATE OR REPLACE TABLE COUNTRY_AREA_INC_FRESH AS 
    SELECT
          UPPER(SPLIT_PART("geo", ':', 1)) AS ZEME_ZKRATKA_PRAC
        , UPPER(SPLIT_PART("geo", ':', 2)) AS COUNTRY_NAME
        , CASE
            WHEN ZEME_ZKRATKA_PRAC = 'EL' 
            THEN 'GR' 
            ELSE UPPER(ZEME_ZKRATKA_PRAC) 
          END AS COUNTRY_CODE_INC
        , OBS_VALUE AS COUNTRY_AREA_INC_FRESH_KM2
    FROM AREA_EU_OBOJI
    WHERE "landuse" LIKE 'TOTAL:Total area'
;

-- vytvoření tabulky s rozlohami zemí BEZ FRESHWATER = T3
-- COUNTRY_AREA_EXC_FRESH ZNAMENA údaj "L0008:Land area - total" (bez pevninských vodních ploch - freshwater)
-- ec.europa.eu/eurostat/databrowser/view/REG_AREA3__custom_18483361/default/table
CREATE OR REPLACE TABLE COUNTRY_AREA_EXC_FRESH AS 
    SELECT
          UPPER(SPLIT_PART("geo", ':', 1)) AS ZEME_ZKRATKA_PRAC
        , UPPER(SPLIT_PART("geo", ':', 2)) AS COUNTRY_NAME
        , CASE 
            WHEN ZEME_ZKRATKA_PRAC = 'EL' 
            THEN 'GR' 
            ELSE UPPER(ZEME_ZKRATKA_PRAC) 
          END AS COUNTRY_CODE_EXC
        , OBS_VALUE AS COUNTRY_AREA_EXC_FRESH_KM2
    FROM AREA_EU_OBOJI
    WHERE "landuse" LIKE 'L0008:Land area - total'
;

-- KROK 2

-- vytvoření tabulky NATURA2000SITES_CLEAN POMOCÍ JOINU: COUNTRY_AREA_INC_FRESH + COUNTRY_AREA_EXC_FRESH + NATURA2000SITES
CREATE OR REPLACE TABLE NATURA2000SITES_CLEAN AS
    SELECT T2.COUNTRY_CODE_INC
    	, T2.COUNTRY_NAME
    	, T2.COUNTRY_AREA_INC_FRESH_KM2
    	, T3.COUNTRY_AREA_EXC_FRESH_KM2
    	, UPPER(T1.SITECODE) AS SITE_CODE
    	, UPPER(T1.SITENAME) AS SITE_NAME
    	, UPPER(T1.SITETYPE) AS SITE_TYPE
    	, T1.AREAHA AS SITE_AREA_HA
    	, T1.LENGTHKM AS SITE_LENGTH_KM
    	, T1.MARINE_AREA_PERCENTAGE AS SITE_MARINE_PER
    	, T1.LATITUDE AS SITE_LATITUDE
    	, T1.LONGITUDE AS SITE_LONGITUDE
        , CASE 
    		WHEN T1.MARINE_AREA_PERCENTAGE = '' 
    		THEN '0' 
    		ELSE T1.MARINE_AREA_PERCENTAGE 
    	  END AS SITE_MARINE_PER_0
    --  , DOCUMENTATION
	--  , QUALITY
	--  , DESIGNATION
	--  , OTHERCHARACT
    --  , DATE_COMPILATION
	--  , DATE_UPDATE 
	--  , DATE_SPA AS DATE_SPECIAL_PROTECTION_AREA
	--  , SPA_LEGAL_REFERENCE
	--  , DATE_PROP_SCI AS DATE_PROPOSED_SITES_OF_COMMUNITY_IMPORTANCE
	--  , DATE_CONF_SCI AS DATE_CONF_SITES_OF_COMMUNITY_IMPORTANCE
	--  , DATE_SAC AS DATE_SPECIAL_AREAS_OF_CONSERVATION
	--  , SAC_LEGAL_REFERENCE AS DATE_OF_LEGAL_SPECIAL_AREAS_OF_CONSERVATION
	--  , EXPLANATIONS
	--  , INSPIRE_ID
	FROM NATURA2000SITES AS T1
	LEFT JOIN COUNTRY_AREA_INC_FRESH AS T2 
    	ON UPPER(T1.COUNTRY_CODE) = T2.COUNTRY_CODE_INC
	LEFT JOIN COUNTRY_AREA_EXC_FRESH AS T3 
    	ON UPPER(T1.COUNTRY_CODE) = T3.COUNTRY_CODE_EXC
	ORDER BY T2.COUNTRY_NAME DESC
;

/*
----------------------------
OVERVIEW: TABULKA NATURA2000SITES:
----------------------------

 #   Column                  Non-Null Count  Dtype  
---  ------                  --------------  -----  
 0   COUNTRY_CODE            27165 non-null  object 
 1   SITECODE                27165 non-null  object 
 2   SITENAME                27165 non-null  object 
 3   SITETYPE                27165 non-null  object 
 4   DATE_COMPILATION        27162 non-null  object 
 5   DATE_UPDATE             26599 non-null  object 
 6   DATE_SPA                5488 non-null   object 
 7   SPA_LEGAL_REFERENCE     5138 non-null   object 
 8   DATE_PROP_SCI           23888 non-null  object 
 9   DATE_CONF_SCI           16820 non-null  object 
 10  DATE_SAC                21538 non-null  object 
 11  SAC_LEGAL_REFERENCE     22018 non-null  object 
 12  EXPLANATIONS            2113 non-null   object 
 13  AREAHA                  27165 non-null  float64
 14  LENGTHKM                12006 non-null  float64
 15  MARINE_AREA_PERCENTAGE  21465 non-null  float64
 16  DOCUMENTATION           17567 non-null  object 
 17  QUALITY                 25939 non-null  object 
 18  DESIGNATION             6328 non-null   object 
 19  OTHERCHARACT            25333 non-null  object 
 20  LATITUDE                27165 non-null  float64
 21  LONGITUDE               27165 non-null  float64
 22  INSPIRE_ID              3137 non-null   object