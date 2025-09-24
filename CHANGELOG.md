## [Unreleased]

## [0.1.0] - 2025-09-23

- `Bivy::RecordJob` & `Bivy::IndexJob` jobs for async indexing.
- Including `Bivy::Indexable` adds `after_save_commit` & `after_destroy_commit` callbacks.
- Index a model by including `Bivy::Indexable` module.
- Access indexable models through `Bivy::Indexable.models`.
