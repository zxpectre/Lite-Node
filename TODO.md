# TODO
## Adapting koios-lite to use all koios-artifacts *.sql:
- Fix errors on SQL files when running ./scripts/lib/install_postgres.sh:
```
/scripts/sql/rpc/00_blockchain/genesis.sql: ERROR:  relation "rpc.genesis" does not exist
LINE 31:   FROM rpc.genesis AS g;
                ^
/scripts/sql/rpc/account/account_info_cached.sql: ERROR:  could not find a function named "rpc.account_info"
/scripts/sql/rpc/pool/pool_delegators_history.sql: ERROR:  could not find a function named "rpc.pool_delegators"
SQL scripts have finished processing, following scripts were executed successfully:

```
- adapt and add missing cron jobs
