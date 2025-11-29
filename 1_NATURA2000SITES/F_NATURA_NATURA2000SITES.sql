-- INPUT: 
	-- NATURA2000SITES
	-- AREA_EU_OBOJI
-- OUTPUT:
	-- COUNTRY_AREA_INC_FRESH
	-- COUNTRY_AREA_EXC_FRESH
	-- NATURA2000SITES_CLEAN

----------------------------
-- ENTITA NATURA2000SITES
----------------------------

-- Unikátní identifikátor v tabulce je SITECODE - kód lokality.
-- 0 = nejsou duplicity ve sloupci SITECODE = PK
SELECT SITECODE, COUNT(*) AS POCET_ZAZNAMU_NA_SITECODE
FROM NATURA2000SITES
GROUP BY SITECODE
HAVING COUNT(*) > 1;

-- 0 = Ve sloupci SITECODE nejsou nulové hodnoty ani prázdný string.
SELECT *
FROM NATURA2000SITES
WHERE SITECODE IS NULL OR SITECODE = ''
;

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

----------------------------
DOKUMENTACE:
----------------------------

COUNTRY_CODE - ED: Two digit country code the site belongs to.

SITECODE - ED: Unique code witch forms the key-item within the database.
- VD: The unique code comprises nine characters and consists of two components. The first two codes are the country code the remaining seven characters, which serve to create a unique alphanumeric code for each site.

HABITATCODE -ED: Code for the habitat type listed in Annex I of Directive 92/43/EEC.

SITENAME - ED: Site name in the local language.

SITETYPE - ED: Type of classification for the site. VD:
A: SPAs (Special Protection Areas - sites designated under the Birds Directive); 
B: SCIs and SACs (Sites of Community Importance and Special Areas of Conservation - sites designated under the Habitats Directive); 
C: where SPAs and SCIs/SACs boundaries are identical (sites designated under both directives).

DATE_COMPILATION - ED: The date information has been recorded in the Standard Data Form. The data field takes the form of the year (four digits) followed by the month in numeric form (two digits).

DATE_UPDATE - ED: The date when the information reported for the site was last changed. The data field takes the form of the year (four digits) followed by the month in numeric form (two digits).

DATE_SPA - ED: Date site classified as SPA.

SPA_LEGAL_REFERENCE - ED: The legal statement by the national authority in which the site was amended as SPA.

DATE_PROP_SCI - ED: Date site proposed as eligible for identification as a Site of Community importance (SCI).

DATE_CONF_SCI - ED: Date site has been confirmed as a Site of Community importance (SCI).

DATE_SAC - ED: Date site designated as SAC.

SAC_LEGAL_REFERENCE - ED: The legal statement by the national authority in which the site was amended as SAC.

EXPLANATIONS - ED: Additional explanations given by the country to support the dates designation

AREAHA - ED: Surface area of a site in hectares. Although it is an obligatory field, the value -99 is given for sites for witch the areas is unknown. A value of 0 cab be correct if the site is a cave or cliff. In this case the field 2.3 is obligatory.

LENGTHKM - ED: Site length is entered in kilometers.

MARINE_AREA_PERCENTAGE - ED: Percentage of the site considered as marine.

DOCUMENTATION - ED: Additional documentation existing as a reference for the site.

QUALITY - ED: Description of the site in terms of ecological quality.

DESIGNATION - ED: The local name of the official designation of the site.

OTHERCHARACT - ED: Additional description in the local language about the site.

LATITUDE - ED: The geographic coordinate in decimals of the site centre. (ETRS89 projection).

LONGITUDE - ED: The geographic coordinate in decimals of the site centre. (ETRS89 projection).

INSPIRE_ID - ED: The InspireID is defined by the Inspire Protected Sites specification and consists of three components: the localId, the nameSpace and the versionId.

*/