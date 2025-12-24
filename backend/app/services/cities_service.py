"""
════════════════════════════════════════════════════════════════════════════
CITIES SERVICE - GESTÃO DE MUNICÍPIOS BRASILEIROS
════════════════════════════════════════════════════════════════════════════

Gerencia base de dados de 5.570 municípios brasileiros com dados do IBGE.

Features:
    - Busca por nome (autocomplete)
    - Busca por UF
    - Busca por código IBGE
    - Coordenadas geográficas (lat/lon)
    - População estimada
    - Região (Norte, Nordeste, Sul, Sudeste, Centro-Oeste)

Fonte de Dados:
    API IBGE: https://servicodados.ibge.gov.br/api/v1/localidades/municipios

Autor: Dengo Team
Data: 2025-12-23
════════════════════════════════════════════════════════════════════════════
"""

import json
from pathlib import Path
from typing import Dict, List, Optional
import unicodedata

from app.core.logger import logger


def normalize_text(text: str) -> str:
    """
    Normaliza texto removendo acentos para busca insensível.
    
    Examples:
        >>> normalize_text("São Paulo")
        'sao paulo'
        >>> normalize_text("Maringá")
        'maringa'
    """
    # Remove acentos usando NFD (Normalization Form Decomposed)
    nfkd = unicodedata.normalize('NFD', text)
    text_without_accents = ''.join([c for c in nfkd if not unicodedata.combining(c)])
    return text_without_accents.lower().strip()


class CitiesService:
    """
    Serviço para buscar municípios brasileiros.
    
    Usa JSON local com 5.570 municípios para performance.
    Alternativa: PostgreSQL para produção com índices full-text.
    """

    def __init__(self):
        """Inicializa o serviço e carrega dados das cidades."""
        self.cities_data: List[Dict] = []
        self.cities_by_ibge: Dict[str, Dict] = {}
        self._load_cities_data()

    def _load_cities_data(self):
        """
        Carrega dados das cidades do arquivo JSON.
        
        Fase atual: Paraná (399 municípios)
        Se arquivo não existe, usa apenas capitais como fallback.
        """
        cities_file = Path(__file__).parent.parent.parent / "data" / "cidades_parana.json"

        if cities_file.exists():
            try:
                with open(cities_file, "r", encoding="utf-8") as f:
                    self.cities_data = json.load(f)
                    
                # Cria índice por código IBGE para busca rápida O(1)
                self.cities_by_ibge = {
                    city["ibge_codigo"]: city for city in self.cities_data
                }
                
                logger.success(
                    f"OK - Cidades carregadas: {len(self.cities_data)} municipios"
                )
            except Exception as e:
                logger.error(f"ERRO - Erro ao carregar cidades: {e}")
                self._load_fallback_cities()
        else:
            logger.warning(
                f"AVISO - Arquivo {cities_file} nao encontrado. Usando apenas capitais."
            )
            self._load_fallback_cities()

    def _load_fallback_cities(self):
        """
        Carrega apenas capitais brasileiras como fallback.
        
        Usado quando arquivo JSON completo não está disponível.
        """
        self.cities_data = [
            {
                "ibge_codigo": "3550308",
                "nome": "São Paulo",
                "uf": "SP",
                "regiao": "Sudeste",
                "populacao": 12252023,
                "latitude": -23.5505,
                "longitude": -46.6333,
                "capital": True,
            },
            {
                "ibge_codigo": "3304557",
                "nome": "Rio de Janeiro",
                "uf": "RJ",
                "regiao": "Sudeste",
                "populacao": 6747815,
                "latitude": -22.9068,
                "longitude": -43.1729,
                "capital": True,
            },
            {
                "ibge_codigo": "3106200",
                "nome": "Belo Horizonte",
                "uf": "MG",
                "regiao": "Sudeste",
                "populacao": 2521564,
                "latitude": -19.9167,
                "longitude": -43.9345,
                "capital": True,
            },
            {
                "ibge_codigo": "4106902",
                "nome": "Curitiba",
                "uf": "PR",
                "regiao": "Sul",
                "populacao": 1963726,
                "latitude": -25.4284,
                "longitude": -49.2733,
                "capital": True,
            },
            {
                "ibge_codigo": "4314902",
                "nome": "Porto Alegre",
                "uf": "RS",
                "regiao": "Sul",
                "populacao": 1492530,
                "latitude": -30.0346,
                "longitude": -51.2177,
                "capital": True,
            },
            {
                "ibge_codigo": "5300108",
                "nome": "Brasília",
                "uf": "DF",
                "regiao": "Centro-Oeste",
                "populacao": 3055149,
                "latitude": -15.8267,
                "longitude": -47.9218,
                "capital": True,
            },
            {
                "ibge_codigo": "2927408",
                "nome": "Salvador",
                "uf": "BA",
                "regiao": "Nordeste",
                "populacao": 2900319,
                "latitude": -12.9714,
                "longitude": -38.5014,
                "capital": True,
            },
            {
                "ibge_codigo": "2611606",
                "nome": "Recife",
                "uf": "PE",
                "regiao": "Nordeste",
                "populacao": 1653461,
                "latitude": -8.0476,
                "longitude": -34.8770,
                "capital": True,
            },
            {
                "ibge_codigo": "2304400",
                "nome": "Fortaleza",
                "uf": "CE",
                "regiao": "Nordeste",
                "populacao": 2703391,
                "latitude": -3.7172,
                "longitude": -38.5433,
                "capital": True,
            },
            {
                "ibge_codigo": "1302603",
                "nome": "Manaus",
                "uf": "AM",
                "regiao": "Norte",
                "populacao": 2219580,
                "latitude": -3.1190,
                "longitude": -60.0217,
                "capital": True,
            },
        ]

        self.cities_by_ibge = {
            city["ibge_codigo"]: city for city in self.cities_data
        }

        logger.warning(
            f"⚠️ Modo fallback: {len(self.cities_data)} capitais disponíveis"
        )

    def search_cities(
        self, query: str, limit: int = 10, uf: Optional[str] = None
    ) -> List[Dict]:
        """
        Busca cidades por nome (autocomplete).

        Args:
            query: Texto de busca (ex: "são", "rio", "curiti")
            limit: Número máximo de resultados (padrão: 10)
            uf: Filtrar por UF (ex: "SP", "RJ") - opcional

        Returns:
            List[Dict]: Lista de cidades encontradas, ordenadas por relevância
                [
                    {
                        "ibge_codigo": "3550308",
                        "nome": "São Paulo",
                        "uf": "SP",
                        "regiao": "Sudeste",
                        "populacao": 12252023,
                        "latitude": -23.5505,
                        "longitude": -46.6333,
                        "capital": True,
                    },
                    ...
                ]

        Examples:
            >>> search_cities("são", limit=5)
            [
                {"nome": "São Paulo", "uf": "SP", ...},
                {"nome": "São Gonçalo", "uf": "RJ", ...},
                {"nome": "São Bernardo do Campo", "uf": "SP", ...},
            ]

            >>> search_cities("rio", limit=3, uf="RJ")
            [
                {"nome": "Rio de Janeiro", "uf": "RJ", ...},
                {"nome": "Rio das Ostras", "uf": "RJ", ...},
            ]
        """
        if not query or len(query) < 2:
            # Retorna capitais se query muito curta
            return [
                city for city in self.cities_data if city.get("capital", False)
            ][:limit]

        # Normaliza query (remove acentos para busca insensível)
        query_normalized = normalize_text(query)

        # Filtra por nome
        matches = []
        for city in self.cities_data:
            # Normaliza nome da cidade
            city_name_normalized = normalize_text(city["nome"])

            # Aplica filtro de UF se especificado
            if uf and city["uf"].upper() != uf.upper():
                continue

            # Match exato tem prioridade máxima
            if city_name_normalized == query_normalized:
                matches.append((city, 3))  # Score 3
            # Match no início da palavra
            elif city_name_normalized.startswith(query_normalized):
                matches.append((city, 2))  # Score 2
            # Match em qualquer posição
            elif query_normalized in city_name_normalized:
                matches.append((city, 1))  # Score 1

        # Ordena por score (descendente) e depois por população (descendente)
        matches.sort(key=lambda x: (x[1], x[0].get("populacao", 0)), reverse=True)

        # Retorna apenas os dicts, sem os scores
        return [match[0] for match in matches[:limit]]

    def get_city_by_ibge(self, ibge_code: str) -> Optional[Dict]:
        """
        Busca cidade por código IBGE.

        Args:
            ibge_code: Código IBGE de 7 dígitos (ex: "3550308")

        Returns:
            Optional[Dict]: Dados da cidade ou None se não encontrada
        """
        return self.cities_by_ibge.get(ibge_code)

    def get_cities_by_uf(self, uf: str) -> List[Dict]:
        """
        Lista todas as cidades de uma UF.

        Args:
            uf: Sigla da UF (ex: "SP", "RJ")

        Returns:
            List[Dict]: Lista de cidades da UF, ordenadas por população
        """
        cities = [
            city for city in self.cities_data if city["uf"].upper() == uf.upper()
        ]

        # Ordena por população (descendente)
        cities.sort(key=lambda x: x.get("populacao", 0), reverse=True)

        return cities

    def get_all_states(self) -> List[Dict]:
        """
        Lista todos os estados brasileiros.

        Returns:
            List[Dict]: Lista de UFs com contagem de cidades
                [
                    {"uf": "SP", "nome": "São Paulo", "cidades": 645},
                    {"uf": "MG", "nome": "Minas Gerais", "cidades": 853},
                    ...
                ]
        """
        states_data = {
            "AC": "Acre",
            "AL": "Alagoas",
            "AP": "Amapá",
            "AM": "Amazonas",
            "BA": "Bahia",
            "CE": "Ceará",
            "DF": "Distrito Federal",
            "ES": "Espírito Santo",
            "GO": "Goiás",
            "MA": "Maranhão",
            "MT": "Mato Grosso",
            "MS": "Mato Grosso do Sul",
            "MG": "Minas Gerais",
            "PA": "Pará",
            "PB": "Paraíba",
            "PR": "Paraná",
            "PE": "Pernambuco",
            "PI": "Piauí",
            "RJ": "Rio de Janeiro",
            "RN": "Rio Grande do Norte",
            "RS": "Rio Grande do Sul",
            "RO": "Rondônia",
            "RR": "Roraima",
            "SC": "Santa Catarina",
            "SP": "São Paulo",
            "SE": "Sergipe",
            "TO": "Tocantins",
        }

        # Conta cidades por UF
        cities_count = {}
        for city in self.cities_data:
            uf = city["uf"]
            cities_count[uf] = cities_count.get(uf, 0) + 1

        # Monta lista de estados
        states = [
            {"uf": uf, "nome": nome, "cidades": cities_count.get(uf, 0)}
            for uf, nome in states_data.items()
        ]

        # Ordena por nome
        states.sort(key=lambda x: x["nome"])

        return states

    def validate_parana_data(self) -> Dict:
        """
        Valida qualidade dos dados das cidades do Paraná.
        
        Retorna estatísticas sobre:
        - Total de municípios
        - Cobertura de população real
        - Cobertura de coordenadas precisas
        - Cidades com dados incompletos
        
        Returns:
            Dicionário com estatísticas de qualidade
        """
        DEFAULT_POPULATION = 10000
        DEFAULT_LAT = -25.2521  # Centróide do PR
        DEFAULT_LON = -52.0215
        
        # Filtra apenas cidades do Paraná
        pr_cities = [c for c in self.cities_data if c["uf"] == "PR"]
        total = len(pr_cities)
        
        if total == 0:
            return {
                "estado": "PR",
                "total_municipios": 0,
                "erro": "Nenhuma cidade do Paraná encontrada",
            }
        
        # Analisa população
        with_real_population = sum(
            1 for c in pr_cities if c["populacao"] != DEFAULT_POPULATION
        )
        with_default_population = total - with_real_population
        population_coverage = (with_real_population / total) * 100
        
        # Analisa coordenadas
        with_precise_coords = sum(
            1 for c in pr_cities
            if c["latitude"] != DEFAULT_LAT or c["longitude"] != DEFAULT_LON
        )
        with_centroid = total - with_precise_coords
        coords_coverage = (with_precise_coords / total) * 100
        
        # Identifica cidades incompletas (população OU coordenadas faltando)
        incomplete_cities = []
        for city in pr_cities:
            issues = []
            
            if city["populacao"] == DEFAULT_POPULATION:
                issues.append("população_padrão")
            
            if (city["latitude"] == DEFAULT_LAT and 
                city["longitude"] == DEFAULT_LON):
                issues.append("coordenadas_centróide")
            
            if issues:
                incomplete_cities.append({
                    "ibge_codigo": city["ibge_codigo"],
                    "nome": city["nome"],
                    "problemas": issues,
                })
        
        # Calcula qualidade geral
        avg_coverage = (population_coverage + coords_coverage) / 2
        
        if avg_coverage >= 95:
            quality = "EXCELENTE"
        elif avg_coverage >= 80:
            quality = "MUITO_BOM"
        elif avg_coverage >= 60:
            quality = "BOM"
        elif avg_coverage >= 40:
            quality = "REGULAR"
        else:
            quality = "PRECISA_MELHORAR"
        
        return {
            "estado": "PR",
            "nome_estado": "Paraná",
            "total_municipios": total,
            "populacao": {
                "com_dados_reais": with_real_population,
                "com_valor_padrao": with_default_population,
                "cobertura_percentual": round(population_coverage, 2),
            },
            "coordenadas": {
                "com_coordenadas_precisas": with_precise_coords,
                "com_centroide": with_centroid,
                "cobertura_percentual": round(coords_coverage, 2),
            },
            "qualidade_geral": quality,
            "cobertura_media": round(avg_coverage, 2),
            "encoding": "UTF-8",
            "cidades_incompletas": incomplete_cities,
            "total_incompletas": len(incomplete_cities),
        }


# ════════════════════════════════════════════════════════════════════════════
# INSTÂNCIA SINGLETON
# ════════════════════════════════════════════════════════════════════════════

cities_service = CitiesService()
