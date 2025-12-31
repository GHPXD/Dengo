"""
CITIES SERVICE - GESTÃO DE MUNICÍPIOS (VERSÃO LIMPA)
"""
import json
from pathlib import Path
from typing import Dict, List, Optional
import unicodedata
from app.core.logger import logger

def normalize_text(text: str) -> str:
    if not isinstance(text, str): return str(text)
    nfkd = unicodedata.normalize('NFD', text)
    return ''.join([c for c in nfkd if not unicodedata.combining(c)]).lower().strip()

class CitiesService:
    def __init__(self):
        self.cities_data: List[Dict] = []
        self.cities_by_ibge: Dict[str, Dict] = {}
        self._load_cities_data()

    def _load_cities_data(self):
        # Caminho do arquivo
        cities_file = Path(__file__).parent.parent.parent / "data" / "cidades_parana.json"

        if cities_file.exists():
            try:
                with open(cities_file, "r", encoding="utf-8") as f:
                    self.cities_data = json.load(f)
                
                # Indexa para busca rápida
                for city in self.cities_data:
                    # Garante que ID seja string (igual ao seu JSON)
                    str_id = str(city["ibge_codigo"])
                    city["ibge_codigo"] = str_id
                    self.cities_by_ibge[str_id] = city
                
                logger.success(f"✅ {len(self.cities_data)} cidades do PR carregadas.")
            except Exception as e:
                logger.error(f"❌ Erro crítico ao ler JSON: {e}")
                self.cities_data = [] # Lista vazia em caso de erro de leitura
        else:
            logger.error(f"❌ ARQUIVO NÃO ENCONTRADO: {cities_file}")
            # Sem fallback, a lista fica vazia e o app pode dar 404 em buscas
            self.cities_data = []

    # ... (Mantenha os métodos de busca search_cities, get_city_by_ibge, etc.)
    def search_cities(self, query: str, limit: int = 10, uf: Optional[str] = None) -> List[Dict]:
        if not query or len(query) < 2: return self.cities_data[:limit]
        q_norm = normalize_text(query)
        matches = []
        for city in self.cities_data:
            if uf and city["uf"].upper() != uf.upper(): continue
            name_norm = normalize_text(city["nome"])
            if name_norm == q_norm: matches.append((city, 3))
            elif name_norm.startswith(q_norm): matches.append((city, 2))
            elif q_norm in name_norm: matches.append((city, 1))
        matches.sort(key=lambda x: (x[1], x[0].get("populacao", 0)), reverse=True)
        return [m[0] for m in matches[:limit]]

    def get_city_by_ibge(self, ibge_code: str) -> Optional[Dict]:
        return self.cities_by_ibge.get(str(ibge_code))
        
    def get_cities_by_uf(self, uf: str) -> List[Dict]:
        return [c for c in self.cities_data if c["uf"].upper() == uf.upper()]

cities_service = CitiesService()