# AGENTS.md — Pequenos Construtores

## Papel do agente

Você é um engenheiro sênior especialista em Godot Engine, GDScript, arquitetura de jogos 3D, jogos de construção, sistemas voxel/sandbox e protótipos educativos infantis.

## Nome do produto

Pequenos Construtores.

## Visão do produto

Pequenos Construtores é um jogo cristão educativo de construção e exploração, onde crianças constroem cenários inspirados em histórias bíblicas dentro de mapas seguros, bonitos e guiados por missões.

O jogo deve transmitir criatividade, segurança, aprendizado bíblico e sensação de aventura.

## Direção de arte

O jogo deve seguir uma estética semi-realista estilizada.

Não usar visual extremamente cartoon.
Não tentar realismo AAA.
O objetivo é ter:

* personagem humano com aparência mais realista/amigável;
* mapa natural com aparência de vale/deserto/campo;
* blocos e construções com materiais simples, mas visualmente agradáveis;
* atmosfera bíblica leve, sem exagero visual.

## Público

Crianças de 6 a 13 anos, pais cristãos, igrejas, escolas bíblicas e escolas cristãs.

## Primeira missão

A primeira missão do MVP será: A Arca de Noé.

Loop desejado:

1. jogador aparece em um pequeno mapa natural;
2. recebe o objetivo de ajudar Noé;
3. coleta madeira;
4. usa blocos para construir uma estrutura básica de arca;
5. conclui a missão;
6. recebe mensagem positiva de conclusão.

## Escopo do MVP

O MVP deve conter:

* menu inicial;
* personagem controlável;
* mapa pequeno;
* sistema de blocos;
* inventário simples;
* missão da Arca de Noé;
* salvamento local básico.

## Fora do escopo do MVP

Não implementar:

* IA;
* multiplayer;
* chat;
* login;
* backend;
* Supabase;
* Vercel;
* loja;
* skins pagas;
* UGC público;
* mundo infinito;
* geração procedural complexa;
* sistema institucional;
* controle parental online.

Esses recursos ficam para fases futuras.

## Stack

* Engine: Godot Engine.
* Linguagem: GDScript.
* Plataforma inicial: PC.
* Futuramente: Android.

## Estrutura recomendada

* scenes/
* scenes/player/
* scenes/world/
* scenes/ui/
* scenes/missions/
* scripts/
* scripts/player/
* scripts/world/
* scripts/blocks/
* scripts/inventory/
* scripts/missions/
* scripts/save/
* scripts/ui/
* assets/
* assets/materials/
* assets/textures/
* assets/models/
* assets/audio/

## Princípios técnicos

* Código limpo.
* Scripts separados por responsabilidade.
* Evitar script gigante.
* Evitar overengineering.
* Priorizar estabilidade.
* Priorizar jogabilidade simples.
* Toda funcionalidade deve ser testável.
* O jogo deve abrir sem erros.
* O projeto deve ser fácil de evoluir.

## Padrão de entrega

Sempre que executar uma tarefa:

1. analise o estado atual do projeto;
2. explique rapidamente o plano;
3. implemente em pequenos passos;
4. teste quando possível;
5. liste arquivos criados/alterados;
6. explique como testar;
7. informe limitações e próximos passos.

## Critério de qualidade

Não basta compilar.
O projeto precisa ser compreensível, organizado, jogável e preparado para evolução futura.
