"""Script para testar a API do Dengo - Municípios do Paraná"""
import httpx
import json

def test_dashboard():
    """Testa o endpoint /api/v1/dashboard com municípios do Paraná"""
    
    print("🧪 Testando API Dengo Dashboard - Paraná (399 municípios)")
    print("=" * 80)
    
    # Teste 1: Curitiba (Capital do Paraná)
    print("\n1️⃣ Testando: Curitiba - PR (4106902)")
    print("-" * 80)
    
    try:
        response = httpx.get(
            "http://127.0.0.1:8000/api/v1/dashboard",
            params={"city_id": "4106902"},
            timeout=30.0
        )
        
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print("\n✅ Sucesso! Resposta:")
            print(json.dumps(data, indent=2, ensure_ascii=False))
            
            # Verifica estrutura
            print("\n📊 Validação dos Dados:")
            print(f"  Cidade: {data['cidade']['nome']}")
            print(f"  População: {data['cidade']['populacao']:,}")
            print(f"  Histórico: {len(data['dados_historicos'])} dias")
            print(f"  Casos Estimados: {data['predicao']['casos_estimados']}")
            print(f"  Nível de Risco: {data['predicao']['nivel_risco']}")
            print(f"  Tendência: {data['predicao']['tendencia']}")
            print(f"  Confiança: {data['predicao']['confianca']:.2%}")
            
        else:
            print(f"\n❌ Erro {response.status_code}")
            print(response.text)
            
    except Exception as e:
        print(f"\n❌ Erro na requisição: {e}")
    
    # Teste 2: Londrina (2ª maior cidade do PR)
    print("\n\n2️⃣ Testando: Londrina - PR (4113700)")
    print("-" * 80)
    
    try:
        response = httpx.get(
            "http://127.0.0.1:8000/api/v1/dashboard",
            params={"city_id": "4113700"},
            timeout=30.0
        )
        
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"\n✅ Sucesso para {data['cidade']['nome']}!")
            print(f"  Casos Estimados: {data['predicao']['casos_estimados']}")
            print(f"  Nível de Risco: {data['predicao']['nivel_risco']}")
        else:
            print(f"\n❌ Erro {response.status_code}")
            
    except Exception as e:
        print(f"\n❌ Erro na requisição: {e}")
    
    # Teste 3: Geocode fora do Paraná (deve falhar)
    print("\n\n3️⃣ Testando: São Paulo - Fora do PR (3550308 - deve falhar)")
    print("-" * 80)
    
    try:
        response = httpx.get(
            "http://127.0.0.1:8000/api/v1/dashboard",
            params={"city_id": "3550308"},  # São Paulo - não é PR
            timeout=30.0
        )
        
        print(f"Status Code: {response.status_code}")
        
        if response.status_code in [404, 422]:
            print("✅ Erro esperado para cidade fora do Paraná")
            print(f"Mensagem: {response.json()['detail']}")
        else:
            print(f"⚠️ Status inesperado: {response.status_code}")
            
    except Exception as e:
        print(f"\n❌ Erro na requisição: {e}")
    
    print("\n" + "=" * 80)
    print("✅ Testes concluídos!")
    print("\nℹ️  Sistema configurado para 399 municípios do Paraná (geocode inicia com 41)")

if __name__ == "__main__":
    test_dashboard()
