-- INPUT: 
	-- STROMY_DATABAZE
	-- STROMY_WGS84
	-- OBCE_STROMY
	-- OBCE_GPS
	-- stromy_taxony_FULL
-- OUTPUT:
	-- STROMY_SJTSK
	-- OBCE_STROMY_OBCE_GPS
	-- TAXONY_CLEAN
	-- PAMATNE_STROMY_CLEAN

----------------------------
-- TRANSFORMACE - ČÁST 1: 
    -- STROMY_DATABAZE => STROMY_SJTSK
----------------------------

-- SMAZÁNÍ ZÁZNAMU S '' VE SLOUPCI KOD (5501 záznamů => 5500 záznamů)
DELETE FROM STROMY_DATABAZE 
WHERE "Kod" = 'COUNT:'
;

-- PŘIDÁNÍ SLOUPCŮ: LONGITUDE_KROVAK + LATITUDE_KROVAK
ALTER TABLE STROMY_DATABAZE
    ADD COLUMN LONGITUDE_KROVAK FLOAT
;

ALTER TABLE STROMY_DATABAZE
    ADD COLUMN LATITUDE_KROVAK FLOAT
;

-- Z PRVNÍHO BLOKU {X:…, Y:…} V ŘETĚZCI "Souradnice" ZÍSKÁ X A Y
-- PŘEVEDE ČÁRKU NA TEČKU A ULOŽÍ ČÍSLA JAKO LONGITUDE_KROVAK A LATITUDE_KROVAK.
-- POKUD JE V TEXTU VÍCE BLOKŮ, POUŽIJE SE JEN PRVNÍ.
-- POKUD ZA X: NEJSOU ČÍSLA, REGEX NENAJDE NIC => VRÁTÍ NULL.
-- Např. ze záznamu ve sloupci "Souřadnice": {X:1093518,00, Y:494710,00} {X:1093505,00, Y:494705,00} {X:1093480,00, Y:494694,00} {X:1093478,00, Y:494690,00} {X:1093435,00, Y:494669,00} {X:1093383,00, Y:494654,00} {X:1093365,00, Y:494649,00} {X:1093538,00, Y:494720,00} {X:1093577,00, Y:494724,00} {X:1093561,00, Y:494732,00} {X:1093494,00, Y:494700,00} {X:1093404,00, Y:494659,00} ... se stane 1093518.00 (LONGITUDE_KROVAK) a 494710.00 (LATITUDE_KROVAK).
-- VOLÍME VŽDY JEN PRVNÍ ZÁZNAM, PROTOŽE DATA NEDEINUJÍ, KTERÉ SOUŘADNICE JSOU PRO KTERÝ STROM ZE SKUPINY STROMŮ 
    -- VÍME, ŽE NĚKTERÝ ZE SKUPINY STROMŮ MÁ NĚKTEROU ZE SOUŘADNIC, ALE NENÍ NAPÁROVANÝ NA KONKRÉTNÍ KOMBINACI
    -- TABULKA CENTROID PRACUJE TÉŽ JEN S PRVNÍM ZÁZNAMEM - PŘEJÍMÁME TENTO SYSTÉM
UPDATE STROMY_DATABAZE
SET
    LONGITUDE_KROVAK = TO_DECIMAL(
        REPLACE(
            REGEXP_SUBSTR(
                REGEXP_SUBSTR("Souradnice", '\\{X:[^}]*\\}'),
                'X:([0-9]+,[0-9]+)', 1, 1, 'e', 1
            ),
            ',', '.'
        ),
        10, 2
    ),
    LATITUDE_KROVAK = TO_DECIMAL(
        REPLACE(
            REGEXP_SUBSTR(
                REGEXP_SUBSTR("Souradnice", '\\{X:[^}]*\\}'),
                'Y:([0-9]+,[0-9]+)', 1, 1, 'e', 1
            ),
            ',', '.'
        ),
        10, 2
    )
;

-- UPPERCASE + TRIM PRO VŠECHNY HODNOTY
UPDATE STROMY_DATABAZE
SET 
    "Kod" = UPPER(TRIM("Kod"))
    , "Stary_kod" = UPPER(TRIM("Stary_kod"))
    , "Typ_objektu" = UPPER(TRIM("Typ_objektu"))
    , "Nazev" = UPPER(TRIM("Nazev"))
    , "Datum_vyhlaseni" = UPPER(TRIM("Datum_vyhlaseni"))
    , "Datum_zruseni_vyrazeni" = UPPER(TRIM( "Datum_zruseni_vyrazeni"))
    , "Ochranne_pasmo_Typ" = UPPER(TRIM("Ochranne_pasmo_Typ"))
    , "Ochranne_pasmo_Popis" = UPPER(TRIM("Ochranne_pasmo_Popis"))
    , "Pocet_vyhlaseny" = UPPER(TRIM("Pocet_vyhlaseny"))
    , "Pocet_skutecny" = UPPER(TRIM("Pocet_skutecny"))
    , "Poznamka" = UPPER(TRIM("Poznamka"))
    , "Souradnice" = UPPER(TRIM("Souradnice"))
    , "Zpusob_urceni_souradnic" = UPPER(TRIM("Zpusob_urceni_souradnic"))
    , "Puvod_souradnic" = UPPER(TRIM("Puvod_souradnic"))
    , "Kraj" = UPPER(TRIM("Kraj"))
    , "Okres" = UPPER(TRIM("Okres"))
    , "Obec_s_rozsirenou_pusobnosti" = UPPER(TRIM("Obec_s_rozsirenou_pusobnosti"))
    , "Organ_ochrany_prirody" = UPPER(TRIM("Organ_ochrany_prirody"))
    , "Dat_ucinnosti_nejnovejsiho_vyhl_predpisu" = UPPER(TRIM("Dat_ucinnosti_nejnovejsiho_vyhl_predpisu"))
    , "Dat_vydani_nejnovejsiho_vyhl_predpisu" = UPPER(TRIM("Dat_vydani_nejnovejsiho_vyhl_predpisu"))
    , "Ostatni_informace" = UPPER(TRIM("Ostatni_informace"))
    , "LONGITUDE_KROVAK" = UPPER(TRIM("LONGITUDE_KROVAK"))
    , "LATITUDE_KROVAK" = UPPER(TRIM("LATITUDE_KROVAK"))
;

-- VYTVOŘENÍ NOVÉ TABULKY STROMY_SJTSK
-- VE VÝSLEDNÉ TABULCE DVA NOVÉ SLOUPCE SE SOUŘADNICEMI S-JTSK
CREATE OR REPLACE TABLE STROMY_SJTSK AS
	SELECT "Kod"
    	, "Stary_kod" AS STARY_KOD
    	, "Typ_objektu" AS TYP_OBJEKTU
    	, "Nazev" AS NAZEV
    	, CASE
        	WHEN "Datum_vyhlaseni" = '' THEN 'NEZNÁMÉ'
        	ELSE "Datum_vyhlaseni"
        	END AS DATUM_VYHLASENI_EDIT
    	, "Datum_zruseni_vyrazeni" AS DATUM_ZRUSENI_VYRAZENI
    	, "Ochranne_pasmo_Typ" AS OCHRANNE_PASMO_TYP
    	, "Ochranne_pasmo_Popis" AS OCHRANNE_PASMO_POPIS
    	, "Pocet_vyhlaseny" AS POCET_VYHLASENY
    	, "Pocet_skutecny" AS POCET_SKUTECNY
    	, "Poznamka" AS POZNAMKA
    	, "Souradnice" AS SOURADNICE
    	, "Zpusob_urceni_souradnic" AS ZPUSOB_URCENI_SOURADNIC
    	, "Puvod_souradnic" AS PUVOD_SOURADNIC
    	, "Kraj" AS KRAJ
    	, "Okres" AS OKRES
    	, "Obec_s_rozsirenou_pusobnosti" AS OBEC_S_ROZSIRENOU_PUSOBNOSTI
    	, "Organ_ochrany_prirody" AS ORGAN_OCHRANY_PRIRODY
    	, "Ostatni_informace" AS OSTATNI_INFORMACE
    	, LONGITUDE_KROVAK
    	, LATITUDE_KROVAK
	FROM STROMY_DATABAZE
;

-- TABLEAU NEUMÍ ROZEZNAT SOUŘADNICE V S-JTSK ("KŘOVÁK") => V PYTHONU PŘEVOD S-JTSK na WGS84:
	-- reseni_gps.ipynb: 
		-- INPUT = STROMY_SJTSK
		-- OUTPUT = STROMY_WGS84

----------------------------
-- TRANSFORMACE - ČÁST 2: 
    -- STROMY_WGS84 => PAMATNE_STROMY_CLEAN
----------------------------

-- ====> NAHRAZENÍ 'inf' v STROMY_WGS84 => NULL v "lat" a "long"

-- POVOLENÍ NULL VE SLOUPCI "lat"
ALTER TABLE STROMY_WGS84
ALTER COLUMN "lat" DROP NOT NULL;

-- POVOLENÍ NULL VE SLOUPCI "long"
ALTER TABLE STROMY_WGS84
ALTER COLUMN "long" DROP NOT NULL;

-- nahrazuju 'int' hodnotou NULL v obou sloupcích = 1684 záznamů updatováno na NULL
UPDATE STROMY_WGS84
SET
    "lat" = NULLIF("lat", 'inf'),
    "long" = NULLIF("long", 'inf')
WHERE "lat" = 'inf' OR "long" = 'inf'
;

-- VYTVOŘENÍ TABULKY OBCE_STROMY_OBCE_GPS = OBCE S ROZŠÍŘENOU PŮSOBNOSTÍ ZE STROMOVÉHO DATASETU + GPS
CREATE OR REPLACE TABLE OBCE_STROMY_OBCE_GPS AS
SELECT S.OBEC_S_ROZSIRENOU_PUSOBNOSTI
    , S.OBEC
    , S.OKRES
    , S.KRAJ
    , G.LAT_OBEC
    , G.LONG_OBEC
FROM OBCE_STROMY AS S
INNER JOIN OBCE_GPS AS G ON 
    S.STROMY_KEY = G.GPS_KEY
;

-- DOPLNĚNÍ 'NEZNÁMÝ DO TAXON_CZ A LAT'
UPDATE "stromy_taxony_FULL"
SET
    "taxon_cz" = 'NEUVEDENO',
    "taxon_lat" = 'NEUVEDENO'
WHERE "taxon_cz" = '' OR "taxon_lat" = ''
;

-- V TABULCE TAXONŮ NASTAVUJU PRÁZDNÝ STRING V TAXON_CZ A TAXON_LAT NA 'NEZNÁMÝ'
UPDATE "stromy_taxony_FULL"
SET
    "taxon_cz" = 'NEZNÁMÝ',
    "taxon_lat" = 'NEZNÁMÝ'
WHERE "taxon_cz" = '' OR "taxon_lat" = ''
;

-- vytvoření tabulky TAXONY_CLEAN
-- 6 077 = záznamy, kde je více taxonů v jednom řádku, rozděluju na více řádků se stejným kódem ---- dávám do transformace
CREATE OR REPLACE TABLE TAXONY_CLEAN AS
SELECT 
      "kod" AS KOD
    , "id" AS ID_WEB
    , "nazev" AS NAZEV
    , TRIM(cz.value) AS TAXON_CZ
    , TRIM(lat.value) AS TAXON_LAT
    , TRIM(cnt.value) AS POCET_STROMU_NA_TENTO_TAXON
    , "taxon_cnt_sum" AS POCET_VSECH_STROMU_NA_STANOVISTI
    , "pocet_skutecny" AS POCET_SKUTECNY
    , "taxon_confirmed" AS POCET_CONFIRMED
    , "taxon_warning" AS TAXON_WARNING
FROM "stromy_taxony_FULL"
    , LATERAL FLATTEN(
        INPUT => SPLIT("taxon_cz", ';')
      ) cz
    , LATERAL FLATTEN(
        INPUT => SPLIT("taxon_lat", ';')
      ) lat
    , LATERAL FLATTEN(
        INPUT => SPLIT("taxon_cnt", ';')
      ) cnt
WHERE cz.index = lat.index AND cz.index = cnt.index
;

-- UPRAVENÍ TAXON_CNT A TAXON_CNT_SUM

UPDATE TAXONY_CLEAN
SET
    POCET_STROMU_NA_TENTO_TAXON      = 'NEUVEDENO',
    POCET_VSECH_STROMU_NA_STANOVISTI = 'NEUVEDENO'
WHERE 
      POCET_STROMU_NA_TENTO_TAXON IN ('', '0')
   OR POCET_VSECH_STROMU_NA_STANOVISTI IN ('', '0')
;

-- VYTVOŘENÍ TABULKY PAMATNE_STROMY_CLEAN
-- JOIN STROMY_WGS84 + OBCE_STROMY_OBCE_GPS + TAXONY_CLEAN ==> TABULKA, KDE MÁM JAK POLOHU STROMŮ, TAK GPS OBCÍ (TAKŽE BY TABLEAU MĚLO VIDĚT VŠECH 205 OBCÍ), TAK TAXONŮ

CREATE OR REPLACE TABLE PAMATNE_STROMY_CLEAN AS
SELECT
      TRIM(S."Kod") AS KOD
    , TRIM(S.NAZEV) AS NAZEV
    , TRIM(S.TYP_OBJEKTU) AS TYP_OBJEKTU
    , TRIM(T.TAXON_CZ) AS TAXON_CZ
    , TRIM(T.TAXON_LAT) AS TAXON_LAT
    , TRIM(T.POCET_STROMU_NA_TENTO_TAXON) AS POCET_STROMU_NA_TENTO_TAXON
    , TRIM(T.POCET_VSECH_STROMU_NA_STANOVISTI) AS POCET_VSECH_STROMU_NA_STANOVISTI
    , S.POCET_VYHLASENY AS POCET_VYHLASENY
    , S.POCET_SKUTECNY AS POCET_SKUTECNY
    , TRIM(T.TAXON_WARNING) AS TAXON_WARNING
    , S."lat" AS LAT_WGS84_STROM
    , S."long" AS LONG_WGS84_STROM
    , TRIM(S.POZNAMKA) AS POZNAMKA
    , TRIM(O.OBEC) AS OBEC
    , O.LAT_OBEC AS LAT_WGS84_OBEC
    , O.LONG_OBEC AS LONG_WGS84_OBEC
    , TRIM(O.OKRES) AS OKRES
    , TRIM(O.KRAJ) AS KRAJ
    , TRIM(S.ORGAN_OCHRANY_PRIRODY) AS ORGAN_OCHRANY_PRIRODY
    , S.DATUM_VYHLASENI_EDIT AS DATUM_VYHLASENI
    , S.DATUM_ZRUSENI_VYRAZENI AS DATUM_ZRUSENI_VYRAZENI
    , TRIM(S.OCHRANNE_PASMO_TYP) AS OCHRANNE_PASMO_TYP
    , TRIM(S.OCHRANNE_PASMO_POPIS) AS OCHRANNE_PASMO_POPIS
    , TRIM(S.OSTATNI_INFORMACE) AS OSTATNI_INFORMACE
    , S.LATITUDE_KROVAK AS LAT_KROVAK_STROM
    , S.LONGITUDE_KROVAK AS LONG_KROVAK_STROM
    , TRIM(S.SOURADNICE) AS PUVODNI_SOURADNICE
    , TRIM(S.ZPUSOB_URCENI_SOURADNIC) AS ZPUSOB_URCENI_SOURADNIC
    , TRIM(S.PUVOD_SOURADNIC) AS PUVOD_SOURADNIC
    , TRIM(T.ID_WEB) AS ID_WEB
FROM STROMY_WGS84 AS S
LEFT JOIN TAXONY_CLEAN AS T 
       ON S."Kod" = T.KOD
LEFT JOIN OBCE_STROMY_OBCE_GPS AS O 
       ON S.OBEC_S_ROZSIRENOU_PUSOBNOSTI = O.OBEC_S_ROZSIRENOU_PUSOBNOSTI
ORDER BY KOD
;

-- DODATEČNÝ UPPERCASE
UPDATE PAMATNE_STROMY_CLEAN
SET
      KOD                               = UPPER(TRIM(KOD))
    , NAZEV                             = UPPER(TRIM(NAZEV))
    , TYP_OBJEKTU                       = UPPER(TRIM(TYP_OBJEKTU))
    , TAXON_CZ                          = UPPER(TRIM(TAXON_CZ))
    , TAXON_LAT                         = UPPER(TRIM(TAXON_LAT))
    , POCET_STROMU_NA_TENTO_TAXON       = TRIM(POCET_STROMU_NA_TENTO_TAXON)
    , POCET_VSECH_STROMU_NA_STANOVISTI  = TRIM(POCET_VSECH_STROMU_NA_STANOVISTI)
    , POCET_VYHLASENY                   = TRIM(POCET_VYHLASENY)
    , POCET_SKUTECNY                    = TRIM(POCET_SKUTECNY)
    , TAXON_WARNING                     = UPPER(TRIM(TAXON_WARNING))
    , LAT_WGS84_STROM                   = TRIM(LAT_WGS84_STROM)
    , LONG_WGS84_STROM                  = TRIM(LONG_WGS84_STROM)
    , POZNAMKA                          = UPPER(TRIM(POZNAMKA))
    , OBEC                              = UPPER(TRIM(OBEC))
    , LAT_WGS84_OBEC                    = TRIM(LAT_WGS84_OBEC)
    , LONG_WGS84_OBEC                   = TRIM(LONG_WGS84_OBEC)
    , OKRES                             = UPPER(TRIM(OKRES))
    , KRAJ                              = UPPER(TRIM(KRAJ))
    , ORGAN_OCHRANY_PRIRODY             = UPPER(TRIM(ORGAN_OCHRANY_PRIRODY))
    , DATUM_VYHLASENI                   = TRIM(DATUM_VYHLASENI)
    , DATUM_ZRUSENI_VYRAZENI            = TRIM(DATUM_ZRUSENI_VYRAZENI)
    , OCHRANNE_PASMO_TYP                = UPPER(TRIM(OCHRANNE_PASMO_TYP))
    , OCHRANNE_PASMO_POPIS              = UPPER(TRIM(OCHRANNE_PASMO_POPIS))
    , OSTATNI_INFORMACE                 = UPPER(TRIM(OSTATNI_INFORMACE))
    , LAT_KROVAK_STROM                  = TRIM(LAT_KROVAK_STROM)
    , LONG_KROVAK_STROM                 = TRIM(LONG_KROVAK_STROM)
    , PUVODNI_SOURADNICE                = UPPER(TRIM(PUVODNI_SOURADNICE))
    , ZPUSOB_URCENI_SOURADNIC           = UPPER(TRIM(ZPUSOB_URCENI_SOURADNIC))
    , PUVOD_SOURADNIC                   = UPPER(TRIM(PUVOD_SOURADNIC))
    , ID_WEB                            = TRIM(ID_WEB)
;