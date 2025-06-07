#CRAQUEAR IP ROTEADOR
#EXEMPLO # banco espanha ip# Pesquisa


while ($true) {
    Write-Host "Menu de Opções:"
    Write-Host "1 - Pesquisar roteadores de login premiáveis"
    Write-Host "2 - Pesquisar roteadores e IPs"
    Write-Host "3 - Pesquisar empresas universais"
    Write-Host "4 - Sair"

    $choice = Read-Host "Digite o número da opção desejada"

    switch ($choice) {
        1 {
            $country = Read-Host "Digite o país para filtrar a pesquisa"
            $query = "roteadores+de+login+premiáveis+$country"
            $url = "https://www.google.com/search?q=$query"
            Start-Process -FilePath $url
        }
        2 {
            $country = Read-Host "Digite o país para filtrar a pesquisa"
            $query = "roteadores+IPs+$country"
            $url = "https://www.google.com/search?q=$query"
            Start-Process -FilePath $url
        }
        3 {
            $query = "empresas+universais"
            $url = "https://www.google.com/search?q=$query"
            Start-Process -FilePath $url
        }
        4 {
            Write-Host "Saindo..."
            exit
        }
        Default {
            Write-Host "Opção inválida. Tente novamente."
        }
    }
}