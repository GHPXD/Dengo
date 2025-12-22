# 🦟 DenguePredict

[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Aplicativo multiplataforma (Android/iOS/Web) de Saúde Pública para previsão de casos de dengue usando Inteligência Artificial.**

Desenvolvido como Trabalho de Conclusão de Curso (TCC), o DenguePredict combina tecnologia de ponta com impacto social, oferecendo previsões epidemiológicas precisas e visualizações interativas para conscientização pública.

---

## 📋 Índice

- [Sobre o Projeto](#-sobre-o-projeto)
- [Tecnologias](#-tecnologias)
- [Arquitetura](#-arquitetura)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Instalação](#-instalação)
- [Executando o Projeto](#-executando-o-projeto)
- [Features](#-features)
- [Screenshots](#-screenshots)
- [Roadmap](#-roadmap)
- [Contribuindo](#-contribuindo)
- [Licença](#-licença)

---

## 🎯 Sobre o Projeto

O **DenguePredict** é um aplicativo de saúde pública que utiliza modelos de Machine Learning para prever casos de dengue em diferentes regiões. O objetivo é fornecer informações acessíveis e visuais para:

- 🏥 **Gestores de Saúde Pública**: Tomada de decisão baseada em dados
- 👨‍👩‍👧‍👦 **População Geral**: Conscientização sobre riscos locais
- 📊 **Pesquisadores**: Análise de tendências epidemiológicas

### Diferenciais Técnicos

✅ **Clean Architecture** rigorosa (separação de camadas Domain, Data, Presentation)  
✅ **Programação Funcional** com tratamento de erros via `Either<Failure, Success>`  
✅ **Cache Offline** com Hive para funcionalidade sem internet  
✅ **UI/UX Profissional** seguindo princípios de HealthTech moderno  
✅ **Code Generation** (Riverpod, Freezed, JsonSerializable)  

---

## 🛠 Tecnologias

### Framework e Linguagem
- **Flutter** 3.24+ (Multiplataforma)
- **Dart** 3.5+ (Null Safety)

### Gerenciamento de Estado
- **Riverpod** 2.6+ (com Code Generation)

### Navegação
- **GoRouter** 14.6+ (Rotas tipadas e declarativas)

### Networking
- **Dio** 5.7+ (HTTP client com interceptors)
- **Connectivity Plus** 6.1+ (Detecção de conectividade)

### Modelagem e Serialização
- **Freezed** 2.5+ (Imutabilidade e pattern matching)
- **JsonSerializable** 6.8+ (Parsing automático de JSON)

### Armazenamento Local
- **Hive** 2.2+ (Banco NoSQL rápido)
- **Shared Preferences** 2.3+ (Configurações simples)

### Visualização de Dados
- **FL Chart** 0.69+ (Gráficos interativos)
- **Flutter Map** 7.0+ (Mapas com OpenStreetMap)

### UI/UX
- **Google Fonts** 6.2+ (Tipografia Montserrat)
- **Flutter SVG** 2.0+ (Ícones vetoriais)
- **Lottie** 3.1+ (Animações JSON)
- **Shimmer** 3.0+ (Skeleton loading)

### Utilidades
- **Dartz** 0.10+ (Programação funcional - Either)
- **Equatable** 2.0+ (Comparação de objetos)
- **Logger** 2.4+ (Logging estruturado)

---

## 🏗 Arquitetura

O projeto segue os princípios da **Clean Architecture** de Robert C. Martin, adaptada para Flutter:

```
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION                         │
│  (UI, Widgets, Screens, Providers - Riverpod)          │
└─────────────────────────────────────────────────────────┘
                        ↓ ↑
┌─────────────────────────────────────────────────────────┐
│                       DOMAIN                            │
│  (Entities, UseCases, Repository Contracts)             │
│  ⚠️ SEM dependências de Flutter/bibliotecas externas    │
└─────────────────────────────────────────────────────────┘
                        ↓ ↑
┌─────────────────────────────────────────────────────────┐
│                        DATA                             │
│  (Models, Repositories Impl, DataSources - API/Cache)   │
└─────────────────────────────────────────────────────────┘
```

### Princípios Aplicados
- **Dependency Inversion**: Camadas internas não dependem de externas
- **Single Responsibility**: Cada classe tem uma única responsabilidade
- **Interface Segregation**: Contratos (abstrações) no Domain
- **Testability**: Injeção de dependência facilita testes unitários

---

## 📂 Estrutura do Projeto

```
lib/
├── core/                          # Funcionalidades compartilhadas
│   ├── config/                    # Configurações globais (URLs, Timeouts)
│   ├── theme/                     # Tema visual (cores, tipografia)
│   ├── errors/                    # Classes de Failure
│   ├── constants/                 # Constantes da aplicação
│   ├── utils/                     # Helpers e extensões
│   └── network/                   # Configuração Dio e interceptors
│
├── features/                      # Features modularizadas
│   ├── onboarding/
│   │   ├── data/
│   │   │   ├── datasources/       # API e Cache
│   │   │   ├── models/            # DTOs com Freezed
│   │   │   └── repositories/      # Implementações concretas
│   │   ├── domain/
│   │   │   ├── entities/          # Objetos de negócio puros
│   │   │   ├── repositories/      # Contratos (abstrações)
│   │   │   └── usecases/          # Regras de negócio
│   │   └── presentation/
│   │       ├── providers/         # Riverpod Providers
│   │       ├── screens/           # Telas principais
│   │       └── widgets/           # Componentes reutilizáveis
│   │
│   ├── dashboard/                 # Dashboard principal com gráficos
│   ├── prediction/                # Feature de previsão com IA
│   ├── heatmap/                   # Mapa de calor interativo
│   └── education/                 # Feed educativo sobre prevenção
│
└── main.dart                      # Entry point da aplicação

assets/
├── images/                        # Ilustrações e logos
├── icons/                         # Ícones customizados
└── fonts/                         # Fontes locais (se necessário)

test/
├── core/                          # Testes do core
└── features/                      # Testes por feature
```

---

## ⚙️ Instalação

### Pré-requisitos

- Flutter SDK 3.24+ ([Instalação](https://flutter.dev/docs/get-started/install))
- Dart 3.5+
- Android Studio / Xcode (para emuladores)
- VS Code com extensões Flutter/Dart (recomendado)

### Passos

1. **Clone o repositório**
```powershell
git clone https://github.com/seu-usuario/dengue-predict.git
cd dengue-predict
```

2. **Instale as dependências**
```powershell
flutter pub get
```

3. **Execute os code generators**
```powershell
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **Verifique a instalação**
```powershell
flutter doctor
```

---

## 🚀 Executando o Projeto

### Modo Debug (Android/iOS)
```powershell
flutter run
```

### Modo Release (Build Otimizado)
```powershell
flutter run --release
```

### Web
```powershell
flutter run -d chrome
```

### Executar Testes
```powershell
flutter test
```

---

## ✨ Features

### 🎯 Implementadas
- ✅ Estrutura de pastas Clean Architecture
- ✅ Tema profissional "Modern HealthTech"
- ✅ Configuração de dependências state-of-the-art
- ✅ Sistema de tratamento de erros funcional

### 🚧 Em Desenvolvimento
- 🔄 Onboarding com seleção de cidade
- 🔄 Dashboard com gráficos interativos
- 🔄 Integração com API de previsão de IA
- 🔄 Mapa de calor epidemiológico
- 🔄 Feed educativo sobre prevenção

### 🔮 Roadmap Futuro
- 📍 Notificações push para alertas de surto
- 🌙 Tema escuro (acessibilidade)
- 🌍 Internacionalização (i18n)
- 📊 Exportação de relatórios em PDF

---

## 🤝 Contribuindo

Este é um projeto de TCC, mas feedbacks e sugestões são bem-vindos!

1. Faça um Fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/NovaFeature`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova feature X'`)
4. Push para a branch (`git push origin feature/NovaFeature`)
5. Abra um Pull Request

---

## 📄 Licença

Distribuído sob a licença MIT. Veja `LICENSE` para mais informações.

---

## 👨‍💻 Autor

**Seu Nome**  
📧 seu.email@exemplo.com  
🔗 [LinkedIn](https://linkedin.com/in/seu-perfil)  
🐙 [GitHub](https://github.com/seu-usuario)

---

## 🙏 Agradecimentos

- Orientador(a) do TCC: Prof. [Nome]
- Comunidade Flutter Brasil
- Datasets públicos de saúde (Ministério da Saúde, OMS)

---

<div align="center">
  <sub>Feito com ❤️ e Flutter para salvar vidas 🦟</sub>
</div>
#   D e n g o  
 