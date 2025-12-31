# 🚀 Deploy no Render - Dengo API

## Pré-requisitos
- Conta no [Render](https://render.com)
- Repositório no GitHub
- Chave da API OpenWeather

## Passo a Passo

### 1. Preparar o Repositório

```bash
# Commit das mudanças
git add .
git commit -m "feat: preparar backend para deploy no Render"
git push origin main
```

### 2. Deploy Automático (Blueprint)

1. Acesse [Render Dashboard](https://dashboard.render.com)
2. Clique em **"New" → "Blueprint"**
3. Conecte seu repositório GitHub
4. Selecione o arquivo `backend/render.yaml`
5. Clique em **"Apply"**

O Render criará automaticamente:
- ✅ API Web Service (FastAPI)
- ✅ Redis Cache (25MB grátis)

### 3. Configurar Variáveis de Ambiente

No dashboard do Render, vá em **"Environment"** e adicione:

| Variável | Valor |
|----------|-------|
| `OPENWEATHER_API_KEY` | Sua chave da API OpenWeather |

### 4. Atualizar Frontend

No arquivo `lib/core/config/app_config.dart`:

```dart
// Mude para true
static const bool isProduction = true;

// Atualize a URL com a URL gerada pelo Render
static const String productionApiUrl = 'https://SEU-APP.onrender.com/api/v1';
```

### 5. Testar

```bash
# Testar health check
curl https://SEU-APP.onrender.com/health

# Testar API
curl https://SEU-APP.onrender.com/api/v1/dashboard?city_id=4106902
```

## ⚠️ Limitações do Free Tier

| Recurso | Limite |
|---------|--------|
| **RAM** | 512MB |
| **CPU** | Compartilhada |
| **Sleep** | Após 15 min inatividade |
| **Cold Start** | ~30 segundos |
| **Redis** | 25MB |
| **Bandwidth** | 100GB/mês |

### Cold Start
O serviço "dorme" após 15 minutos sem requisições. A primeira requisição após o sleep leva ~30 segundos.

**Dica**: Use um serviço de ping (como UptimeRobot gratuito) para manter ativo.

## 📊 Monitoramento

- **Logs**: Dashboard → Service → Logs
- **Métricas**: Dashboard → Service → Metrics
- **Health**: `GET /health`

## 🔄 CI/CD Automático

Cada push para `main` dispara deploy automático:
1. Build do requirements
2. Deploy da nova versão
3. Health check
4. Rollback automático se falhar

## 💰 Custos

| Plano | Preço | Recursos |
|-------|-------|----------|
| **Free** | $0 | 512MB RAM, sleep após 15min |
| **Starter** | $7/mês | 512MB RAM, sem sleep |
| **Standard** | $25/mês | 2GB RAM, auto-scaling |

Para produção com mais tráfego, considere o plano Starter ($7/mês).
