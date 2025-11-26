-- Relativní vážený tlak
/*
Výchozí tabulkou byla atributová tabulka, která vznikla v průběhu analýzy v programu QGIS:PO_IMPACT
Vážená zasažená plocha
= součet (plocha zásahu * váha zdroje)
kde váhy jsou:
velký zdroj = 3
střední = 2
malý = 1

Normalizace:
Index tlaku = (vážená zasažená plocha) / celková rozloha lokality
→ výsledkem je relativní hodnota:
0 = žádný tlak
1 = “teoreticky” celá plocha zasažená pouze malými zdroji (nebo 1/3 velkými — ale to je účel vážení)
1 = území trpí kumulací velkých zdrojů nebo mnoha menších
Tento index byl využit pro barevné škálování v mapě (QGIS).
*/
CREATE TABLE TLAK_PTACI_OBLASTI AS
WITH SOURCES AS (
    SELECT *,
        CASE 
            WHEN "layer" LIKE '%VELKE%' THEN 3
            WHEN "layer" LIKE '%STREDNI%' THEN 2
            WHEN "layer" LIKE '%MALE%'  THEN 1
            ELSE 1
        END AS ZDROJ_VAHA
    FROM PO_IMPACT
),
AGG AS (
    SELECT
        SITECODE,
        NAZEV,
        ROZL,
        SUM(ZDROJ_VAHA * AREA_IMPACT) AS VAHA_AREA
    FROM SOURCES
    GROUP BY SITECODE, NAZEV, ROZL
)
SELECT
    SITECODE,
    NAZEV,
    ROZL,
    VAHA_AREA,
    VAHA_AREA / ROZL AS TLAK_INDEX
FROM AGG;