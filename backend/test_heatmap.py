"""
Teste manual do endpoint de heatmap.
"""
import requests
import json

def test_heatmap():
    """Testa endpoint GET /api/v1/heatmap"""
    
    # URL base (assumindo que o servidor está rodando localmente)
    base_url = "http://localhost:8000"
    
    # Teste 1: Heatmap da última semana
    print("=" * 80)
    print("TESTE 1: Heatmap - Última Semana (PR)")
    print("=" * 80)
    
    response = requests.get(f"{base_url}/api/v1/heatmap", params={
        "state": "PR",
        "period": "week"
    })
    
    print(f"Status Code: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"\nEstado: {data['estado']}")
        print(f"Total de cidades: {data['total_cidades']}")
        print(f"Período: {data['periodo']}")
        print(f"\nPrimeiras 5 cidades:")
        
        for i, city in enumerate(data['cidades'][:5]):
            print(f"\n{i+1}. {city['nome']}")
            print(f"   Geocode: {city['geocode']}")
            print(f"   Coordenadas: ({city['latitude']}, {city['longitude']})")
            print(f"   Casos: {city['casos']}")
            print(f"   Incidência: {city['incidencia']:.2f}/100k")
            print(f"   Nível de Risco: {city['nivel_risco']}")
    else:
        print(f"Erro: {response.text}")
    
    # Teste 2: Heatmap do último mês
    print("\n" + "=" * 80)
    print("TESTE 2: Heatmap - Último Mês (PR)")
    print("=" * 80)
    
    response = requests.get(f"{base_url}/api/v1/heatmap", params={
        "state": "PR",
        "period": "month"
    })
    
    print(f"Status Code: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"\nEstado: {data['estado']}")
        print(f"Total de cidades: {data['total_cidades']}")
        print(f"Período: {data['periodo']}")
        
        # Estatísticas de nível de risco
        risk_counts = {"baixo": 0, "medio": 0, "alto": 0}
        for city in data['cidades']:
            risk_counts[city['nivel_risco']] += 1
        
        print(f"\nDistribuição de Risco:")
        print(f"  Baixo: {risk_counts['baixo']} cidades")
        print(f"  Médio: {risk_counts['medio']} cidades")
        print(f"  Alto: {risk_counts['alto']} cidades")
    else:
        print(f"Erro: {response.text}")
    
    print("\n" + "=" * 80)

if __name__ == "__main__":
    print("Certifique-se de que o servidor está rodando (python -m uvicorn app.main:app --reload)")
    print()
    
    try:
        test_heatmap()
    except requests.exceptions.ConnectionError:
        print("ERRO: Não foi possível conectar ao servidor.")
        print("Execute: cd backend && python -m uvicorn app.main:app --reload")
