# PEGASUS hacker Windows
# ARQUIVOS DESKRIPTOGRAFADOS

param (
    [string]$relatorioPath = "$env:USERPROFILE\Documents\relatorio_simples.html",
    [string]$caminhoDocumentos = "$env:USERPROFILE\Documents",
    [string]$caminhoImagens = "$env:USERPROFILE\Pictures",
    [string]$caminhoMusica = "$env:USERPROFILE\Music",
    [string]$caminhoVideos = "$env:USERPROFILE\Videos",
    [string]$caminhoTransferencias = "$env:USERPROFILE\Downloads",
    [string]$caminhoAreaTrabalho = "$env:USERPROFILE\Desktop",
    [string]$caminhoUsers = "C:\Users",
    [string]$caminhoDiscoC = "C:\",
    [int]$maxNivelUsers = 2,
    [int]$maxNivelDiscoC = 1,
    [switch]$descriptografarArquivos,
    [switch]$help
)

if ($help) {
    Write-Host "Uso: .\relatorio_sistema.ps1 [-relatorioPath <caminho>] [-descriptografarArquivos] [-help]"
    Write-Host "Parâmetros:"
    Write-Host "  -relatorioPath <caminho>: Especifica o caminho do relatório HTML."
    Write-Host "  -descriptografarArquivos: Descriptografa arquivos criptografados."
    exit
}

function ListarConteudoPastaHTML {
    param(
        [string]$titulo,
        [string]$caminho,
        [int]$nivel = 0,
        [int]$maxNivel = 3
    )

    $html = "<h2>$titulo</h2>"

    if (-not (Test-Path $caminho)) {
        $html += "<p style='color:red;'>Pasta não encontrada ou inacessível: $caminho</p>"
        return $html
    }

    $html += "<table border='1' cellpadding='4' cellspacing='0' style='border-collapse:collapse;width:100%;font-family:Arial,sans-serif;'>"
    $html += "<tr style='background:#3498db;color:#fff;'><th>Nome</th><th>Tipo</th><th>Tamanho</th><th>Última Modificação</th></tr>"

    try {
        $itens = Get-ChildItem -Path $caminho -Force -ErrorAction Stop
    }
    catch {
        $html += "<tr><td colspan='4' style='color:red;'>Erro ao acessar: $_</td></tr>"
        $html += "</table>"
        return $html
    }

    foreach ($item in $itens) {
        $indent = "&nbsp;" * ($nivel * 4)
        $nomeOriginal = [System.Web.HttpUtility]::HtmlEncode($item.Name)
        $pathEncoded = "file:///" + ($item.FullName -replace '\\','/')
        $link = "<a href='$pathEncoded' target='_blank'>$nomeOriginal</a>"

        $tipo = if ($item.PSIsContainer) { "Pasta" } else { "Arquivo" }
        $tamanho = if (-not $item.PSIsContainer) { "{0:N2} KB" -f ($item.Length / 1KB) } else { "-" }
        $modificado = $item.LastWriteTime.ToString("dd/MM/yyyy HH:mm:ss")

        $html += "<tr><td>$indent$link</td><td>$tipo</td><td style='text-align:right;'>$tamanho</td><td>$modificado</td></tr>"

        if ($descriptografarArquivos -and -not $item.PSIsContainer -and ($item.Attributes -band [System.IO.FileAttributes]::Encrypted)) {
            try {
                $output = cipher /d "$($item.FullName)" 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $html += "<tr><td colspan='4' style='color:green;'>✔ Arquivo descriptografado: $($item.Name)</td></tr>"
                } else {
                    $html += "<tr><td colspan='4' style='color:red;'>❌ Falha ao descriptografar: $($item.Name) - $output</td></tr>"
                }
            }
            catch {
                $html += "<tr><td colspan='4' style='color:red;'>❌ Falha ao descriptografar: $($item.Name) - $_</td></tr>"
            }
        }

        if ($item.PSIsContainer -and $nivel -lt $maxNivel) {
            $html += ListarConteudoPastaHTML -titulo "" -caminho $item.FullName -nivel ($nivel + 1) -maxNivel $maxNivel
        }
    }

    $html += "</table>"
    return $html
}

$so = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor

$html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset='UTF-8'>
    <title>Relatório Simples do Sistema</title>
    <style>
        body { font-family: Arial, sans-serif; padding: 20px; background:#f9f9f9; color:#333; }
        h1, h2 { color: #2c3e50; }
        table { background:#fff; margin-bottom:20px; font-size:14px; }
        th, td { padding:8px; border:1px solid #ccc; vertical-align: top; }
        th { background-color:#3498db; color:#fff; }
        tr:nth-child(even) { background-color:#f2f2f2; }
        a { text-decoration: none; color: #2980b9; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <h1>Relatório Simples do Sistema</h1>
    <p>Gerado em $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')</p>

    <h2>Informações do Sistema</h2>
    <table>
        <tr><th>Sistema Operacional</th><td>$($so.Caption) - $($so.OSArchitecture)</td></tr>
        <tr><th>Usuário Logado</th><td>$($env:USERNAME)</td></tr>
        <tr><th>Nome do Computador</th><td>$($env:COMPUTERNAME)</td></tr>
        <tr><th>Processador</th><td>$($cpu.Name) - $($cpu.NumberOfCores) núcleos</td></tr>
    </table>
"@

$html += ListarConteudoPastaHTML -titulo " Documentos" -caminho $caminhoDocumentos
$html += ListarConteudoPastaHTML -titulo " Imagens" -caminho $caminhoImagens
$html += ListarConteudoPastaHTML -titulo " Música" -caminho $caminhoMusica
$html += ListarConteudoPastaHTML -titulo " Vídeos" -caminho $caminhoVideos
$html += ListarConteudoPastaHTML -titulo " Transferências" -caminho $caminhoTransferencias
$html += ListarConteudoPastaHTML -titulo " Área de Trabalho" -caminho $caminhoAreaTrabalho
$html += ListarConteudoPastaHTML -titulo " Pasta Users (nível $maxNivelUsers)" -caminho $caminhoUsers -maxNivel $maxNivelUsers
$html += ListarConteudoPastaHTML -titulo " Disco C:\ (nível $maxNivelDiscoC)" -caminho $caminhoDiscoC -maxNivel $maxNivelDiscoC

$html += "</body></html>"

try {
    $html | Out-File -FilePath $relatorioPath -Encoding UTF8
    Write-Host "✅ Relatório gerado com sucesso!"
    Write-Host "📄 Caminho: $relatorioPath"
    Start-Process $relatorioPath
}
catch {
    Write-Host "❌ Erro ao salvar o relatório: $_"
}