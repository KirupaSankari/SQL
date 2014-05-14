SELECT * FROM TABLE(siebel_stats.gather_siebel_stats(:schema_owner, :process_type))
*
ERROR at line 1:
ORA-04063: package body "SIEBEL.SIEBEL_STATS" has errors


