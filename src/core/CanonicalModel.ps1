<#
    .SYNOPSIS
    CANONICAL MODEL - A Árvore de Sintaxe Abstrata (AST) do Réplica.
    Fase 1: Soberania da Camada Core.
    
    .DESCRIPTION
    Representação neutra de formulários clínicos. 
    Invariante: Identificadores técnicos em UPPER_SNAKE_CASE.
    Invariante: SQL Variables (&<PAR_...>) preservadas como RAW.
#>

Class MvField {
    [int]$Id                # ID Real (Positivo) ou Temporário (Negativo)
    [string]$Identifier     # UPPER_SNAKE_CASE required
    [string]$Type           # V3 Name (ex: TEXT, BUTTON, DATE)
    [int]$TypeId            # V3 ID
    [hashtable]$Properties  # Mapeamento Semântico (ex: @{ editavel = $true })
    [hashtable]$Style       # Metadados Visuais (X, Y, W, H, Color)
    [string]$CreatedBy      # Metadado de Rastreabilidade (ex: Migrador®)

    MvField() {
        $this.Properties = @{}
        $this.Style = @{}
    }

    # Validação de Invariante: Identifier em UPPER_SNAKE_CASE
    [void] SetIdentifier([string]$name) {
        $this.Identifier = $name.ToUpper().Replace(" ", "_")
    }

    # Adiciona propriedade garantindo a Rosetta Stone
    [void] AddProperty([string]$key, $value) {
        $this.Properties[$key] = $value
    }
}

Class MvDocument {
    [int]$Id
    [string]$Name
    [string]$Identifier
    [int]$Version
    [string]$VersionStatus
    [bool]$Active
    [int]$Width
    [int]$Height
    [System.Collections.Generic.List[MvField]]$Fields

    MvDocument() {
        $this.Fields = [System.Collections.Generic.List[MvField]]::new()
        $this.Version = 1
        $this.VersionStatus = "DRAFT"
        $this.Active = $true
        $this.Width = 800
        $this.Height = 1100
    }

    [void] AddField([MvField]$field) {
        $this.Fields.Add($field)
    }
}

Class MvCanonicalModel {
    # Fábrica de Objetos AST
    static [MvDocument] CreateNewDocument([string]$name, [string]$id) {
        $doc = [MvDocument]::new()
        $doc.Name = $name
        $doc.Identifier = $id.ToUpper().Replace(" ", "_")
        return $doc
    }
}
