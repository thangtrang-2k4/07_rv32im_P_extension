# AGENTS.md — Entry Point cho Codex & opencode

## STARTUP SEQUENCE — Đọc theo thứ tự khi mở conversation mới:

1. **AGENT.md** → Project map, thư mục nào chứa gì
2. **.agent/handoff/SESSION_LOG.md** → Trạng thái hiện tại, đã làm gì, tiếp theo làm gì
3. **.agent/handoff/FILE_OWNERSHIP.md** → Task board, file nào đang lock
4. **.agent/docs/rtl_standards.md** → Quy chuẩn code SystemVerilog (khi viết RTL)
5. **.agent/docs/build_commands.md** → Lệnh compile, sim (khi cần test)

## Quy tắc:

- Sau khi đọc xong startup sequence, bạn đã có đầy đủ bối cảnh.
- Trước khi SỬA file → check `FILE_OWNERSHIP.md` → đăng ký lock.
- Sau khi XONG task → xóa lock → update `SESSION_LOG.md` → commit.
- Khi hết phiên → cập nhật `SESSION_LOG.md` để bàn giao cho agent tiếp theo.

## Plan triển khai hiện tại:

→ Đọc `docs/implementation_brainstorm.md` (3 phase, 15 bước chi tiết)

## Project Rules:

→ Đọc `GEMINI.md` (phân vai agent, quy tắc R-S-E, multi-agent coordination)
