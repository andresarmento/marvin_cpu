# MaRVin CPU — Memória do Projeto

Memória principal do projeto para uso do Claude Code entre sessões. Ver também
`TODO.md`, `CHANGELOG.md` e `DECISIONS.md` nesta mesma pasta.

## O que é

MaRVin CPU é uma CPU RISC-V RV32I implementada em Verilog, feita do zero pelo
usuário como projeto de aprendizado/hardware. Evolução planejada (ver
`README.md` da raiz):

1. `RV32I` — 40 instruções (fase atual)
2. `RV32IM` — 48 instruções (+8, extensão M — mul/div)
3. `RV32IMA` — 59 instruções (+11, extensão A — atomics)
4. `RV32IMAC` — 93 instruções (+34, extensão C — compressed)

## Estrutura do repo

```
rtl/                RTL principal
  marvin_cpu.v       módulo Marvin_CPU — FSM, PC, IR, regFile
  marvin_rom.v        módulo Marvin_ROM — memória de instruções (síncrona)
sw/                 imagens .hex carregadas via $readmemh na ROM
sim/                arquivos do simulador Digital (.dig) usados para validar a FSM visualmente
docs/               specs oficiais RISC-V (PDFs) + notas de git/markdown
ISA.md              lista de instruções alvo (LUI, ADDI, ANDI, ORI, XORI, ADD,
                    SUB, AND, OR, XOR, JAL, BEQ, LW, SW)
README.md           changelog de alto nível + TODO curto
claude_memory/      esta pasta
```

Repo git local, branch `main`, com remote `origin` (ver [[project_repo_split]]
na memória global — marvin_cpu e marvin (SoC) são repos separados desde
2026-07-01).

## Estado atual do RTL (`rtl/marvin_cpu.v`, `rtl/marvin_rom.v`)

- **Memória de instruções (`Marvin_ROM`)**: leitura **síncrona registrada**,
  1 ciclo de latência, agora com handshake **valid/ready**:
  ```verilog
  always @(posedge clk or negedge rst_n) begin
      if (!rst_n) ready <= 1'b0;
      else begin
          ready <= valid;
          if (valid) rdata <= rom[addr[31:2]];
      end
  end
  ```
  `ready` é `valid` atrasado 1 ciclo — ou seja, o ready-latency é fixo em 1
  ciclo (não é uma memória de latência variável apesar do protocolo
  valid/ready).

- **FSM da CPU**: one-hot, 2 estados (`S_FETCH`, `S_EXECUTE`), usando
  `case (1'b1)` com bits de estado (`state[S_FETCH_bit]` etc.):
  - `S_FETCH`: mantém `mem_valid` ativo; permanece neste estado até
    `mem_ready` ser 1 (auto-loop implícito — o `case` só transiciona quando
    `mem_ready` é verdadeiro). Na prática ainda **consome 2 ciclos de
    relógio** por causa da latência da ROM (comentário no código: `// Now
    this state consumes two cycles`), mas isso não exige mais um estado
    dedicado (`S_WAIT`) — foi "colapsado" dentro de `S_FETCH`.
  - `S_EXECUTE`: `PC <= PC + 4`; volta para `S_FETCH`. **Ainda não decodifica
    nem executa nenhuma instrução real** — não há ALU, não há write-back no
    regFile, não há lógica de desvio (JAL/BEQ). `opcode`/`rd` não são mais
    extraídos do IR nesta versão (foram removidos entre fsm1 e fsm3).
  - Reset assíncrono (`negedge rst_n`) zera `state→S_FETCH`, `PC`, `IR`.

- `dbg_IR` substitui o antigo `dbg_x1` (debug agora expõe o IR, não mais
  `regFile[1]`).

## Convenções observadas no código

- Nomes de módulo em `PascalCase` com prefixo `Marvin_` (`Marvin_CPU`,
  `Marvin_ROM`).
- Sinais de memória seguem convenção valid/ready (não Wishbone/AXI).
- `HEX_FILES_PATH` é uma macro `` `define `` com caminho **absoluto
  hardcoded** do Windows do usuário (`C:/Users/andre/Downloads/...`) —
  frágil se o repo for movido ou usado por outra pessoa/máquina.
- Testes/validação: usuário usa o simulador **Digital** (arquivos `.dig` em
  `sim/`) para visualizar a FSM, não um testbench Verilog tradicional
  (nenhum arquivo `_tb.v` no repo).

## Como ajudar

- Ao propor mudanças na FSM ou na interface de memória, sempre confirmar o
  número de ciclos por instrução resultante e comparar com a versão anterior
  (ver `CHANGELOG.md` — o usuário está iterando deliberadamente sobre esse
  tradeoff: fsm1 → 3 ciclos, fsm2/fsm3 → 2 ciclos efetivos).
- Antes de recomendar algo baseado neste arquivo, confira o RTL atual — o
  usuário está modificando a FSM ativamente e este documento pode ficar
  desatualizado rápido.
