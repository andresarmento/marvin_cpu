# TODO — MaRVin CPU

Consolidado a partir do `README.md` da raiz + lacunas identificadas no RTL
atual (`rtl/marvin_cpu.v`, `rtl/marvin_rom.v`). Atualizar conforme o trabalho
avança.

## Curto prazo (do README)

- [ ] Instrução `LUI` (load upper immediate)
- [ ] Instrução `ADDI`

## Decode / Execute (bloqueador para qualquer instrução real)

- [ ] Reintroduzir extração de campos do IR (`opcode`, `rd`, `rs1`, `rs2`,
      `funct3`, `funct7`, imediatos) — existiam em fsm1, foram removidos em
      fsm3 e ainda não voltaram.
- [ ] Lógica de decode (opcode → tipo de instrução: R/I/S/B/U/J)
- [ ] ALU (ADD, SUB, AND, OR, XOR e variantes imediatas ADDI/ANDI/ORI/XORI)
- [ ] Write-back no `regFile` (atualmente só é inicializado, nunca escrito)
- [ ] Geração de imediatos por tipo de instrução (sign-extend conforme
      formato RV32I)

## Controle de fluxo

- [ ] `JAL` (jump and link)
- [ ] `BEQ` (branch if equal)
- [ ] Desvio de `PC` fora do incremento padrão `PC + 4` (hoje só existe
      `PC <= PC + 4` em `S_EXECUTE`, sem mux para destino de salto)

## Memória de dados

- [ ] `LW` (load word)
- [ ] `SW` (store word)
- [ ] Definir se dado e instrução compartilham o mesmo barramento
      valid/ready da `Marvin_ROM` ou se haverá uma RAM de dados separada
      (hoje só existe `Marvin_ROM`, somente leitura, só para instruções)

## FSM / timing

- [ ] Avaliar se vale a pena reduzir de 2 para 1 ciclo por instrução
      simples (ver `DECISIONS.md` — depende de trocar a ROM para leitura
      combinacional ou pipeline com prefetch)
- [ ] Escrever testbench Verilog (hoje a validação é feita só visualmente
      via simulador Digital, `.dig` files em `sim/`)

## Higiene de repo

- [ ] `HEX_FILES_PATH` em `rtl/marvin_rom.v` é um caminho absoluto
      hardcoded do Windows do usuário — trocar por caminho relativo ou
      parametrizar via `+define+` / argumento de simulação
- [ ] Confirmar que `sw/00_fsm1.hex` não é mais necessário (arquivo antigo,
      substituído por `00_fsm3.hex`) e remover se obsoleto

## Roadmap de extensões (do README, longo prazo)

- [ ] `RV32IM` (+8 instruções — mul/div)
- [ ] `RV32IMA` (+11 — atomics)
- [ ] `RV32IMAC` (+34 — compressed, total 93 instruções)
