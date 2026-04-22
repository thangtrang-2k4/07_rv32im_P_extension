# Workspace Tree (Simplified)

> Thu gon .git va py-ref-model/venv de tap trung vao cau truc source chinh.

```text
07_rv32im_P_extension/
|-- .agent/
|   -- workflows/
|       -- p_ext_coding.md
|-- .git/
|   |-- hooks/
|   |-- info/
|   |-- logs/
|   |-- objects/
|   |-- refs/
|   |-- HEAD
|   |-- config
|   |-- index
|-- docs/
|   |-- insructions/
|   |   |-- paas_hx.md
|   |   |-- pas_hx.md
|   |   |-- pasa_hx.md
|   |   |-- pm4adda_b.md
|   |   |-- pm4addasu_b.md
|   |   |-- pm4addau_b.md
|   |   |-- pmax_h.md
|   |   |-- pmaxu_h.md
|   |   |-- pmin_h.md
|   |   |-- pminu_h.md
|   |   |-- pmseq_h.md
|   |   |-- pmslt_h.md
|   |   |-- pmsltu_h.md
|   |   |-- pnclip_hs.md
|   |   |-- pnclipi_h.md
|   |   |-- pnclipiu_h.md
|   |   |-- pnclipr_hs.md
|   |   |-- pnclipri_h.md
|   |   |-- pnclipriu_h.md
|   |   |-- pnclipru_hs.md
|   |   |-- pnclipu_hs.md
|   |   |-- psa_hx.md
|   |   |-- psabs_h.md
|   |   |-- psas_hx.md
|   |   |-- psati_h.md
|   |   |-- pssa_hx.md
|   |   -- pusati_h.md
|   |-- P-ext-proposal.adoc
|   -- Preliminary in-progress RISC-V P Extension Version 0.20-draft, 2026-03-25.pdf
|-- instrinsic/
|   -- riscv_p_asm.h
|-- py-ref-model/
|   |-- notebooks/
|   |   -- test.ipynb
|   |-- flow.md
|   |-- note.md
|   -- requirements.txt
|-- refcodes/
|   |-- acorebase.scala
|   |-- alublock.scala
|   |-- fir.c
|   |-- main.c
|   |-- pextalu.scala
|   -- sobel.c
|-- rtl/
|   |-- adder.sv
|   |-- adder_9bit.sv
|   |-- alu.sv
|   |-- alup.sv
|   |-- branch_comparator.sv
|   |-- clock_divider.sv
|   |-- control_logic.sv
|   |-- control_logic_thang.sv
|   |-- data_memory.sv
|   |-- decoder.sv
|   |-- divider.sv
|   |-- forwarding_unit.sv
|   |-- hazard_detection.sv
|   |-- imem.sv
|   |-- immgen.sv
|   |-- immgen_thang.sv
|   |-- multiplier.sv
|   |-- pc.sv
|   |-- pc_selection.sv
|   |-- pipe_reg.sv
|   |-- regfile.sv
|   |-- rv32_pkg.sv
|   |-- rv32_pkg_thang.sv
|   -- rv32imp_pipeline.sv
|-- sim/
|   |-- filelists/
|   |   -- tb_rv32imp_pipeline.f
|   |-- Makefile
|   |-- sim_main.cpp
|   |-- verilated.d
|   -- verilated.o
|-- sw/
|   |-- all_type_test/
|   |-- Filter-Fir/
|   |   |-- link.ld
|   |   |-- Makefile
|   |   |-- pext.c
|   |   |-- pext.elf
|   |   |-- pext.log
|   |   |-- pext_dmem.hex
|   |   |-- pext_goldenb.hex
|   |   |-- pext_goldenw.hex
|   |   |-- pext_imem.hex
|   |   |-- pext_signature.hex
|   |   |-- README.md
|   |   |-- scala.c
|   |   |-- scala.elf
|   |   |-- scala.log
|   |   |-- scala.s
|   |   |-- scala_dmem.hex
|   |   |-- scala_goldenb.hex
|   |   |-- scala_goldenw.hex
|   |   |-- scala_imem.hex
|   |   |-- scala_signature.hex
|   |   -- start.s
|   |-- Filter-Fir copy/
|   |   |-- dmem2.hex
|   |   |-- fir.hex
|   |   |-- fir2.hex
|   |   |-- golden1.hex
|   |   |-- link.ld
|   |   -- result.hex
|   |-- Filter-Sobel/
|   |   |-- link.ld
|   |   |-- pext copy.c
|   |   |-- pext.c
|   |   |-- pext.elf
|   |   |-- pext.log
|   |   |-- pext.s
|   |   |-- pext_dmem.hex
|   |   |-- pext_goldenw.hex
|   |   |-- pext_imem.hex
|   |   |-- pext_signature.hex
|   |   |-- reason.md
|   |   |-- scala.c
|   |   |-- scala.elf
|   |   |-- scala.log
|   |   |-- scala.s
|   |   |-- scala_dmem.hex
|   |   |-- scala_goldenb.hex
|   |   |-- scala_goldenw.hex
|   |   |-- scala_imem.hex
|   |   |-- scala_signature.hex
|   |   |-- sobel_cycle_analysis.md
|   |   |-- sobel_pext_analysis.md
|   |   |-- start.s
|   |   |-- visualize_sobel.html
|   |   -- visualize_sobel.py
|   |-- hazard_test/
|   |-- Hazards-IBaseTest/
|   |   |-- hazards_program_all.hex
|   |   |-- hazards_program_all.mem
|   |   |-- hazards_program_all.S
|   |   |-- mem.mem
|   |   |-- mem1.mem
|   |   -- program_all.hex
|   |-- Hazards-PExtTest/
|   |   |-- golden.hex
|   |   |-- hazards_test.dump
|   |   |-- hazards_test.elf
|   |   |-- hazards_test.hex
|   |   |-- hazards_test.S
|   |   |-- link.ld
|   |   -- result.hex
|   |-- include/
|   |-- load_store_test/
|   |   |-- load_store.hex
|   |   -- load_store.S
|   |-- p_ext_byte/
|   |   |-- golden.hex
|   |   |-- link.ld
|   |   |-- pext_byte.dump
|   |   |-- pext_byte.elf
|   |   |-- pext_byte.hex
|   |   -- pext_byte.S
|   |-- pext_test/
|   |   |-- dump.txt
|   |   |-- golden.hex
|   |   |-- link.ld
|   |   |-- pext_test.dump
|   |   |-- pext_test.elf
|   |   |-- pext_test.hex
|   |   |-- pext_test.S
|   |   |-- result.hex
|   |   -- rv32imp_pipeline.log
|   -- PExtTest/
|       |-- golden.hex
|       |-- link.ld
|       |-- missmarch.sisnature
|       |-- pext_alup_test.dump
|       |-- pext_alup_test.elf
|       |-- pext_alup_test.hex
|       |-- pext_alup_test.S
|       |-- pext_inst_test.c
|       |-- pext_inst_test.S
|       -- result.hex
|-- tb/
|   |-- tb_rv32im_pipeline_org.sv
|   -- tb_rv32imp_pipeline.sv
|-- .gitignore
|-- map_mismatch.py
|-- pext_add_sub.S
|-- rawcode.sv
|-- rawcode2.sv
|-- README.md
-- workspace_tree.md
```

