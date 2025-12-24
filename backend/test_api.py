"""Script para testar a API do Dengo"""
import httpx
import json

def test_dashboard():
    """Testa o endpoint /api/v1/dashboard"""
    
    print("🧪 Testando API Dengo Dashboard...")
    print("=" * 80)
    
    # Teste 1: São Paulo
    print("\n1️⃣ Testando: São Paulo (3550308)")
    print("-" * 80)
    
    try:
        response = httpx.get(
            "http://127.0.0.1:8000/api/v1/dashboard",
            params={"city_id": "3550308"},
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
    
    # Teste 2: Rio de Janeiro
    print("\n\n2️⃣ Testando: Rio de Janeiro (3304557)")
    print("-" * 80)
    
    try:
        response = httpx.get(
            "http://127.0.0.1:8000/api/v1/dashboard",
            params={"city_id": "3304557"},
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
    
    # Teste 3: Cidade inválida
    print("\n\n3️⃣ Testando: Cidade Inválida (9999999)")
    print("-" * 80)
    
    try:
        response = httpx.get(
            "http://127.0.0.1:8000/api/v1/dashboard",
            params={"city_id": "9999999"},
            timeout=30.0
        )
        
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 404:
            print("✅ Erro 404 esperado para cidade inválida")
            print(f"Mensagem: {response.json()['detail']}")
        else:
            print(f"⚠️ Status inesperado: {response.status_code}")
            
    except Exception as e:
        print(f"\n❌ Erro na requisição: {e}")
    
    print("\n" + "=" * 80)
    print("✅ Testes concluídos!")

if __name__ == "__main__":
    test_dashboard()
