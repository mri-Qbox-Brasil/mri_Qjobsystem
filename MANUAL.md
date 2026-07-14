# mri_Qjobsystem — Manual

Criador de jobs e gangs em jogo: cria os grupos no `qbx_core`, define cargos e salários, e coloca no mundo os pontos de bater ponto, cofre, alarme, boss menu, bancadas de crafting e lojas — tudo sem editar arquivo nem reiniciar o servidor.

---

## Sumário

1. [Dependências](#dependências)
2. [Instalação](#instalação)
3. [Permissões (ACE)](#permissões-ace)
4. [Configuração](#configuração)
5. [Comandos](#comandos)
6. [Criando um grupo](#criando-um-grupo)
7. [Menu de gerenciamento](#menu-de-gerenciamento)
8. [Estrutura de um grupo](#estrutura-de-um-grupo)
9. [Craftings e lojas](#craftings-e-lojas)
10. [Cofre do grupo](#cofre-do-grupo)
11. [Permissões de cargo](#permissões-de-cargo)
12. [Persistência e backup](#persistência-e-backup)
13. [Segurança dos eventos](#segurança-dos-eventos)
14. [Integrações](#integrações)
15. [Entrypoints para outros recursos](#entrypoints-para-outros-recursos)
16. [Localização](#localização)
17. [Estrutura de arquivos](#estrutura-de-arquivos)

---

## Dependências

| Recurso | Obrigatório | Observação |
|---|---|---|
| `qbx_core` | Sim | Declarado em `dependencies`. Os grupos são registrados via `exports.qbx_core:CreateJobs` e `CreateGangs` |
| `ox_lib` | Sim | Menus de contexto, `inputDialog`, `alertDialog`, `progressCircle`, callbacks, locale e comandos |
| `oxmysql` | Sim | Persistência dos grupos na tabela `mri_qjobsystem` |
| `mri_Qbox` | Sim | Declarado em `dependencies`. Fornece `GlobalState.UIColors`, usado na cor dos itens do menu |
| `ox_inventory` | Sim | Lojas (`RegisterShop`, `openInventory`) e baús dos grupos. É o inventário padrão do `BRIDGE` |
| `ox_target` | Sim | Pontos interativos no mundo. Alternativas configuráveis no `BRIDGE` |
| `qbx_management` | Não | Boss menu e a aba de permissões de cargo. Sem ele, o boss menu não abre e os itens de permissão não aparecem |
| `ps-dispatch` | Não | Necessário apenas para o ponto de alarme, que chama `exports["ps-dispatch"]:CustomAlert` |

---

## Instalação

1. Copie a pasta `mri_Qjobsystem` para `resources/`.
2. Adicione ao `server.cfg`:
   ```
   ensure mri_Qjobsystem
   ```
3. A tabela é criada automaticamente no start do recurso:
   ```sql
   CREATE TABLE IF NOT EXISTS `mri_qjobsystem` (
       `jobs` longtext
   ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
   ```
   Na primeira execução, se a tabela estiver vazia, o conteúdo de `server/jobs.json` é carregado e gravado no banco. A partir daí **o banco é a fonte da verdade** — o `jobs.json` só serve como seed inicial.
4. **Conflito com os jobs do `qbx_core`** — os grupos criados aqui são registrados em runtime por cima dos definidos em `qbx_core/shared/jobs.lua` e `gangs.lua`. Um grupo com o mesmo nome nos dois lugares será sobrescrito pelo deste recurso a cada start.

---

## Permissões (ACE)

Os dois comandos são restritos.

```
add_ace group.admin command.createjob allow
add_ace group.admin command.open_jobs allow
```

O gate real está no `lib.addCommand` (`restricted = 'group.admin'`). Do lado do servidor, os eventos de escrita passam por `CanTrustPlayer` (anti-trigger externo) e por `IsPlayerHasCustomPerms`, que na versão atual **sempre retorna `true`** — é o ponto de extensão previsto pelo autor caso você queira uma checagem de permissão própria além do ACE do comando.

---

## Configuração

### `config.lua`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `Config.DefaultDataJob` | tabela | Sim | Esqueleto de um grupo novo. Não precisa ser alterado |
| `Config.DEFAULT_ANIM` | string | Sim | Animação usada no crafting quando o item não define uma própria. Padrão: `hack_loop` |
| `Config.DEFAULT_ANIM_DIC` | string | Sim | Dicionário da animação padrão. Padrão: `mp_prison_break` |
| `Config.BlacklistedStrings` | lista de strings | Sim | Trechos proibidos nos nomes digitados no criador (armas, drogas, dinheiro...). Vem **vazio** por padrão — a lista sugerida está comentada no arquivo |
| `Config.jobTypeList` | lista | Sim | Tipos de job oferecidos no criador (`leo`, `ems`, `mechanic`, `realestate`, sem tipo). O tipo alimenta o `job.type` do `qbx_core`, usado por outros recursos (dispatch, HUD, etc.) |
| `Config.DirectoryToInventoryImages` | string | Sim | Caminho NUI das imagens dos itens. Padrão: `nui://ox_inventory/web/images/` |

O `config.lua` também define, no client, as funções `openBossmenu` (chama `exports.qbx_management:OpenBossMenu`) e `SendDispatch` (chama `exports["ps-dispatch"]:CustomAlert` para a job `police`). É aí que se troca o recurso de dispatch ou a lista de jobs alertadas.

### `BRIDGE/config.lua`

Camada de compatibilidade com outros frameworks e inventários.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `BRIDGE.Framework` | `"QB"` \| `"ESX"` \| `"OX"` | Sim | Framework do servidor. Padrão: `QB` (QBox/QBCore) |
| `BRIDGE.Inventory` | `"ox_inventory"` \| `"qb_inventory"` \| `"quasar_inventory"` | Sim | Inventário. Padrão: `ox_inventory`. Note que as lojas usam `exports.ox_inventory` diretamente, então trocar o inventário quebra as lojas |
| `BRIDGE.Target` | `"ox_target"` \| `"qb_target"` | Sim | Recurso de target. Padrão: `ox_target` |
| `BRIDGE.UseMarkers` | bool | Sim | Usa markers no lugar do target. Padrão: `false` |
| `BRIDGE.ESXOld` | bool | Sim | Só relevante em ESX antigo |
| `BRIDGE.QBStashesReplaceByPLS` | bool | Sim | Substitui os stashes do `qb-inventory`. Padrão: `false` |

---

## Comandos

| Comando | Permissão | Descrição |
|---|---|---|
| `/createjob` | `group.admin` | Abre o assistente de criação de um novo grupo (job ou gang) |
| `/open_jobs` | `group.admin` | Abre o menu de gerenciamento com todos os grupos existentes |

---

## Criando um grupo

`/createjob` abre um assistente em etapas:

1. **Título** — nome exibido (ex.: `Polícia`).
2. **Código do grupo** — identificador interno, sempre minúsculo (ex.: `police`). Se já existir um job com esse código no `qbx_core`, a criação é recusada.
3. **Tipo** — `Job` (com salário e ponto) ou `Gang` (sem salário e sem ponto).
4. **Quantidade de cargos**.
5. Para jobs: o **tipo de trabalho** (`leo`, `ems`, `mechanic`, `realestate` ou sem tipo).
6. Um formulário por cargo, do índice `0` até `n-1`, com nome e — no caso de job — salário.

O **último cargo criado recebe automaticamente `isboss` e `bankAuth`**. As coordenadas do personagem no momento da criação são salvas como `coords` do grupo. Ao final, o menu de gerenciamento abre.

---

## Menu de gerenciamento

`/open_jobs` lista todos os grupos. Ao escolher um, as opções são:

| Opção | O que faz |
|---|---|
| Renomear | Altera o `label` do grupo |
| Cargos | Gerencia hierarquia, nomes e salários |
| Local para Bater Ponto | Define/remove o ponto de duty na posição da mira |
| Ponto batido por padrão | Liga/desliga `defaultDuty` (entra em serviço automaticamente ao logar) |
| Caixa registradora | Define/remove o ponto do cofre do grupo |
| Alarme | Define/remove o ponto de alarme (aciona o dispatch) |
| Bossmenu | Define/remove o ponto do boss menu |
| Craftings/Lojas | Abre o submenu de bancadas e lojas |
| Excluir grupo | Remove o grupo |
| Atualizar para MIM | Recarrega os pontos apenas para quem está no menu |
| Atualizar para TODOS | Recarrega os pontos para todos os jogadores online |
| Backup | Cria ou restaura o `server/backup.json` |

As posições dos pontos são capturadas por raycast (onde você está mirando), não pela posição do personagem.

Depois de qualquer alteração, use **Atualizar para TODOS** para os pontos aparecerem para quem já está conectado — os dados são salvos na hora, mas os targets no mundo só são recriados no pull.

---

## Estrutura de um grupo

Cada grupo é um objeto no JSON persistido. Campos usados pelo código:

| Campo | Tipo | Descrição |
|---|---|---|
| `label` | string | Nome exibido |
| `job` | string | Código do grupo (minúsculo) |
| `type` | `"job"` \| `"gang"` | Define se vai para `CreateJobs` ou `CreateGangs` |
| `jobtype` | string | Tipo do job no `qbx_core` (`leo`, `ems`, ...). Só para jobs |
| `grades` | objeto | Cargos indexados por número, com `name`, `payment`, `isboss`, `bankAuth`, `isrecruiter` |
| `defaultDuty` | bool | Entra em serviço por padrão |
| `balance` | number | Saldo do cofre do grupo |
| `coords` | `{x,y,z}` | Posição onde o grupo foi criado |
| `duty` | `{x,y,z}` | Ponto de bater ponto |
| `register` | `{x,y,z}` | Ponto do cofre |
| `alarm` | `{x,y,z}` | Ponto do alarme |
| `bossmenu` | `{x,y,z}` | Ponto do boss menu |
| `craftings` | lista | Bancadas e lojas (veja abaixo) |
| `stashes` | lista | Baús do grupo (`id`, `label`, `slots`, `weight`, `coords`). Registrados no inventário no start; não são editáveis pelo menu nesta versão |

O cargo de maior índice é sempre forçado a `isboss` e `bankAuth` no carregamento (`decodeGrades`), independentemente do que estiver salvo.

---

## Craftings e lojas

Um item de `craftings` vira uma bancada **ou** uma loja, dependendo do ícone escolhido:

- Ícone `fa-solid fa-screwdriver-wrench` (padrão) — **bancada de crafting**: abre um menu com as receitas, mostra os ingredientes necessários, pede a quantidade, roda a barra de progresso com animação e consome os itens no servidor.
- Qualquer outro ícone — **loja**: abre o `ox_inventory` no modo `shop`. A loja é registrada no start via `exports.ox_inventory:RegisterShop`, usando o primeiro ingrediente do item como moeda e preço.

Cada bancada/loja pode ser marcada como `public` — nesse caso qualquer jogador pode usar. Caso contrário, só quem estiver na job ou gang dona do ponto.

Cada item de crafting aceita `duration` (segundos por unidade), `animation` (`dict`/`anim`, ou `scully` para usar um emote via `/e`), `stockAmount`, `license`, `grade` e `metadata`.

---

## Cofre do grupo

O ponto "Caixa registradora" abre um menu com o saldo do grupo e as opções de retirar e depositar. O saldo fica no campo `balance` do grupo e é validado no servidor: não é possível sacar mais do que há no cofre nem depositar mais dinheiro do que o jogador tem.

Só quem está na job ou gang dona do ponto consegue abrir.

---

## Permissões de cargo

Com o `qbx_management` instalado, o recurso adiciona um item "Gerenciar Permissões" no boss menu de jobs e de gangs (`AddBossMenuItem` / `AddGangMenuItem`). Ele abre um menu onde se alternam as flags de cada cargo (`isboss`, `bankAuth`, `isrecruiter`).

Ao mudar uma flag, o servidor grava a alteração e **reaplica o grupo a todos os personagens naquele cargo** (consultando `player_groups` e chamando `SetPlayerPrimaryJob` / `SetPlayerPrimaryGang`), para que a permissão passe a valer sem precisar relogar. A flag `isboss` do cargo mais alto é bloqueada — não dá para remover o líder.

---

## Persistência e backup

- Todos os grupos ficam em uma única linha da tabela `mri_qjobsystem`, na coluna `jobs` (JSON).
- `server/jobs.json` é apenas o seed usado quando a tabela está vazia.
- **Backup** grava o estado atual em `server/backup.json` (sobrescrevendo o anterior). **Restaurar** lê esse arquivo e o grava de volta no banco. Confira se o `backup.json` não está vazio antes de restaurar.

---

## Segurança dos eventos

Os eventos de escrita não são disparados com `TriggerServerEvent` direto: o client usa `TriggerSecureEvent`, que primeiro registra um token temporário no servidor (`secure.lua`). No servidor, cada handler chama `CanTrustPlayer(src)`, que só aceita a chamada se o token tiver sido gerado há menos de 1 segundo. Isso bloqueia eventos disparados por executores externos.

Não é substituto de checagem de permissão: quem passa pelo `CanTrustPlayer` ainda depende do `IsPlayerHasCustomPerms`, que por padrão libera todo mundo. Se o seu servidor expõe o cliente a executores, implemente a checagem em `IsPlayerHasCustomPerms` (`server/server.lua`).

---

## Integrações

### qbx_core

Os grupos são registrados em runtime com `exports.qbx_core:CreateJobs` e `exports.qbx_core:CreateGangs` a cada carregamento. O client também espelha o job atual nos statebags `jobName`, `jobType` e `jobGrade` do jogador, atualizados no login e em `QBCore:Client:OnJobUpdate`.

### qbx_management

Fornece o boss menu (`OpenBossMenu`) aberto pelo ponto "Bossmenu", e recebe o item de gerenciamento de permissões de cargo. Se o recurso não estiver iniciado, o registro dos itens é simplesmente pulado.

### ox_inventory

Registra as lojas (`RegisterShop`) e os baús dos grupos (`BRIDGE.RegisterStash`) no start, e abre a loja no ponto correspondente.

### ps-dispatch

O ponto de alarme dispara `exports["ps-dispatch"]:CustomAlert` para a job `police`, com a posição do jogador e o nome do grupo. Para trocar o dispatch ou as jobs alertadas, edite a função `SendDispatch` em `config.lua`.

### mri_Qbox

O client lê `GlobalState.UIColors` para colorir os itens do menu (verde para ativo, vermelho para inativo).

---

## Entrypoints para outros recursos

### Exports

```lua
-- true se o cargo do jogador tem a flag isboss
-- groupType: 'job' | 'gang' | data: PlayerData
exports.mri_Qjobsystem:CheckPlayerIsbossByJobSystemData('job', QBX.PlayerData)

-- true se o cargo do jogador tem a flag isrecruiter
exports.mri_Qjobsystem:CheckPlayerIrecruiterByJobSystemData('gang', QBX.PlayerData)

-- ordena uma lista de opções de menu pelo número entre colchetes no título
exports.mri_Qjobsystem:SortByTitleIndex(options)
```

### Callback de saldo

```lua
-- saldo do cofre do grupo
local balance = lib.callback.await('mri_Qjobsystem:server:getBalance', 100, 'police')
```

### Eventos de client

```lua
-- abre o assistente de criação (o comando /createjob dispara este evento)
TriggerClientEvent('mri_Qjobsystem:client:createjob', source)

-- abre o menu de gerenciamento; recebe a lista de grupos
TriggerClientEvent('mri_Qjobsystem:client:openJobMenu', source, Jobs)

-- envia a lista de grupos e recria os pontos no mundo
TriggerClientEvent('mri_Qjobsystem:client:Pull', -1, Jobs)
```

Os eventos de escrita no servidor (`saveNewJob`, `saveJob`, `deleteJob`, `createItem`, `makeRegisterAction`, `createBackup`, `setBackup`, `pullChanges`) exigem o token do `TriggerSecureEvent` e não funcionam com `TriggerServerEvent` comum.

---

## Localização

As strings dos itens de permissão no boss menu são traduzidas via `ox_lib` locale. Os arquivos ficam em `locales/`:

- `en.json` — inglês
- `pt-br.json` — português do Brasil

O locale ativo é definido pela convar `ox:locale` no `server.cfg`:

```
setr ox:locale "pt-br"
```

O restante dos textos dos menus está escrito direto no Lua, em português.

---

## Estrutura de arquivos

```
mri_Qjobsystem/
├── client/
│   ├── client.lua        — cria os pontos no mundo (crafting, duty, cofre, alarme, bossmenu) e o menu de crafting
│   ├── creation.lua      — assistente /createjob e todo o menu de gerenciamento, incluindo permissões de cargo
│   └── utilities.lua     — exports de checagem de boss/recruiter e ordenação de menus
├── server/
│   ├── server.lua        — carrega os grupos, registra em qbx_core, eventos de CRUD, cofre, backup e comandos
│   ├── db.lua            — queries oxmysql (tabela mri_qjobsystem e leitura de player_groups)
│   ├── jobs.json         — seed inicial dos grupos (usado só quando a tabela está vazia)
│   └── backup.json       — backup gerado pelo menu
├── BRIDGE/
│   ├── config.lua        — framework, inventário, target e markers
│   ├── client/
│   │   ├── inventory.lua — itens, contagem e stash no client
│   │   └── target.lua    — sphere zones e model targets (ox_target / qb_target / markers)
│   └── server/
│       ├── framework.lua — player data, job/gang, dinheiro da society, item usável
│       └── inventory.lua — add/remove item, registrar e limpar stash, drops
├── secure.lua            — token anti-trigger externo (TriggerSecureEvent / CanTrustPlayer)
├── config.lua            — animações, tipos de job, blacklist, bossmenu e dispatch
├── locales/
│   ├── en.json
│   └── pt-br.json
└── fxmanifest.lua
```
