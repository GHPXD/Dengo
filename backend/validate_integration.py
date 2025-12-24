"""
Script de validação rápida da integração Flutter ↔ Backend

Este script verifica:
1. Backend está rodando
2. Endpoints respondem corretamente
3. Dados estão no formato esperado pelo Flutter
"""

import httpx
import json
from typing import Dict, Any


def validate_backend() -> bool:
    """Valida se o backend está acessível"""
    print("🔍 Verificando backend...")
    try:
        response = httpx.get("http://127.0.0.1:8000/health", timeout=5.0)
        if response.status_code == 200:
            print("✅ Backend está rodando!")
            return True
        else:
            print(f"❌ Backend retornou status {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Erro ao conectar no backend: {e}")
        return False


def validate_dashboard_schema(data: Dict[str, Any]) -> bool:
    """Valida se o JSON retornado tem a estrutura esperada pelo Flutter"""
    print("\n🔍 Validando schema do dashboard...")
    
    required_keys = {
        "cidade": ["ibge_codigo", "nome", "populacao"],
        "dados_historicos": ["data", "casos", "temperatura_media", "umidade_media"],
        "predicao": ["casos_estimados", "nivel_risco", "tendencia", "confianca"],
    }
    
    # Valida cidade
    if "cidade" not in data:
        print("❌ Falta chave 'cidade'")
        return False
    
    for key in required_keys["cidade"]:
        if key not in data["cidade"]:
            print(f"❌ Falta chave 'cidade.{key}'")
            return False
    
    # Valida histórico
    if "dados_historicos" not in data:
        print("❌ Falta chave 'dados_historicos'")
        return False
    
    if len(data["dados_historicos"]) != 5:
        print(f"⚠️ Esperado 5 dias de histórico, encontrado {len(data['dados_historicos'])}")
    
    for i, hist in enumerate(data["dados_historicos"]):
        for key in required_keys["dados_historicos"]:
            if key not in hist:
                print(f"❌ Falta chave 'dados_historicos[{i}].{key}'")
                return False
    
    # Valida predição
    if "predicao" not in data:
        print("❌ Falta chave 'predicao'")
        return False
    
    for key in required_keys["predicao"]:
        if key not in data["predicao"]:
            print(f"❌ Falta chave 'predicao.{key}'")
            return False
    
    # Valida tipos de dados
    if not isinstance(data["cidade"]["populacao"], int):
        print("❌ 'populacao' deve ser int")
        return False
    
    if not isinstance(data["predicao"]["casos_estimados"], int):
        print("❌ 'casos_estimados' deve ser int")
        return False
    
    if not isinstance(data["predicao"]["confianca"], (int, float)):
        print("❌ 'confianca' deve ser número")
        return False
    
    if data["predicao"]["confianca"] < 0 or data["predicao"]["confianca"] > 1:
        print(f"⚠️ 'confianca' fora do range 0-1: {data['predicao']['confianca']}")
    
    # Valida valores de enum
    valid_risk_levels = ["baixo", "moderado", "alto", "muito_alto"]
    if data["predicao"]["nivel_risco"] not in valid_risk_levels:
        print(f"❌ 'nivel_risco' inválido: {data['predicao']['nivel_risco']}")
        return False
    
    valid_trends = ["estavel", "subindo", "caindo"]
    if data["predicao"]["tendencia"] not in valid_trends:
        print(f"❌ 'tendencia' inválida: {data['predicao']['tendencia']}")
        return False
    
    print("✅ Schema válido!")
    return True


def test_dashboard_endpoint() -> bool:
    """Testa o endpoint principal do dashboard"""
    print("\n🧪 Testando endpoint /api/v1/dashboard...")
    
    try:
        response = httpx.get(
            "http://127.0.0.1:8000/api/v1/dashboard",
            params={"city_id": "3550308"},  # São Paulo
            timeout=30.0,
        )
        
        if response.status_code != 200:
            print(f"❌ Status code: {response.status_code}")
            print(f"Resposta: {response.text}")
            return False
        
        data = response.json()
        
        print("✅ Endpoint respondeu corretamente!")
        print(f"   Cidade: {data['cidade']['nome']}")
        print(f"   Casos Estimados: {data['predicao']['casos_estimados']}")
        print(f"   Nível de Risco: {data['predicao']['nivel_risco']}")
        print(f"   Confiança: {data['predicao']['confianca']:.0%}")
        
        return validate_dashboard_schema(data)
        
    except Exception as e:
        print(f"❌ Erro na requisição: {e}")
        return False


def main():
    """Executa todos os testes de validação"""
    print("=" * 80)
    print("🔗 VALIDAÇÃO DE INTEGRAÇÃO FLUTTER ↔ BACKEND")
    print("=" * 80)
    
    # Teste 1: Backend acessível
    if not validate_backend():
        print("\n❌ Backend não está rodando. Execute:")
        print("   cd backend && python -m uvicorn app.main:app --reload --port 8000")
        return False
    
    # Teste 2: Endpoint dashboard
    if not test_dashboard_endpoint():
        print("\n❌ Endpoint /dashboard falhou!")
        return False
    
    print("\n" + "=" * 80)
    print("✅ VALIDAÇÃO COMPLETA - SISTEMA PRONTO PARA INTEGRAÇÃO!")
    print("=" * 80)
    print("\n📱 Próximo passo: Executar Flutter e testar no app:")
    print("   flutter run -d chrome")
    print("   ou")
    print("   flutter run -d windows")
    
    return True


if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
