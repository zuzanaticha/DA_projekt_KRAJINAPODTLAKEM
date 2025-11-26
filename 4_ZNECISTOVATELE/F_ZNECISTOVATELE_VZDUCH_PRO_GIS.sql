-- PIVOT - látky s hodnotami
CREATE OR REPLACE TABLE ZNECISTOVATELE_VZDUCH_PRO_GIS AS -- Vytvoření nové tabulky s agregovanými a pivotovanými daty o znečišťovatelích
/* ----------------------------------------------------------
   PRVNÍ CTE: ZDROJ
   - Agregace množství emisí podle provozovny, látky a typu úniku
   - Připojení souřadnic provozovny
   - Očista číselných hodnot (převod čárek na tečky, prázdné na NULL)
-----------------------------------------------------------*/
WITH ZDROJ AS (
    SELECT  
        T1."ICP",
        T1."Nazev_provozovny" AS PROVOZOVNA,
        T1."Nazev_typu_uniku" AS UNIK,
        T1."Nazev_latky",
        SUM(CAST(NULLIF(REPLACE(T1."Mnozstvi_celkem", ',', '.'), '') AS FLOAT)) AS MNOZSTVI_CELKEM,
        MAX(CAST(NULLIF(REPLACE(T2."jtskX", ',', '.'), '') AS FLOAT)) AS JTSK_X_PROVOZOVNA,
        MAX(CAST(NULLIF(REPLACE(T2."jtskY", ',', '.'), '') AS FLOAT)) AS JTSK_Y_PROVOZOVNA,
        MAX(CAST(NULLIF(REPLACE(T2."wgs84X", ',', '.'), '') AS FLOAT)) AS WGS84_X_PROVOZOVNA,
        MAX(CAST(NULLIF(REPLACE(T2."wgs84Y", ',', '.'), '') AS FLOAT)) AS WGS84_Y_PROVOZOVNA
    FROM ZNECISTOVATELE_UNIKY_A_PRENOSY T1
    LEFT JOIN ZNECISTOVATELE_PROVOZOVNY T2
        ON T1."ICP" = T2."ICP"
        AND T1."Nazev_provozovny" = T2."Nazev_provozovny"
    WHERE T1."Nazev_typu_uniku" = 'Úniky do ovzduší' -- Filtrování pouze na úniky do ovzduší    
    GROUP BY 
        T1."ICP",
        T1."Nazev_provozovny",
        T1."Nazev_typu_uniku",
        T1."Nazev_latky"
),
/* ----------------------------------------------------------
   DRUHÉ CTE: P
   - PIVOT dat podle názvu látky → každá látka dostane vlastní sloupec
-----------------------------------------------------------*/
P AS (
    SELECT *
    FROM ZDROJ
    PIVOT (
        SUM(MNOZSTVI_CELKEM)
        FOR "Nazev_latky" IN (
                            'Amoniak (NH3)' AS AMONIAK_NH3
                            , 'Arsen a sloučeniny (jako As)' AS ARSEN_SLOUCENINY
                            , 'Azbest' AS AZBEST
                            , 'Benzen' AS BENZEN
                            , 'Benzo(g,h,i)perylen' AS BENZO_GHI_PERYLEN
                            , 'Celkový dusík' AS CELKOVY_DUSIK
                            , 'Celkový fosfor' AS CELKOVY_FOSFOR
                            , 'Celkový organický uhlík (TOC) (jako celkové C nebo COD/3)' AS TOC
                            , 'Di-(2-ethyl hexyl) ftalát (DEHP)' AS DEHP
                            , 'Dichloromethan (DCM)' AS DCM
                            , 'Ethylbenzen' AS ETHYLBENZEN
                            , 'Fenoly (jako celkové C)' AS FENOLY
                            , 'Fluor a anorganické sloučeniny (jako HF)' AS HF
                            , 'Fluoranthen' AS FLUORANTHEN
                            , 'Fluorid sírový (SF6)' AS SF6
                            , 'Fluoridy (jako celkové F)' AS F
                            , 'Fluorované uhlovodíky (HFC)' AS HFC
                            , 'Formaldehyd' AS FORMALDEHYD
                            , 'Halogenované organické sloučeniny (jako AOX)' AS AOX
                            , 'Hexachlorbenzen (HCB)' AS HCB
                            , 'Hydrochlorofluorouhlovodíky (HCFC)' AS HCFC
                            , 'Chlor a anorganické sloučeniny (jako HCl)' AS HCL
                            , 'Chloridy (jako celkové Cl)' AS CL
                            , 'Chlorofluorouhlovodíky (CFC)' AS CFC
                            , 'Chrom a sloučeniny (jako Cr)' AS CR
                            , 'Kadmium a sloučeniny (jako Cd)' AS CD
                            , 'Kyanidy (jako celkové CN)' AS CN
                            , 'Kyanovodík (HCN)' AS HCN
                            , 'Měď a sloučeniny (jako Cu)' AS CU
                            , 'Methan (CH4)' AS CH4
                            , 'Naftalen' AS NAFTALEN
                            , 'Nemethanové těkavé organické sloučeniny (NMVOC)' AS NMVOC
                            , 'Nenalezeno' AS NENALEZENO
                            , 'Nikl a sloučeniny (jako Ni)' AS NI
                            , 'Olovo a sloučeniny (jako Pb)' AS PB
                            , 'Oxid dusný (N2O)' AS N2O
                            , 'Oxid uhelnatý (CO)' AS CO
                            , 'Oxid uhličitý (CO2)' AS CO2
                            , 'Oxid uhličitý (CO2) bez spalování biomasy' AS CO2_BEZ_SPALOVANI
                            , 'Oxidy dusíku (NOx/NO2)' AS NOX_NO2
                            , 'Oxidy síry (SOx/SO2)' AS SOX_SO2
                            , 'PCDD+PCDF (dioxiny+furany) (jako Teq)' AS PCDD_PCDF
                            , 'Per- a polyfluorované uhlovodíky (PFAS)' AS PFAS
                            , 'Perfluorouhlovodíky (PFC)' AS PFC
                            , 'Polétavý prach (PM10)' AS PM10
                            , 'Polycyklické aromatické uhlovodíky (PAH)' AS PAH
                            , 'Polychlorované bifenyly (PCB)' AS PCB
                            , 'Polychlorované naftaleny (PCN)' AS PCN
                            , 'Rtuť a sloučeniny (jako Hg)' AS HG
                            , 'Styren' AS STYREN
                            , 'Tetrachlorethylen (PER)' AS PER_TETRACHLORETHYLEN
                            , 'Tetrachlormethan (TCM)' AS TCM
                            , 'Toluen' AS TOLUEN
                            , 'Trichlorethylen' AS TRICHLORETHYLEN
                            , 'Trichlormethan' AS TRICHLORMETHAN
                            , 'Vinylchlorid' AS VINYLCHLORID
                            , 'Xyleny' AS XYLENY
                            , 'Zinek a sloučeniny (jako Zn)' AS ZN
                            , '1,2-dichlorethan (DCE)' AS DCE
        )
    )
)
/* ----------------------------------------------------------
   HLAVNÍ SELECT
   - Výběr a agregace pivotovaných dat
   - Výpočet součtového množství emisí CELKEM_MNOZSTVI
-----------------------------------------------------------*/
SELECT 
    ICP,
    PROVOZOVNA,
    UNIK,
    -- Souřadnice (zůstává jedna hodnota)
    MAX(JTSK_X_PROVOZOVNA) AS JTSK_X_PROVOZOVNA,
    MAX(JTSK_Y_PROVOZOVNA) AS JTSK_Y_PROVOZOVNA,
    MAX(WGS84_X_PROVOZOVNA) AS WGS84_X_PROVOZOVNA,
    MAX(WGS84_Y_PROVOZOVNA) AS WGS84_Y_PROVOZOVNA,
    -- Všechny pivotované sloupce
    MAX(AMONIAK_NH3) AS AMONIAK_NH3,
    MAX(ARSEN_SLOUCENINY) AS ARSEN_SLOUCENINY,
    MAX(AZBEST) AS AZBEST,
    MAX(BENZEN) AS BENZEN,
    MAX(BENZO_GHI_PERYLEN) AS BENZO_GHI_PERYLEN,
    MAX(CELKOVY_DUSIK) AS CELKOVY_DUSIK,
    MAX(CELKOVY_FOSFOR) AS CELKOVY_FOSFOR,
    MAX(TOC) AS TOC,
    MAX(DEHP) AS DEHP,
    MAX(DCM) AS DCM,
    MAX(ETHYLBENZEN) AS ETHYLBENZEN,
    MAX(FENOLY) AS FENOLY,
    MAX(HF) AS HF,
    MAX(FLUORANTHEN) AS FLUORANTHEN,
    MAX(SF6) AS SF6,
    MAX(F) AS F,
    MAX(HFC) AS HFC,
    MAX(FORMALDEHYD) AS FORMALDEHYD,
    MAX(AOX) AS AOX,
    MAX(HCB) AS HCB,
    MAX(HCFC) AS HCFC,
    MAX(HCL) AS HCL,
    MAX(CL) AS CL,
    MAX(CFC) AS CFC,
    MAX(CR) AS CR,
    MAX(CD) AS CD,
    MAX(CN) AS CN,
    MAX(HCN) AS HCN,
    MAX(CU) AS CU,
    MAX(CH4) AS CH4,
    MAX(NAFTALEN) AS NAFTALEN,
    MAX(NMVOC) AS NMVOC,
    MAX(NENALEZENO) AS NENALEZENO,
    MAX(NI) AS NI,
    MAX(PB) AS PB,
    MAX(N2O) AS N2O,
    MAX(CO) AS CO,
    MAX(CO2) AS CO2,
    MAX(CO2_BEZ_SPALOVANI) AS CO2_BEZ_SPALOVANI,
    MAX(NOX_NO2) AS NOX_NO2,
    MAX(SOX_SO2) AS SOX_SO2,
    MAX(PCDD_PCDF) AS PCDD_PCDF,
    MAX(PFAS) AS PFAS,
    MAX(PFC) AS PFC,
    MAX(PM10) AS PM10,
    MAX(PAH) AS PAH,
    MAX(PCB) AS PCB,
    MAX(PCN) AS PCN,
    MAX(HG) AS HG,
    MAX(STYREN) AS STYREN,
    MAX(PER_TETRACHLORETHYLEN) AS PER_TETRACHLORETHYLEN,
    MAX(TCM) AS TCM,
    MAX(TOLUEN) AS TOLUEN,
    MAX(TRICHLORETHYLEN) AS TRICHLORETHYLEN,
    MAX(TRICHLORMETHAN) AS TRICHLORMETHAN,
    MAX(VINYLCHLORID) AS VINYLCHLORID,
    MAX(XYLENY) AS XYLENY,
    MAX(ZN) AS ZN,
    MAX(DCE) AS DCE,
-- Výpočet celkového množství emisí přes všechny látky
    (   COALESCE(MAX(AMONIAK_NH3),0) +
        COALESCE(MAX(ARSEN_SLOUCENINY),0) +
        COALESCE(MAX(AZBEST),0) +
        COALESCE(MAX(BENZEN),0) +
        COALESCE(MAX(BENZO_GHI_PERYLEN),0) +
        COALESCE(MAX(CELKOVY_DUSIK),0) +
        COALESCE(MAX(CELKOVY_FOSFOR),0) +
        COALESCE(MAX(TOC),0) +
        COALESCE(MAX(DEHP),0) +
        COALESCE(MAX(DCM),0) +
        COALESCE(MAX(ETHYLBENZEN),0) +
        COALESCE(MAX(FENOLY),0) +
        COALESCE(MAX(HF),0) +
        COALESCE(MAX(FLUORANTHEN),0) +
        COALESCE(MAX(SF6),0) +
        COALESCE(MAX(F),0) +
        COALESCE(MAX(HFC),0) +
        COALESCE(MAX(FORMALDEHYD),0) +
        COALESCE(MAX(AOX),0) +
        COALESCE(MAX(HCB),0) +
        COALESCE(MAX(HCFC),0) +
        COALESCE(MAX(HCL),0) +
        COALESCE(MAX(CL),0) +
        COALESCE(MAX(CFC),0) +
        COALESCE(MAX(CR),0) +
        COALESCE(MAX(CD),0) +
        COALESCE(MAX(CN),0) +
        COALESCE(MAX(HCN),0) +
        COALESCE(MAX(CU),0) +
        COALESCE(MAX(CH4),0) +
        COALESCE(MAX(NAFTALEN),0) +
        COALESCE(MAX(NMVOC),0) +
        COALESCE(MAX(NENALEZENO),0) +
        COALESCE(MAX(NI),0) +
        COALESCE(MAX(PB),0) +
        COALESCE(MAX(N2O),0) +
        COALESCE(MAX(CO),0) +
        COALESCE(MAX(CO2),0) +
        COALESCE(MAX(CO2_BEZ_SPALOVANI),0) +
        COALESCE(MAX(NOX_NO2),0) +
        COALESCE(MAX(SOX_SO2),0) +
        COALESCE(MAX(PCDD_PCDF),0) +
        COALESCE(MAX(PFAS),0) +
        COALESCE(MAX(PFC),0) +
        COALESCE(MAX(PM10),0) +
        COALESCE(MAX(PAH),0) +
        COALESCE(MAX(PCB),0) +
        COALESCE(MAX(PCN),0) +
        COALESCE(MAX(HG),0) +
        COALESCE(MAX(STYREN),0) +
        COALESCE(MAX(PER_TETRACHLORETHYLEN),0) +
        COALESCE(MAX(TCM),0) +
        COALESCE(MAX(TOLUEN),0) +
        COALESCE(MAX(TRICHLORETHYLEN),0) +
        COALESCE(MAX(TRICHLORMETHAN),0) +
        COALESCE(MAX(VINYLCHLORID),0) +
        COALESCE(MAX(XYLENY),0) +
        COALESCE(MAX(ZN),0) +
        COALESCE(MAX(DCE),0)
    ) AS CELKEM_MNOZSTVI
FROM P
GROUP BY
    ICP,
    PROVOZOVNA,
    UNIK;