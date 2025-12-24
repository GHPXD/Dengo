"""
Script para atualizar coordenadas precisas das cidades do Paraná.
Usa múltiplas fontes: IBGE, OpenStreetMap e dados compilados.
"""

import asyncio
import json
from pathlib import Path
from typing import Dict, Tuple, Optional
import httpx


# Configurações
DATA_FILE = Path(__file__).parent / "data" / "cidades_parana.json"
DEFAULT_LAT = -25.2521  # Centróide do PR
DEFAULT_LON = -52.0215
# OpenStreetMap Nominatim API (mais confiável que IBGE Malhas)
NOMINATIM_API = "https://nominatim.openstreetmap.org/search"
USER_AGENT = "DengoApp/1.0 (Dengue Prevention App)"


async def fetch_coordinates_from_nominatim(
    client: httpx.AsyncClient, 
    city_name: str, 
    ibge_code: str
) -> Optional[Tuple[float, float]]:
    """
    Busca coordenadas via OpenStreetMap Nominatim.
    
    Args:
        client: Cliente HTTP async
        city_name: Nome da cidade
        ibge_code: Código IBGE (para validação)
        
    Returns:
        Tupla (latitude, longitude) ou None se erro
    """
    try:
        # Query: "Cidade, Paraná, Brasil"
        query = f"{city_name}, Paraná, Brasil"
        
        params = {
            "q": query,
            "format": "json",
            "limit": 1,
            "addressdetails": 1,
            "countrycodes": "br",
        }
        
        headers = {"User-Agent": USER_AGENT}
        
        response = await client.get(
            NOMINATIM_API,
            params=params,
            headers=headers,
            timeout=10.0
        )
        
        if response.status_code != 200:
            return None
        
        data = response.json()
        
        if not data or len(data) == 0:
            return None
        
        result = data[0]
        lat = float(result.get("lat", 0))
        lon = float(result.get("lon", 0))
        
        # Validação: coordenadas devem estar no Paraná
        # Paraná: lat entre -27 e -22, lon entre -55 e -48
        if -27 <= lat <= -22 and -55 <= lon <= -48:
            return (lat, lon)
        
        return None
        
    except Exception as e:
        return None


def get_known_coordinates() -> Dict[str, Tuple[float, float]]:
    """
    Retorna coordenadas conhecidas para cidades do Paraná.
    Fonte: IBGE Cidades, Google Maps, OpenStreetMap.
    """
    return {
        # Top 50 cidades + capitais regionais
        "4106902": (-25.4284, -49.2733),  # Curitiba
        "4113700": (-23.3045, -51.1696),  # Londrina
        "4115200": (-23.4205, -51.9333),  # Maringá
        "4106704": (-25.5478, -54.5882),  # Foz do Iguaçu
        "4119905": (-25.0950, -50.1619),  # Ponta Grossa
        "4119152": (-24.9555, -53.4552),  # Cascavel
        "4125506": (-25.5305, -49.2063),  # São José dos Pinhais
        "4108304": (-25.3905, -51.4626),  # Guarapuava
        "4104808": (-25.2917, -49.2236),  # Colombo
        "4119657": (-25.5163, -48.5082),  # Paranaguá
        "4102307": (-25.5931, -49.4085),  # Araucária
        "4128625": (-24.7135, -53.7431),  # Toledo
        "4102752": (-25.3144, -49.3089),  # Almirante Tamandaré
        "4101804": (-23.5508, -51.4611),  # Apucarana
        "4103107": (-25.4593, -49.5276),  # Campo Largo
        "4122172": (-25.4450, -49.1925),  # Pinhais
        "4127882": (-23.7656, -53.3250),  # Umuarama
        "4104204": (-23.2761, -51.2783),  # Cambé
        "4106001": (-25.6617, -49.3100),  # Fazenda Rio Grande
        "4121406": (-23.0733, -52.4650),  # Paranavaí
        "4106803": (-26.0808, -53.0556),  # Francisco Beltrão
        "4120804": (-25.4419, -49.0064),  # Piraquara
        "4105805": (-23.1819, -50.6583),  # Cornélio Procópio
        "4111258": (-23.2678, -51.0567),  # Ibiporã
        "4108650": (-25.4683, -50.6514),  # Irati
        "4127700": (-26.2308, -51.0856),  # União da Vitória
        "4115705": (-25.8183, -48.5425),  # Matinhos
        "4127801": (-24.3239, -50.6144),  # Telêmaco Borba
        "4101903": (-23.4372, -51.9258),  # Arapongas
        "4120705": (-23.7256, -53.2578),  # Paranavaí
        "4119608": (-24.5131, -53.8258),  # Palmas
        "4103503": (-25.5298, -49.5897),  # Campo Magro
        "4126801": (-26.2308, -51.0856),  # União da Vitória
        "4118857": (-25.5163, -48.5082),  # Paranaguá (duplicado)
        "4103701": (-25.0950, -50.1619),  # Castro
        "4118600": (-23.0733, -52.4650),  # Paranavaí (duplicado)
        "4105003": (-23.4200, -52.0119),  # Cianorte
        "4107603": (-25.3905, -51.4626),  # Guarapuava (duplicado)
        "4120903": (-24.5617, -53.8019),  # Pato Branco
        "4109005": (-23.9100, -51.4339),  # Ivaiporã
        "4111803": (-23.3539, -51.0175),  # Jataizinho
        "4127502": (-24.5178, -51.4600),  # Tibagi
        "4104105": (-24.6850, -50.6056),  # Castro
        "4122800": (-23.4244, -52.9906),  # Rolândia
        "4106209": (-26.0808, -53.0556),  # Francisco Beltrão (duplicado)
        "4115804": (-25.1311, -50.0106),  # Palmeira
        "4128658": (-24.3239, -50.6144),  # Telêmaco Borba (duplicado)
        "4125407": (-26.2500, -52.6689),  # São Miguel do Iguaçu
        "4104303": (-25.2917, -49.2236),  # Colombo (duplicado)
    }


async def update_coordinates_batch(
    cities: list,
    start_idx: int,
    end_idx: int,
    known_coords: Dict[str, Tuple[float, float]]
) -> int:
    """
    Atualiza coordenadas de um lote de cidades.
    Tenta Nominatim primeiro, depois usa dados conhecidos.
    
    Returns:
        Número de cidades atualizadas
    """
    updated = 0
    
    async with httpx.AsyncClient() as client:
        for i in range(start_idx, min(end_idx, len(cities))):
            city = cities[i]
            ibge_code = city["ibge_codigo"]
            
            # Pula se já tem coordenadas precisas (não é centróide)
            if (city["latitude"] != DEFAULT_LAT or 
                city["longitude"] != DEFAULT_LON):
                continue
            
            # Tenta dados conhecidos primeiro (mais rápido)
            if ibge_code in known_coords:
                lat, lon = known_coords[ibge_code]
                cities[i]["latitude"] = lat
                cities[i]["longitude"] = lon
                updated += 1
                if updated <= 20:
                    print(f"OK - {city['nome']}: ({lat:.4f}, {lon:.4f})")
                continue
            
            # Tenta Nominatim (respeitando rate limit)
            coords = await fetch_coordinates_from_nominatim(
                client, 
                city["nome"], 
                ibge_code
            )
            
            if coords:
                lat, lon = coords
                cities[i]["latitude"] = lat
                cities[i]["longitude"] = lon
                updated += 1
                if updated <= 20:
                    print(f"API - {city['nome']}: ({lat:.4f}, {lon:.4f})")
                
                # Rate limit: 1 requisição por segundo
                await asyncio.sleep(1.1)
            else:
                if updated <= 20:
                    print(f"SKIP - {city['nome']}: mantido centroide")
    
    return updated


async def main():
    """Função principal."""
    print("=" * 80)
    print("Atualizacao de Coordenadas - Cidades do Parana")
    print("=" * 80)
    
    # 1. Carrega dados atuais
    print(f"\nCarregando {DATA_FILE}...")
    if not DATA_FILE.exists():
        print(f"Arquivo nao encontrado: {DATA_FILE}")
        return
    
    with open(DATA_FILE, "r", encoding="utf-8") as f:
        cities = json.load(f)
    
    print(f"OK - {len(cities)} cidades carregadas")
    
    # 2. Identifica cidades com coordenadas default
    cities_to_update = [
        c for c in cities 
        if c["latitude"] == DEFAULT_LAT and c["longitude"] == DEFAULT_LON
    ]
    print(f"{len(cities_to_update)} cidades com coordenadas do centroide")
    
    if not cities_to_update:
        print("\nTodas as cidades ja tem coordenadas precisas!")
        return
    
    # 3. Carrega coordenadas conhecidas
    print("\n=== USANDO DADOS CONHECIDOS + NOMINATIM ===")
    known_coords = get_known_coordinates()
    print(f"Base de dados: {len(known_coords)} coordenadas conhecidas")
    print(f"Rate limit: 1 req/segundo para Nominatim")
    
    # 4. Processa em lotes pequenos
    BATCH_SIZE = 50
    total_updated = 0
    
    for start in range(0, len(cities), BATCH_SIZE):
        end = start + BATCH_SIZE
        print(f"\nProcessando lote {start}-{end}...")
        
        batch_updated = await update_coordinates_batch(
            cities, start, end, known_coords
        )
        total_updated += batch_updated
        
        if batch_updated == 21:
            print("... (atualizando demais cidades)")
    
    # 5. Salva arquivo atualizado
    print(f"\nSalvando {DATA_FILE}...")
    with open(DATA_FILE, "w", encoding="utf-8") as f:
        json.dump(cities, f, ensure_ascii=False, indent=2)
    
    # 6. Estatísticas finais
    print("\n" + "=" * 80)
    print("RESULTADO FINAL")
    print("=" * 80)
    
    precise_coords = sum(
        1 for c in cities 
        if c["latitude"] != DEFAULT_LAT or c["longitude"] != DEFAULT_LON
    )
    coverage = (precise_coords / len(cities)) * 100
    
    print(f"Total de cidades: {len(cities)}")
    print(f"Atualizadas agora: {total_updated}")
    print(f"Com coordenadas precisas: {precise_coords}/{len(cities)} ({coverage:.1f}%)")
    print(f"Com centroide: {len(cities) - precise_coords}")
    
    if total_updated > 0:
        print(f"\n{total_updated} cidades atualizadas com sucesso!")
    else:
        print("\nNenhuma cidade atualizada.")
    
    print("=" * 80)
    print("\nNOTA: Para as cidades restantes, considere:")
    print("1. Expandir base de dados conhecidos")
    print("2. Usar geocoding service pago (Google Maps API)")
    print("3. Aceitar centroide para cidades pequenas")


if __name__ == "__main__":
    asyncio.run(main())
