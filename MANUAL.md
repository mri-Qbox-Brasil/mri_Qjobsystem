# MANUAL - mri_Qjobsystem

## O que o recurso faz
Sistema completo de gerenciamento de empregos (jobs) e gangues para servidores FiveM baseados no framework MRI Qbox, permitindo controle hierárquico de cargos, gerenciamento via tablet, restrições de acesso a roupas e zonas de trabalho, com integração nativa à suite MRI Qbox.

## Funcionalidades principais
- Gerenciamento completo de jobs e gangues com hierarquia de grades (cargos) e salários
- Tablet de gerenciamento exclusivo para bosses e recrutadores realizarem gestão de membros
- Salas de roupas específicas por job/gang com restrição de acesso por cargo
- Zonas de trabalho com blips e marcações no mapa para identificação visual
- Sistema de bridge para compatibilidade com frameworks QBCore e QBX
- Suporte a múltiplos idiomas via arquivos de tradução JSON na pasta `locales/`
- Proteção de dados sensíveis via módulo `secure.lua`

## Como funciona (fluxo de trabalho)
1. Jobs e gangues são definidos no `config.lua` com hierarquia de cargos, salários e permissões de acesso
2. Jogadores ao ingressar em um job/gang têm seu cargo sincronizado via eventos server-client
3. Bosses e recrutadores acessam o tablet para adicionar/remover membros, alterar cargos e gerenciar permissões
4. Salas de roupas validam o cargo do jogador para liberar outfits exclusivos
5. Zonas de trabalho exibem blips no mapa para todos os jogadores, com identificação visual do job/gang
6. Atualizações de dados disparam eventos de sincronização automática entre todos os clientes conectados

## Opções de configuração disponíveis
Configurações definidas em `config.lua`:
- **Jobs/Gangs**: Nome, label, hierarquia de grades (nome do cargo, salário, permissões), zonas de trabalho, salas de roupas
- **Zonas de trabalho**: Coordenadas (coords), tipo, configuração de blip (sprite, cor, escala)
- **Salas de roupas**: Outfits por cargo, restrições de acesso
- **Permissões**: Definição de quais cargos têm acesso a funções de boss ou recrutador
- **Bridge**: Configurações de compatibilidade com framework em `BRIDGE/config.lua`

## Comandos disponíveis
| Comando | Descrição | Permissão |
|---------|-----------|-----------|
| `/createjob` | Cria um novo job ou gangue no sistema | Admin |
| `/open_jobs` | Lista todos os jobs e gangues cadastrados | Todos |

## Eventos que dispara/ouve
### Eventos Server
| Evento | Descrição |
|--------|-----------|
| `QBCore:Server:OnJobUpdate` | Disparado automaticamente ao atualizar dados de um job/gang |

### Eventos Client
| Evento | Descrição |
|--------|-----------|
| `QBCore:Client:OnJobUpdate` | Recebe e aplica atualizações de job no client |
| `QBCore:Client:OnGangUpdate` | Recebe e aplica atualizações de gang no client |

## Exports que fornece/consome
### Exports fornecidos (disponíveis para outros recursos)
| Export | Descrição |
|--------|-----------|
| `CheckPlayerIsbossByJobSystemData()` | Verifica se o jogador é boss de um job/gang |
| `CheckPlayerIrecruiterByJobSystemData()` | Verifica se o jogador é recrutador de um job/gang |

### Exports consumidos (depende de outros recursos)
- `BRIDGE/server/framework.lua`: Abstração de funções do framework server-side
- `BRIDGE/client/inventory.lua`: Abstração de funções de inventário client-side
- `BRIDGE/client/target.lua`: Abstração de funções de sistema de target

## Integração com outros recursos MRI Qbox
- `mri_Qmenu`: Realiza verificação de boss/recruiter no menu F9
- `mri_Qdevmenu`: Valida permissões administrativas para gerenciamento de jobs
- `mri_Qbox`: Resource central da suite (dependência obrigatória para funcionamento)

## Casos de uso / exemplos práticos
- Criar a gangue "Polícia Civil" com cargos de Agente, Investigador e Delegado, cada um com salários e permissões diferenciadas
- Configurar sala de roupas para a gangue, onde apenas o Delegado tem acesso ao outfit completo
- Definir zona de trabalho na delegacia com blip no mapa para identificação visual de membros
- Boss da gangue utilizar o tablet para recrutar novos membros e promover agentes a investigadores

## Dicas de solução de problemas
- Atualizações de job/gang não sincronizam: Verifique se o sistema de bridge está configurado corretamente para o framework em uso (QBCore/QBX)
- Tablet não abre para o jogador: Confirme se o jogador possui permissão de boss/recruiter no `config.lua`
- Erros de banco de dados: Execute as migrations SQL fornecidas na pasta do resource
- Traduções faltantes: Adicione o idioma desejado criando um arquivo JSON na pasta `locales/`