# MSSQL container migration (Podman, one step)

Migrates a list of databases from one SQL Server container to another —
both running in Podman on the same host — with a single command.

```text
┌─────────────────┐    BACKUP      ┌──────────────┐    cat >    ┌─────────────────┐
│  mssql-source   │ ────────────▶ │ staging/*.bak │ ──────────▶ │  mssql-target   │
│  (Podman)       │   WITH CHECKSUM│  (on the Mac) │             │  (Podman)       │
└─────────────────┘                └──────────────┘             └─────────────────┘
                                        RESTORE FILELISTONLY ▶ MOVE clauses built automatically
```

## What the script does

For each database in `DATABASES`:

1. `BACKUP DATABASE ... WITH INIT, CHECKSUM, STATS=5` on the source container.
2. Streams the `.bak` through the host into the target container
   (`podman exec ... cat` both ways — no `podman cp` permission/ownership issues).
3. Reads `RESTORE FILELISTONLY` and builds `MOVE` clauses automatically, so logical
   file names never need to be hard-coded and restores are collision-free
   (`AppDb_AppDb.mdf`, `AppDb_AppDb_log.ldf`, ...).
4. Drops any existing copy on the target (so re-runs are idempotent) and restores
   with `RECOVERY, CHECKSUM, REPLACE`.
5. Verifies the database is `ONLINE`.

A failed database doesn't stop the others; the summary line and exit code report
failures (usable in CI).

## Files

| File | Purpose |
| --- | --- |
| `migrate.sh` | The whole migration — run this |
| `config.env` | Container names, sa passwords, database list |
| `.vscode/tasks.json` | VS Code tasks: **Cmd+Shift+B** to run, or the "dry run" task |
| `staging/` | Created at runtime; backups pass through here (gitignored) |

## Usage

1. Open the folder in VS Code.
2. Edit `config.env`: set the two container names, sa passwords, and the four
   database names.
3. Preview first (recommended):

   ```bash
   DRY_RUN=true ./migrate.sh
   ```

4. Run the migration:

   ```bash
   ./migrate.sh
   ```

   Or in VS Code: **Cmd+Shift+B** (build task) runs `migrate.sh`, and
   **Terminal ▸ Run Task... ▸ mssql: dry run** previews it.

## Requirements

- Both containers running on the same Podman host, `sa` access to each.
- Works with the `mssql/server` images (2019 and 2022): the script auto-detects
  `/opt/mssql-tools18/bin/sqlcmd` (newer images, where `-C` is needed for the
  self-signed certificate) and falls back to `/opt/mssql-tools/bin/sqlcmd`.
- macOS system bash (3.2) is fine — the script avoids bash 4+ features.

## Notes and gotchas

- **Logins and users**: server logins live in `master`, not in your databases.
  After the migration, reconnect database users to logins on the target:

  ```sql
  -- for each user, e.g. from the VS Code MSSQL extension
  ALTER USER [app_user] WITH LOGIN = [app_user];
  ```

  If the logins themselves don't exist on the target, generate them on the source
  with the classic `sp_help_revlogin` script and run the output on the target.

- **Version direction**: you can only restore *upward* (2019 backup → 2022
  server is fine; 2022 → 2019 is not). The restored databases keep the source
  compatibility level; raise it manually if wanted:

  ```sql
  ALTER DATABASE [AppDb] SET COMPATIBILITY_LEVEL = 160;
  ```

- **Space**: the script needs room for one `.bak` in the source container, one on
  the Mac (`staging/`), and the restored files in the target.
- **Big databases**: the `cat` streaming is simple but single-threaded. For
  repeated large migrations, mount the same named volume at `/var/opt/mssql/backup`
  in **both** containers and set `BACKUP_DIR` accordingly — the backup then
  lands directly where the target can read it.
- **Different hosts / going to Azure**: use `sqlpackage` with `/Action:Export`
  (`.bacpac`) instead — it's schema+data, version-flexible, and moves well over
  networks. Detach/attach (copying `.mdf`/`.ldf`) also works between identical
  versions but requires stopping the source — backup/restore is safer.
- **Read-only databases**: a restored copy keeps the source's read-only state.
  Fix with `ALTER DATABASE [AppDb] SET READ_WRITE;`
- The sa password is passed to sqlcmd via the `SQLCMDPASSWORD` environment
  variable (`podman exec --env`), so it never shows up in a `ps` listing.
  Keep `config.env` out of version control (`.gitignore` is included) and
  consider `chmod 600 config.env`.
- Filestream/full-text-enabled databases are not fully handled (only `D`/`L`
  files get `MOVE` clauses) — the script warns and skips such files.

## Troubleshooting

- `sqlcmd not found inside <container>` — the container may be stopped, or it's
  a non-Microsoft image; check `podman ps` and the path detection in
  `find_sqlcmd`.
- Certificate errors (`SSL Provider: certificate chain ...`) — the image has
  tools18 but the script's `-C` detection didn't trigger; confirm the detected
  path contains `tools18`.
- `Operating system error 5` restoring — the backup file arrived unreadable;
  this shouldn't happen with the `cat` streaming approach, but check that
  `/var/opt/mssql/backup` is writable inside the target container.
