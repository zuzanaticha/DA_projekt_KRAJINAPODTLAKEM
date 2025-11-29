import requests                                         # přivolání knihovny Requests - umí posílat požadavky na webové stránky, podobně jako to dělá prohlížeč 
from bs4 import BeautifulSoup                           # přivolání knihovny BeautifulSoup - umí rozebrat HTML stránku do objektu, ve kterém se pak dá snadno hledat (najít tabulku, buňku, odkaz…)
import csv                                              # načte vestavěnou knihovnu pro práci se CSV soubory - umožní zapsat slovníky jako řádky v CSV

session = requests.Session()                            # vytvoří trvalé spojení (session), které si pamatuje nastavení a používá se pro všechny další dotazy
session.headers.update({                                # nastaví, co má tenhle prohlížeč říkat serveru při každém dotazu - do seznamu informací, které posílám serveru, přidej tohle:
    "User-Agent": "Mozilla/5.0",                                                    # serveru se představí jako běžný prohlížeč
    "Referer": "https://drusop.nature.cz/ost/chrobjekty/pstromy/index.php"          # serveru řekne, že přichází z téhle stránky
})

BASE = "https://drusop.nature.cz"                       # část URL, která se nemění - rozděluju pro přehlednost
URL = BASE + "/ost/chrobjekty/pstromy/brow.php"         # F12 -> Síť -> Fetch/XHR / Dok -> Náhled -> tabulka s tím, co chci scrapovat

def get_page(offset):                                   # definice funkce get_page
    params = {"pageposxstrom": offset}                  # do URL přibalí parametr pageposxstrom, který server používá jako „posun“ v tabulce
    r = session.get(URL, params=params)                 # pošle GET požadavek na danou stránku s parametry
    r.raise_for_status()                                # pokud přišlo chybové HTTP (4xx/5xx), vyhodí výjimku a nepokračuje v kódu
    return BeautifulSoup(r.text, "html.parser")         # HTML odpověď převede do objektu BeautifulSoup – dál může snadno hledat elementy

def parse_rows(soup):
    table = soup.find("table", class_="table-body")     # najde tabulku s daty podle CSS třídy; když tam není, nic nevrátí
    if not table:
        return

    for tr in table.find_all("tr"):                     # projde všechny řádky tabulky
        tds = tr.find_all("td")                         # v každém řádku najde všechny buňky
        if len(tds) < 7:                                # když řádek nemá potřebný počet sloupců, přeskočí ho
            continue

        kod = tds[2].get_text(strip=True)               # třetí sloupec obsahuje kód; get_text vyčistí HTML a strip=True odstraní mezery kolem

        a = tds[1].find("a", href=True)                 # ve druhém sloupci hledá odkaz – v něm je ID stromu
        if not a:
            continue
        href = a["href"]                                # vytáhne URL z atributu href
        if "ID=" not in href:                           # kontrola, že URL obsahuje parametr ID
            continue
        tree_id = href.split("ID=")[1]                  # z URL vyřízne hodnotu ID za "ID="

        nazev = tds[3].get_text(strip=True)             # čtvrtý sloupec obsahuje název stromu

        pocet_skutecny = tds[6].get_text(strip=True)    # sedmý sloupec obsahuje skutečný počet
        if pocet_skutecny == "":
            pocet_skutecny = None                       # pokud je buňka prázdná, chci mít hodnotu None, aby se s ní lépe pracovalo

        yield {                                         # vrací slovník pro každý řádek; yield → generátor, takže nevyrábí velký seznam najednou
            "kod": kod,
            "id": tree_id,
            "nazev": nazev,
            "pocet_skutecny": pocet_skutecny
        }

def main():
    all_rows = []                                       # sem se budou ukládat všechny získané řádky z jednotlivých stránek

    for offset in range(0, 5500, 25):                   # stránka zobrazuje 25 řádků; offset posouvá stránkování (0, 25, 50…)
        soup = get_page(offset)                         # stáhne jednu stránku tabulky
        for row in parse_rows(soup):                    # projde jednotlivé záznamy z té stránky
            all_rows.append(row)                        # a přidá je do seznamu
        print("Hotovo offset:", offset)                 # průběžný výpis - kde scraper zrovna je

    with open("stromy_kod_id_nazev_pocet.csv", "w", newline="", encoding="utf-8") as f:         # otevře nový CSV soubor pro zápis
        w = csv.DictWriter(f, fieldnames=["kod", "id", "nazev", "pocet_skutecny"])              # nastaví writer, který umí psát slovníky
        w.writeheader()                                                                         # první řádek: názvy sloupců
        w.writerows(all_rows)                                                                   # zapíše všechny řádky, jeden po druhém

    print("Uloženo:", len(all_rows), "záznamů.")        # informativní výpis: kolik položek se podařilo stáhnout a uložit


if __name__ == "__main__":                              # kontrola, že skript běží přímo, ne jako import z jiného souboru
    main()                                              # pokud ano, spustí hlavní funkci