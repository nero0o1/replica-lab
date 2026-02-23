import re
from typing import Any, List, Dict, Optional
from core.tabela_hashes import obter_lacre

class TradutorRoseta:
    """
    Onda 2 & 3: Pedra de Roseta.
    Motor de conversão, normalização e segurança de metadados legados.
    Responsável por garantir a integridade de tipos (Casting) e os lacres (Hashes MD5).
    """

    @staticmethod
    def traduzir_propriedade(p_id: int, p_val: str) -> Dict[str, Any]:
        """
        Realiza a tradução de IDs numéricos para chaves semânticas com tipagem estrita
        e lacre de integridade (Hash MD5).
        
        Args:
            p_id: ID numérico da propriedade legado.
            p_val: Valor original em formato texto.
            
        Returns:
            Dicionário com a chave traduzida e o valor/hash encapsulados.
        """
        # Limpeza básica do valor de entrada
        val_clean = str(p_val).strip() if p_val is not None else ""

        if p_id == 8:
             # Suporte ao ID 8 (Obrigatorio) para os testes
             val_bool = val_clean.lower() == "true"
             return {"obrigatorio": TradutorRoseta._encapsular(val_bool)}

        if p_id == 15:
            # REGRA DE NÚMERO (ID 15) -> tamanho (Exige Integer)
            try:
                val_int = int(val_clean)
                return {"tamanho": TradutorRoseta._encapsular(val_int)}
            except (ValueError, TypeError):
                return {"tamanho": TradutorRoseta._encapsular(0)}

        elif p_id == 17:
             # Suporte ao ID 17 (Reprocessar)
             val_bool = val_clean.lower() == "true"
             return {"reprocessar": TradutorRoseta._encapsular(val_bool)}

        elif p_id == 21:
            # REGRA DE TEXTO (ID 21) -> acaoSql (String padrão)
            return {"acaoSql": TradutorRoseta._encapsular(val_clean)}

        elif p_id == 25:
            # REGRA DE LISTA/ARRAY (ID 25) -> listaValores (Array de Objetos)
            lista = TradutorRoseta._quebrar_lista(val_clean)
            return {"listaValores": TradutorRoseta._encapsular(lista)}

        return {}

    @staticmethod
    def _encapsular(valor: Any) -> Dict[str, Any]:
        """Agrupa o valor e seu lacre de segurança no mesmo nó."""
        return {
            "value": valor,
            "hash": obter_lacre(valor)
        }

    @staticmethod
    def _quebrar_lista(texto: str) -> List[Dict[str, str]]:
        """
        A Máquina de Quebrar Texto (ID 25).
        Transforma strings delimitadas por '|' ou ';' em uma lista de objetos estruturados.
        
        Exemplo: "S|N" -> [{"value": "S"}, {"value": "N"}]
        Exemplo: "1|Ativo;2|Inativo" -> [{"value": "1"}, {"value": "Ativo"}, ...]
        """
        if not texto:
            return []

        # Aplica o split por múltiplos delimitadores (Pipe ou Ponto-e-Vírgula)
        # O uso de Regex garante que tratamos ambos os padrões legados simultaneamente
        fragments = re.split(r'[|;]', texto)
        
        # Limpeza de fragmentos vazios e construção dos dicionários de valor
        # O formato {"value": "xxx"} é o padrão exigido pelo motor do novo editor
        return [{"value": f.strip()} for f in fragments if f.strip()]

# Teste preliminar de sanidade (interno)
if __name__ == "__main__":
    t = TradutorRoseta()
    print("Teste ID 15 (Num):", t.traduzir_propriedade(15, "250"))
    print("Teste ID 21 (Txt):", t.traduzir_propriedade(21, "SELECT * FROM DUAL"))
    print("Teste ID 25 (List):", t.traduzir_propriedade(25, "S|N"))
    print("Teste ID 25 (Complex):", t.traduzir_propriedade(25, "1|Sim;0|Não"))
