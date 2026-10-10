# 0022 — Notes are files

- **Status:** accepted
- **Date:** 2026-10-09

## Context
BRIEF §9's + sheet has New note, and an answer can be saved as a note. Notes must be searchable
and citable like documents, with the same access rules.

## Decision
- A note is a `File` of kind `NOTE` with source `WRITTEN`; its Markdown body is stored as the
  file's original in storage, and a `Note` row keeps the body for editing. Creating or editing
  one publishes `file.uploaded`, so it goes through the same extraction, chunking and embedding
  as an uploaded document.
- Notes live in collections like any file, list under Documents, and are cited like documents.
- An edit while the previous version is still indexing wins: the worker re-reads the status
  before marking a file Ready and skips stale work.

## Consequences
- Everything that works on files (trash, move, access, audit, search) works on notes for free.
- Rich editing beyond Markdown would need a different storage format; not planned.
