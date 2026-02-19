# Estrutura do Projeto & Algoritmos (PROTOCOL_MV_NATIVE)

## 1. Árvore de Diretórios
A estrutura separa estritamente o "O Que" (Core) do "Como" (Drivers).

```text
J:\replica_lab\
├── src\
│   ├── Core\          
│   │   ├── CanonicalModel.ps1  # Armazena IDs e Valores (Agnóstico)
│   │   └── RosettaStone.ps1    # Tabela de Lookup (IDs <-> Conceitos)
│   │   
│   ├── Drivers\       
│   │   ├── DriverV2.ps1        # Exporta para XML (Oracle Tags)
│   │   └── DriverV3.ps1        # Exporta para JSON (Protocol Native)
│   │   
│   └── Loaders\       
│       └── LoaderV3.ps1        # Importa JSON para Core
│
├── docs\              # Documentação da Engenharia Reversa
│   └── mv_types_manifest.md
│
└── tests\             # Testes de Fidelidade
    └── test_structural.ps1
```

## 2. Pseudocódigo: SerializeLayout ("Inception")

O layout visual no Editor 3 é armazenado como uma String JSON dentro de uma propriedade JSON.

```pseudocode
FUNCTION SerializeLayout(LayoutMap):
    // Entrada: Map<FieldID, {x, y, w, h}>
    // Saída: String (escaped JSON)

    Let layoutObject = NewOrderedMap()

    FOR EACH fieldId IN LayoutMap:
        Let coords = LayoutMap[fieldId]
        layoutObject[fieldId] = {
            "x": coords.x,
            "y": coords.y,
            "w": coords.w,
            "h": coords.h
        }
    END FOR

    // PASSO CRÍTICO: Serializar para String Minimalista
    // Não retornar o objeto! Retornar a string representativa.
    Let jsonString = ConvertToJson(layoutObject, Compress=True)

    RETURN jsonString
END FUNCTION
```

**Exemplo de Saída Válida**:
`"{\"TXT_NOME\":{\"x\":10,\"y\":20,\"w\":100,\"h\":30}}"`

## 3. Pseudocódigo: Hash Híbrido

```pseudocode
FUNCTION CalculateHash(Value):
    IF Value IS Boolean:
        IF Value == True: RETURN "b326b5062b2f0e69046810717534cb09"
        IF Value == False: RETURN "68934a3e9455fa72420237eb05902327"
    
    // Para outros tipos, MD5 do valor string
    Let strVal = ToString(Value)
    RETURN MD5(strVal)
END FUNCTION
```
