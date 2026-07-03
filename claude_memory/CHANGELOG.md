# CHANGELOG — MaRVin CPU

Reconstruído a partir do histórico do git local (`git log`). Mantém o
racional técnico de cada etapa, não só o "o quê" (que já está no diff).

## `00_fsm3` — Collapse fetch and wait states (2026-07-03)

Elimina o estado `S_WAIT` separado que existia em fsm2. A espera pela
latência da ROM (1 ciclo, protocolo valid/ready) passa a ser tratada dentro
do próprio estado `S_FETCH`, via `case (1'b1)` one-hot: a FSM só sai de
`S_FETCH` quando `mem_ready` está ativo. Na prática ainda são 2 ciclos de
relógio por causa da latência real da memória (comentário no código:
"Now this state consumes two cycles"), mas o **número de estados** da FSM
caiu de 3 (fsm1) para 2 (fsm2/fsm3).
`dbg_x1` (saída de debug de `regFile[1]`) foi trocado por `dbg_IR` (expõe o
registrador de instrução em vez de um registrador do banco).
ROM: `sw/00_fsm1.hex` → `sw/00_fsm3.hex`.

## `00_fsm2` — one hot FSM with valid-ready (2026-07-03)

Reescreve a FSM de estados sequenciais (`S_FETCH`/`S_WAIT`/`S_EXECUTE` com
`localparam` 2'd0/1/2) para **one-hot** (`S_FETCH`/`S_EXECUTE` como bits
independentes, `state[S_FETCH_bit]`/`state[S_EXECUTE_bit]`). Introduz
protocolo **valid/ready** entre CPU e ROM (`mem_valid`/`mem_ready`) no lugar
de um handshake implícito por contagem de ciclos fixa. A `Marvin_ROM` passa
a ter `ready <= valid` (ready-latency fixo de 1 ciclo) e só registra
`rdata` quando `valid` está ativo.

## readme corrections ×3 (2026-07-03)

Ajustes de texto no `README.md` (sem mudança de RTL).

## first commit - fsm 1st version (2026-07-03)

Versão inicial (`00_fsm1`): FSM sequencial de 3 estados
(`S_FETCH → S_WAIT → S_EXECUTE`), sem handshake valid/ready — a espera pela
ROM (1 ciclo de latência, leitura síncrona simples `rdata <= rom[addr]`) é
resolvida com um estado `S_WAIT` dedicado só para dar tempo ao dado de ficar
estável antes de `IR <= mem_rdata`. Ver `DECISIONS.md` para o racional de
por que esse estado extra era necessário nessa versão (semântica de
non-blocking assignment). 3 ciclos por instrução.
