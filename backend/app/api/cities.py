"""
════════════════════════════════════════════════════════════════════════════
ENDPOINT /api/v1/cities - BUSCA DE MUNICÍPIOS BRASILEIROS
════════════════════════════════════════════════════════════════════════════

Endpoints para buscar municípios brasileiros (5.570 cidades).

Features:
    - Busca por nome (autocomplete)
    - Busca por UF
    - Busca por código IBGE
    - Lista de estados
    - Dados do IBGE (população, coordenadas)

Autor: Dengo Team
Data: 2025-12-23
════════════════════════════════════════════════════════════════════════════
"""

from typing import List, Optional

from fastapi import APIRouter, HTTPException, Path, Query

from app.core.logger import logger
from app.services.cities_service import cities_service

router = APIRouter()


@router.get("/search")
async def search_cities(
    q: str = Query(..., min_length=2, description="Texto de busca (mín. 2 caracteres)"),
    limit: int = Query(10, ge=1, le=50, description="Número máximo de resultados"),
    uf: Optional[str] = Query(
        None, min_length=2, max_length=2, description="Filtrar por UF (ex: SP, RJ)"
    ),
):
    """
    Busca cidades por nome (autocomplete).

    **Exemplos:**
    - `/cities/search?q=são` → São Paulo, São Gonçalo, São Bernardo...
    - `/cities/search?q=rio&uf=RJ` → Rio de Janeiro, Rio das Ostras...
    - `/cities/search?q=curiti&limit=5` → Curitiba, Curitibanos...

    **Response:**
    ```json
    {
        "query": "são",
        "total": 127,
        "results": [
            {
                "ibge_codigo": "3550308",
                "nome": "São Paulo",
                "uf": "SP",
                "regiao": "Sudeste",
                "populacao": 12252023,
                "latitude": -23.5505,
                "longitude": -46.6333,
                "capital": true
            },
            ...
        ]
    }
    ```
    """
    logger.info(f"🔍 Busca de cidades: q='{q}', uf={uf}, limit={limit}")

    results = cities_service.search_cities(query=q, limit=limit, uf=uf)

    logger.success(f"OK - Encontradas {len(results)} cidades")

    return {"query": q, "uf": uf, "total": len(results), "results": results}


@router.get("/{ibge_code}")
async def get_city_by_ibge(
    ibge_code: str = Path(..., min_length=7, max_length=7, description="Código IBGE")
):
    """
    Busca cidade por código IBGE.

    **Exemplo:**
    - `/cities/3550308` → São Paulo

    **Response:**
    ```json
    {
        "ibge_codigo": "3550308",
        "nome": "São Paulo",
        "uf": "SP",
        "regiao": "Sudeste",
        "populacao": 12252023,
        "latitude": -23.5505,
        "longitude": -46.6333,
        "capital": true
    }
    ```
    """
    logger.info(f"Busca por IBGE: {ibge_code}")

    city = cities_service.get_city_by_ibge(ibge_code)

    if not city:
        logger.error(f"ERRO - Cidade nao encontrada: {ibge_code}")
        raise HTTPException(
            status_code=404, detail=f"Cidade com código IBGE {ibge_code} não encontrada"
        )

    logger.success(f"OK - Cidade encontrada: {city['nome']}/{city['uf']}")

    return city


@router.get("/uf/{uf}")
async def get_cities_by_uf(
    uf: str = Path(..., min_length=2, max_length=2, description="Sigla da UF")
):
    """
    Lista todas as cidades de uma UF.

    **Exemplo:**
    - `/cities/uf/SP` → 645 cidades de São Paulo

    **Response:**
    ```json
    {
        "uf": "SP",
        "total": 645,
        "cities": [
            {
                "ibge_codigo": "3550308",
                "nome": "São Paulo",
                "populacao": 12252023,
                ...
            },
            ...
        ]
    }
    ```
    """
    logger.info(f"🔍 Listando cidades de: {uf}")

    cities = cities_service.get_cities_by_uf(uf)

    if not cities:
        logger.error(f"❌ UF não encontrada ou sem cidades: {uf}")
        raise HTTPException(
            status_code=404, detail=f"UF {uf} não encontrada ou sem cidades"
        )

    logger.success(f"✓ {len(cities)} cidades em {uf}")

    return {"uf": uf.upper(), "total": len(cities), "cities": cities}


@router.get("/states/list")
async def list_states():
    """
    Lista todos os estados brasileiros.

    **Response:**
    ```json
    {
        "total": 27,
        "states": [
            {"uf": "AC", "nome": "Acre", "cidades": 22},
            {"uf": "SP", "nome": "São Paulo", "cidades": 645},
            ...
        ]
    }
    ```
    """
    logger.info("🔍 Listando estados")

    states = cities_service.get_all_states()

    logger.success(f"✓ {len(states)} estados listados")

    return {"total": len(states), "states": states}


@router.get("/validate/pr")
async def validate_parana_data():
    """
    Valida qualidade dos dados das cidades do Paraná.
    
    Retorna estatísticas sobre:
    - Total de municípios
    - Cobertura de população real
    - Cobertura de coordenadas precisas
    - Cidades com dados incompletos
    
    **Response:**
    ```json
    {
        "estado": "PR",
        "total_municipios": 399,
        "populacao": {
            "com_dados_reais": 392,
            "com_valor_padrao": 7,
            "cobertura_percentual": 98.2
        },
        "coordenadas": {
            "com_coordenadas_precisas": 399,
            "com_centroide": 0,
            "cobertura_percentual": 100.0
        },
        "qualidade_geral": "EXCELENTE",
        "encoding": "UTF-8",
        "cidades_incompletas": []
    }
    ```
    """
    logger.info("🔍 Validando dados do Paraná")

    validation = cities_service.validate_parana_data()

    logger.success(
        f"✓ Validação concluída - Qualidade: {validation['qualidade_geral']}"
    )

    return validation
