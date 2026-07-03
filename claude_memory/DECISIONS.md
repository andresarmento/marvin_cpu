# DECISIONS — MaRVin CPU

Racional técnico por trás de escolhas de design que não são óbvias só lendo
o RTL final. Formato livre, um item por decisão.

## Por que fsm1 precisava de um estado `S_WAIT` dedicado

A ROM (`marvin_rom.v`) usa leitura síncrona registrada:
`always @(posedge clk) rdata <= rom[addr];`. Isso significa que o endereço
aplicado no ciclo N só produz dado válido em `rdata` **depois** do próximo
`posedge` (ciclo N+1).

Se a FSM tentasse capturar `IR <= mem_rdata` no mesmo edge em que `S_FETCH`
termina (fundindo fetch+captura em um único estado), pela semântica de
non-blocking assignment do Verilog o `IR` pegaria o valor **antigo** de
`mem_rdata` (do ciclo anterior, potencialmente lixo ou instrução errada),
porque a atualização de `rdata` pela ROM e a leitura de `mem_rdata` pela CPU
acontecem no mesmo edge, em paralelo, sem ordem garantida entre módulos.

Por isso o fsm1 usava 3 estados: `S_FETCH` (aplica `PC` em `mem_addr`),
`S_WAIT` (um ciclo inteiro de folga para `mem_rdata` estabilizar), `S_EXECUTE`
(captura `IR` e already-avançado). 3 ciclos por instrução.

## Por que fsm2/fsm3 conseguiram reduzir para 2 estados/ciclos

fsm2 introduziu handshake **valid/ready** explícito: a CPU levanta
`mem_valid` e só avança quando a ROM responde `mem_ready`. Isso não elimina
a latência física de 1 ciclo da ROM, mas move a responsabilidade de "esperar
o tempo certo" para fora da contagem de estados da FSM — em vez de um estado
`S_WAIT` fixo, a CPU faz polling de `mem_ready` dentro do próprio
`S_FETCH`. fsm3 só limpa a estrutura do código (one-hot com auto-loop
implícito no `case`), mas o comportamento em ciclos é o mesmo de fsm2: ainda
são 2 ciclos de relógio consumidos por `S_FETCH` na prática (a ROM tem
`ready <= valid`, ou seja, ready-latency fixo de 1 ciclo), só que agora isso
é modelado como "ficar no mesmo estado até ready" em vez de um estado
nomeado à parte.

**Importante**: o protocolo valid/ready aqui não compra latência variável de
verdade (a ROM sempre responde em exatamente 1 ciclo) — é mais uma escolha
de estilo/extensibilidade (preparar a interface para uma memória real com
latência variável no futuro, ex. cache miss) do que uma otimização de
desempenho no estado atual do projeto.

## Caminho para reduzir para 1 ciclo por instrução (não feito ainda)

Duas opções, ambas com tradeoffs que o usuário ainda não decidiu:

1. **Memória combinacional** (`assign rdata = rom[addr];` em vez de
   registrada) — dado disponível no mesmo ciclo em que o endereço é
   aplicado. Mais simples, mas não reflete uma SRAM/BRAM real de FPGA (BRAMs
   normalmente exigem saída registrada para timing).
2. **Prefetch/pipeline**: buscar a próxima instrução durante o `S_EXECUTE`
   da instrução atual, sobrepondo fetch e execute. Mais realista para uma
   CPU pipelined, mas complica desvios (JAL/BEQ invalidam o prefetch) — e o
   projeto ainda nem tem controle de fluxo implementado (ver `TODO.md`).

Ainda não há decisão tomada sobre qual caminho seguir; registrar aqui quando
o usuário escolher.

## Caminho absoluto hardcoded em `HEX_FILES_PATH`

`rtl/marvin_rom.v` define
`` `define HEX_FILES_PATH "C:/Users/andre/Downloads/PROJECTS/marvin_cpu/sw/" ``
— funciona apenas na máquina/pasta atual do usuário. Não foi um problema até
agora porque é projeto pessoal single-machine, mas quebra se o repo for
clonado em outro lugar. Listado em `TODO.md`, não uma decisão definitiva
ainda.
