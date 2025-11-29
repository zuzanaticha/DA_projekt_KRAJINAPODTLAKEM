import requests                                         # přivolání knihovny Requests – umí posílat požadavky na web podobně jako prohlížeč
from bs4 import BeautifulSoup                           # přivolání knihovny BeautifulSoup – umí rozebrat HTML do objektu, ve kterém se dá dál hledat
import csv                                              # načte knihovnu pro práci s CSV soubory
import time                                             # knihovna pro práci s časem – umožní vložit pauzu mezi požadavky

session = requests.Session()                            # vytvoří trvalé spojení, které si pamatuje nastavení a sdílí je mezi požadavky
session.headers.update({                                # nastaví hlavičky, které se budou posílat při každém dotazu
    "User-Agent": "Mozilla/5.0",                        # identifikace jako běžný prohlížeč
    "Referer": "https://drusop.nature.cz/"              # informace o tom, odkud dotaz přichází
})

BASE = "https://drusop.nature.cz"                       # základ URL, který se nemění
DETAIL_URL = BASE + "/ost/chrobjekty/pstromy/brow.php"  # adresa stránky, která zobrazuje detail jednoho stromu

# ------------------------------------------------------------
# Funkce pro stažení detailu jednoho stromu podle jeho ID
# ------------------------------------------------------------

def load_detail(tree_id, retries=5):
    params = {"SHOW_ONE": 1, "ID": tree_id}                             # parametry, které přepnou stránku do režimu zobrazení jednoho detailu

    for attempt in range(retries):                                      # pokusí se stránku stáhnout několikrát, kdyby došlo k výpadku
        try:
            r = session.get(DETAIL_URL, params=params, timeout=15)      # odešle požadavek na server
            r.raise_for_status()                                        # pokud přijde HTTP chyba, vyvolá se výjimka
            return BeautifulSoup(r.text, "html.parser")                 # úspěšná odpověď se převede na HTML objekt

        except Exception as e:
            print(f"   Chyba při ID {tree_id}, pokus {attempt+1}/{retries}: {e}")
            time.sleep(2)                                               # krátká pauza před dalším pokusem

    print(f"!!! POZOR: ID {tree_id} selhalo po {retries} pokusech.")    # ani jeden pokus nebyl úspěšný
    return None                                                         # vrátí None jako signál, že detail nebylo možné získat

# ------------------------------------------------------------
# Funkce pro stažení sekce taxonů z detailu
# ------------------------------------------------------------

def parse_taxa(soup):
    if soup is None:                                                    # když se detail nepodařilo stáhnout, vrátí prázdné seznamy
        return [], [], []

    taxon_cz = []                                                       # seznam českých názvů
    taxon_lat = []                                                      # seznam latinských názvů
    taxon_cnt = []                                                      # seznam počtů jedinců

    form = soup.find("form", attrs={"name": "frm_strom_druhy"})         # najde formulář, který obsahuje tabulku s druhy
    if not form:
        return taxon_cz, taxon_lat, taxon_cnt

    table = form.find("table", class_="table-body")                     # najde tabulku s daty o taxonech
    if not table:
        return taxon_cz, taxon_lat, taxon_cnt

    tbody = table.find("tbody") or table                                # tabulka může mít nebo nemusí mít <tbody> – tím se ošetří obě varianty

    for tr in tbody.find_all("tr"):                                     # projde všechny řádky tabulky
        tds = tr.find_all("td")
        if len(tds) < 3:                                                # řádky s méně než 3 sloupci se přeskočí
            continue

        cz = tds[0].get_text(strip=True)                                # český název druhu
        lat = tds[1].get_text(strip=True)                               # latinský název
        cnt_raw = tds[2].get_text(strip=True)                           # počet v textové podobě

        if not cz and not lat:                                          # prázdné řádky se ignorují
            continue

        try:
            cnt = int(cnt_raw)                                          # převede hodnotu na číslo
        except:
            cnt = 0                                                     # pokud převod selže, doplní se 0

        taxon_cz.append(cz)
        taxon_lat.append(lat)
        taxon_cnt.append(cnt)

    return taxon_cz, taxon_lat, taxon_cnt                               # vrátí všechna data o druzích z detailu

# ------------------------------------------------------------
# Hlavní funkce – projde všechna ID z prvního CSV a ke každému stáhne detaily
# ------------------------------------------------------------

def main():
    input_file = "stromy_kod_id_nazev_pocet.csv"                        # soubor vytvořený prvním scraperem
    output_file = "stromy_taxony_FULL.csv"                              # nový soubor s kompletními detaily

    with open(input_file, encoding="utf-8") as f:
        rows = list(csv.DictReader(f))                                  # načte celý CSV jako seznam slovníků

    output_rows = []
    total = len(rows)                                                   # celkový počet záznamů pro informativní výpis

    for i, row in enumerate(rows, 1):                                   # projde všechny řádky, čísluje od 1 pro přehledné logování

        kod = row["kod"]
        tree_id = row["id"]
        nazev = row["nazev"]

        try:
            pocet_skutecny = int(row["pocet_skutecny"])
        except:
            pocet_skutecny = None                                       # prázdné nebo nečíselné hodnoty se převedou na None

        print(f"[{i}/{total}] ID {tree_id}: stahuji…")                  # informativní výpis, co se zrovna zpracovává

        soup = load_detail(tree_id)                                     # stáhne detail daného stromu

        taxon_cz_list, taxon_lat_list, taxon_cnt_list = parse_taxa(soup)   # najde druhy stromů v detailu

        taxon_cnt_sum = sum(taxon_cnt_list)                             # sečte všechny počty jedinců z detailu

        if pocet_skutecny is None:                                      # pokud původní přehled neměl počet
            taxon_confirmed = None                                      # nedává smysl provádět porovnání
        else:
            taxon_confirmed = (taxon_cnt_sum == pocet_skutecny)         # True / False podle shody
        
        warnings = []                                                   # seznam upozornění pro konkrétní záznam
        if len(taxon_cz_list) > 1:                                      # pokud má strom více druhů, vzniká upozornění
            warnings.append("MULTIPLE_TAXON")
        if pocet_skutecny is not None and taxon_cnt_sum != pocet_skutecny:
            warnings.append("COUNT_MISMATCH")                           # upozornění na rozdíl mezi součtem a deklarovaným počtem

        taxon_warning = "OK" if not warnings else "+".join(warnings)

        output_rows.append({
            "kod": kod,
            "id": tree_id,
            "nazev": nazev,
            "taxon_cz": "; ".join(taxon_cz_list),
            "taxon_lat": "; ".join(taxon_lat_list),
            "taxon_cnt": "; ".join(str(n) for n in taxon_cnt_list),
            "taxon_cnt_sum": taxon_cnt_sum,
            "pocet_skutecny": pocet_skutecny,
            "taxon_confirmed": taxon_confirmed,
            "taxon_warning": taxon_warning
        })

        time.sleep(0.5)                                                 # pauza mezi dotazy kvůli šetrnosti vůči serveru

    with open(output_file, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=output_rows[0].keys())
        w.writeheader()                                                 # první řádek CSV
        w.writerows(output_rows)                                        # zapíše všechny řádky

    print("\nHotovo. Výsledky uložené do:", output_file)

if __name__ == "__main__":                                              # zajistí, že se main() spustí jen při přímém spuštění souboru
    main()