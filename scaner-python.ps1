# scanner_menu.ps1

function Show-Menu {
    Clear-Host
    Write-Host "=== SCANNER WEB - MENU ==="
    Write-Host "1. Inserir URL e escanear"
    Write-Host "2. Sair"
    Write-Host "==========================="
}

function Run-Scanner {
    param (
        [string]$url,
        [int]$depth = 2
    )

    $pythonCode = @"
import requests
from bs4 import BeautifulSoup
import re
import csv
import os
from urllib.parse import urljoin

visited = set()
results = {
    'links': set(),
    'emails': set(),
    'phones': set(),
    'ips': set(),
    'keywords': set(),
    'domains': set()
}

KEYWORDS = ['admin', 'senha', 'login', 'root', 'auth']
email_pattern = re.compile(r'[\w\.-]+@[\w\.-]+\.\w+')
phone_pattern = re.compile(r'\+?\d[\d\s\-\(\)]{7,}\d')
ip_pattern = re.compile(r'\b(?:\d{1,3}\.){3}\d{1,3}\b')
domain_pattern = re.compile(r'(?<=://)([^/]+)')

def extract_data(html, base_url):
    soup = BeautifulSoup(html, 'html.parser')
    text = soup.get_text()
    results['emails'].update(email_pattern.findall(html))
    results['phones'].update(phone_pattern.findall(html))
    results['ips'].update(ip_pattern.findall(html))
    results['keywords'].update([kw for kw in KEYWORDS if kw.lower() in text.lower()])
    results['domains'].update(domain_pattern.findall(base_url))
    for a_tag in soup.find_all('a', href=True):
        href = a_tag['href']
        full_url = urljoin(base_url, href)
        if full_url.startswith('http'):
            results['links'].add(full_url)

def scrape(url, depth=0, max_depth=$depth):
    if depth > max_depth or url in visited:
        return
    visited.add(url)
    print(f"[+] Scanning: {url}")
    try:
        headers = {'User-Agent': 'Mozilla/5.0 (compatible; EthicalScanner/1.0)'}
        response = requests.get(url, headers=headers, timeout=5)
        if response.status_code == 200:
            extract_data(response.text, url)
            links_to_follow = list(results['links'] - visited)
            for link in links_to_follow:
                if link not in visited:
                    scrape(link, depth + 1, max_depth)
    except Exception as e:
        print(f"[!] Error on {url}: {e}")

def save_to_csv(filename='scan_results.csv'):
    with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile)
        for key, values in results.items():
            writer.writerow([key.upper()])
            for item in values:
                writer.writerow([item])
            writer.writerow([])

if __name__ == '__main__':
    scrape("$url", 0, $depth)
    save_to_csv()
    print("\n[✓] Resultados salvos em scan_results.csv")
"@

    $tempFile = "$env:TEMP\scanner_temp.py"
    $pythonCode | Out-File -Encoding UTF8 -FilePath $tempFile
    try {
        python $tempFile
    } catch {
        Write-Host "Erro ao executar o script Python"
    } finally {
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    }
}

# Loop infinito com menu
while ($true) {
    Show-Menu
    $choice = Read-Host "Escolha uma opção (1 ou 2)"
    
    switch ($choice) {
        '1' {
            $url = Read-Host "Insira o link pai (ex: https://example.com)"
            if ($url -notmatch '^https?://') {
                Write-Host "❌ URL inválida. Deve começar com http:// ou https://"
                Pause
                continue
            }
            $depthInput = Read-Host "Profundidade do scan (padrão 2)"
            if ($depthInput -match '^\d+$') {
                $depth = [int]$depthInput
            } else {
                $depth = 2
            }
            Run-Scanner -url $url -depth $depth
            Pause
        }
        '2' {
            Write-Host "Saindo..."
            break
        }
        default {
            Write-Host "❌ Opção inválida. Escolha 1 ou 2."
            Pause
        }
    }
    if ($choice -eq '2') {
        break
    }
}