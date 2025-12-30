"""
Script de teste para endpoint de predições de dengue.
Testa health check e predições para Curitiba.

Usage:
    python test_predictions.py
"""

import requests
import json
from typing import Dict, Any
from datetime import datetime


BASE_URL = "http://127.0.0.1:8000/api/v1/predictions"


def print_section(title: str) -> None:
    """Imprime seção formatada."""
    print(f"\n{'=' * 80}")
    print(f"  {title}")
    print(f"{'=' * 80}\n")


def print_json(data: Dict[str, Any]) -> None:
    """Imprime JSON formatado."""
    print(json.dumps(data, indent=2, ensure_ascii=False))


def test_health_check() -> bool:
    """Testa health check do serviço."""
    print_section("1. HEALTH CHECK")
    
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=5)
        
        print(f"Status Code: {response.status_code}")
        print_json(response.json())
        
        if response.status_code == 200:
            data = response.json()
            if data.get("model_loaded"):
                print("\n✅ Modelo carregado com sucesso!")
                return True
            else:
                print("\n❌ Modelo NÃO carregado!")
                return False
        else:
            print(f"\n❌ Health check falhou: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"\n❌ Erro no health check: {e}")
        return False


def test_prediction_single_week() -> bool:
    """Testa predição para 1 semana (Curitiba)."""
    print_section("2. PREDIÇÃO 1 SEMANA - Curitiba")
    
    payload = {
        "geocode": "4106902",  # Curitiba
        "weeks_ahead": 1
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/predict",
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=30
        )
        
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print_json(data)
            
            # Validações
            print("\n" + "-" * 80)
            print("VALIDAÇÕES:")
            print("-" * 80)
            
            assert data["city"], "❌ Cidade não retornada"
            print(f"✅ Cidade: {data['city']}")
            
            assert data["geocode"] == "4106902", "❌ Geocode incorreto"
            print(f"✅ Geocode: {data['geocode']}")
            
            assert len(data["predictions"]) == 1, "❌ Deveria ter 1 predição"
            print(f"✅ Predições: {len(data['predictions'])} semana(s)")
            
            pred = data["predictions"][0]
            assert pred["predicted_cases"] > 0, "❌ Casos previstos <= 0"
            print(f"✅ Casos previstos: {pred['predicted_cases']:.2f}")
            
            assert pred["confidence"] in ["high", "medium", "low"], "❌ Confiança inválida"
            print(f"✅ Confiança: {pred['confidence']}")
            
            assert pred["lower_bound"] <= pred["predicted_cases"] <= pred["upper_bound"], "❌ Intervalo de confiança inválido"
            print(f"✅ Intervalo: [{pred['lower_bound']:.2f}, {pred['upper_bound']:.2f}]")
            
            assert data["trend"] in ["ascending", "descending", "stable"], "❌ Tendência inválida"
            print(f"✅ Tendência: {data['trend']} ({data['trend_percentage']:.2f}%)")
            
            metadata = data["model_metadata"]
            assert metadata["accuracy"] > 0.5, "❌ Acurácia muito baixa"
            print(f"✅ Acurácia: {metadata['accuracy']:.2%}")
            
            assert metadata["mae"] < 100, "❌ MAE muito alto"
            print(f"✅ MAE: {metadata['mae']:.2f} casos")
            
            print("\n✅ TODOS OS TESTES PASSARAM!")
            return True
            
        else:
            print(f"\n❌ Predição falhou: {response.status_code}")
            print_json(response.json())
            return False
            
    except AssertionError as e:
        print(f"\n❌ Validação falhou: {e}")
        return False
    except Exception as e:
        print(f"\n❌ Erro na predição: {e}")
        return False


def test_prediction_multiple_weeks() -> bool:
    """Testa predição para 4 semanas (Londrina)."""
    print_section("3. PREDIÇÃO 4 SEMANAS - Londrina")
    
    payload = {
        "geocode": "4113700",  # Londrina
        "weeks_ahead": 4
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/predict",
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=30
        )
        
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print_json(data)
            
            # Validações básicas
            print("\n" + "-" * 80)
            print("VALIDAÇÕES:")
            print("-" * 80)
            
            assert len(data["predictions"]) == 4, f"❌ Deveria ter 4 predições, tem {len(data['predictions'])}"
            print(f"✅ Predições: {len(data['predictions'])} semanas")
            
            # Verifica que confiança decresce com o horizonte temporal
            confidences = {"high": 3, "medium": 2, "low": 1}
            conf_scores = [confidences[p["confidence"]] for p in data["predictions"]]
            
            # Não precisa ser estritamente decrescente, mas última semana deve ter menor confiança que primeira
            if conf_scores[-1] <= conf_scores[0]:
                print(f"✅ Confiança decresce: {[p['confidence'] for p in data['predictions']]}")
            else:
                print(f"⚠️ Confiança não decresce conforme esperado")
            
            # Mostra resumo
            print("\nRESUMO DAS PREDIÇÕES:")
            for i, pred in enumerate(data["predictions"], 1):
                print(f"  Semana {i}: {pred['predicted_cases']:.1f} casos ({pred['confidence']})")
            
            print(f"\nTendência geral: {data['trend']} ({data['trend_percentage']:+.1f}%)")
            
            print("\n✅ TESTE DE MÚLTIPLAS SEMANAS PASSOU!")
            return True
            
        else:
            print(f"\n❌ Predição falhou: {response.status_code}")
            print_json(response.json())
            return False
            
    except AssertionError as e:
        print(f"\n❌ Validação falhou: {e}")
        return False
    except Exception as e:
        print(f"\n❌ Erro na predição: {e}")
        return False


def test_invalid_geocode() -> bool:
    """Testa validação de geocode inválido."""
    print_section("4. TESTE DE VALIDAÇÃO - Geocode Inválido")
    
    test_cases = [
        ("123", "Geocode muito curto"),
        ("12345678", "Geocode muito longo"),
        ("3550308", "São Paulo (fora do Paraná)"),
        ("9999999", "Geocode inexistente"),
    ]
    
    all_passed = True
    
    for geocode, description in test_cases:
        print(f"\nTestando: {description} - {geocode}")
        
        try:
            response = requests.post(
                f"{BASE_URL}/predict",
                json={"geocode": geocode, "weeks_ahead": 1},
                timeout=10
            )
            
            print(f"Status Code: {response.status_code}")
            
            if response.status_code in [404, 422]:
                print(f"✅ Validação funcionou: {response.json().get('detail', 'Erro esperado')}")
            else:
                print(f"❌ Deveria ter retornado 404/422, retornou {response.status_code}")
                all_passed = False
                
        except Exception as e:
            print(f"❌ Erro inesperado: {e}")
            all_passed = False
    
    if all_passed:
        print("\n✅ TODOS OS TESTES DE VALIDAÇÃO PASSARAM!")
    else:
        print("\n❌ ALGUNS TESTES DE VALIDAÇÃO FALHARAM!")
    
    return all_passed


def test_invalid_weeks_ahead() -> bool:
    """Testa validação de weeks_ahead inválido."""
    print_section("5. TESTE DE VALIDAÇÃO - Weeks Ahead Inválido")
    
    test_cases = [
        (0, "Zero semanas"),
        (-1, "Semanas negativas"),
        (5, "Mais que 4 semanas"),
        (100, "Horizonte muito longo"),
    ]
    
    all_passed = True
    
    for weeks, description in test_cases:
        print(f"\nTestando: {description} - {weeks}")
        
        try:
            response = requests.post(
                f"{BASE_URL}/predict",
                json={"geocode": "4106902", "weeks_ahead": weeks},
                timeout=10
            )
            
            print(f"Status Code: {response.status_code}")
            
            if response.status_code == 422:
                error_detail = response.json()
                print(f"✅ Validação funcionou: {error_detail.get('detail', 'Erro esperado')}")
            else:
                print(f"❌ Deveria ter retornado 422, retornou {response.status_code}")
                all_passed = False
                
        except Exception as e:
            print(f"❌ Erro inesperado: {e}")
            all_passed = False
    
    if all_passed:
        print("\n✅ TODOS OS TESTES DE VALIDAÇÃO PASSARAM!")
    else:
        print("\n❌ ALGUNS TESTES DE VALIDAÇÃO FALHARAM!")
    
    return all_passed


def main():
    """Executa todos os testes."""
    print(f"\n{'#' * 80}")
    print(f"#  TESTE DE API DE PREDIÇÕES DE DENGUE")
    print(f"#  Data: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"#  Base URL: {BASE_URL}")
    print(f"{'#' * 80}")
    
    results = {
        "Health Check": test_health_check(),
        "Predição 1 Semana": test_prediction_single_week(),
        "Predição 4 Semanas": test_prediction_multiple_weeks(),
        "Validação Geocode": test_invalid_geocode(),
        "Validação Weeks Ahead": test_invalid_weeks_ahead(),
    }
    
    # Resumo final
    print_section("RESUMO DOS TESTES")
    
    for test_name, passed in results.items():
        status = "✅ PASSOU" if passed else "❌ FALHOU"
        print(f"{test_name:.<50} {status}")
    
    total = len(results)
    passed = sum(results.values())
    
    print(f"\n{'=' * 80}")
    print(f"Total: {passed}/{total} testes passaram ({passed/total*100:.1f}%)")
    print(f"{'=' * 80}\n")
    
    if all(results.values()):
        print("🎉 TODOS OS TESTES PASSARAM! API FUNCIONANDO PERFEITAMENTE!")
        return 0
    else:
        print("⚠️ ALGUNS TESTES FALHARAM. VERIFIQUE OS LOGS ACIMA.")
        return 1


if __name__ == "__main__":
    exit(main())
