SPO coe_siebel_stats.log;
SET DEF ON TERM OFF ECHO ON;
CL TIMI;b
REM DESCRIPTION
REM   Collects schema object statistics for Siebel on 10g and 11g.
REM
REM PARAMETERS
REM   1. Proces Type: (N)ormal or (B)ase Line. Default N.
REM   2. Auto Execute: (N)o or (Y)es. Default N.
REM   3. Schema Owner: Default SIEBEL.
REM
REM EXECUTION
REM   1. When executed for the first time, connect into SQL*Plus as SYSall
REM      and use baseline process type:
REM        # sqlplus / as sysall
REM        SQL> START coe_siebel_stats.sql B Y SIEBEL
REM        or
REM        SQL> START coe_siebel_stats.sql B N SIEBEL
REM   2. After first execution (baseline), use daily as a script or PL/SQL library.
REM      2.1 Executed daily as a script:
REM          # sqlplus / as sysall
REM          SQL> START coe_siebel_stats.sql N Y SIEBEL
REM      2.2 Executed as a PL/SQL library (scheduled daily through a job):
REM          siebel_stats.gather_siebel_stats;
REM          or
REM          siebel_stats.gather_siebel_stats('SIEBEL', 'N');
REM
REM NOTES
REM   1. For possible errors see coe_siebel_stats.log.
REM   2. Use "Baseline" process type when used for the first time.
REM   3. Use "Normal" process type daily if possible, else weekly.
REM   4. Use Auto Execute to start automatically gathering script.
REM   5. Discontinue immediately the execution of the job that
REM      performs an automatic gathering of CBO statistics:
REM        On 10g, connect as SYS and execute
REM          EXEC DBMS_SCHEDULER.DISABLE('GATHER_STATS_JOB');
REM        On 11g, connect as SYS and execute
REM          EXEC DBMS_AUTO_TASK_ADMIN.DISABLE('auto optimizer stats collection', NULL, NULL);
REM
-- default_rows_threshold can be defined as any integer between 1 and 100
DEF default_rows_threshold = '15';
-- SIEBEL is the schema owner in most cases
DEF default_schema_owner = 'SIEBEL';
SET TERM ON ECHO OFF;
PRO
PRO Parameter 1:
PRO Proces Type: (N)ormal or (B)ase Line. Default "N".
PRO
DEF process_type = '&1';
PRO
PRO Parameter 2:
PRO Auto Execute: (N)o or (Y)es. Default "N".
PRO
DEF auto_execute = '&2';
PRO
PRO Parameter 3:
PRO Schema Owner: Default "SIEBEL".
PRO
DEF schema_owner = '&3';
PRO
PRO wait...

SET TERM OFF;
DROP SEQUENCE siebel_stats_line_id_s;
DROP TABLE siebel_stats_log;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

-- prepares parameters
VAR process_type CHAR(1);
VAR auto_execute CHAR(1);
VAR schema_owner VARCHAR2(30);
EXEC :process_type := NVL(UPPER(SUBSTR(TRIM(' ' FROM '&&process_type.'), 1, 1)), 'N');
EXEC :auto_execute := NVL(UPPER(SUBSTR(TRIM(' ' FROM '&&auto_execute.'), 1, 1)), 'N');
EXEC :schema_owner := UPPER(NVL(TRIM(' ' FROM '&&schema_owner.'), '&&default_schema_owner.'));
PRINT process_type;
PRINT auto_execute;
PRINT schema_owner;

CREATE SEQUENCE siebel_stats_line_id_s;

CREATE TABLE siebel_stats_log (
  line_id            NUMBER,
  dbms_stats_command VARCHAR2(4000),
  start_time         DATE,
  error              VARCHAR2(4000) );

CREATE OR REPLACE PACKAGE siebel_stats AS
  FUNCTION gather_siebel_stats (
    p_schema_owner   IN VARCHAR2 DEFAULT '&&default_schema_owner.',
    p_process_type   IN VARCHAR2 DEFAULT 'N',
    p_rows_threshold IN NUMBER   DEFAULT &&default_rows_threshold.,
    p_commands_only  IN VARCHAR2 DEFAULT 'N' )
  RETURN DBMS_DEBUG_VC2COLL PIPELINED;

  PROCEDURE gather_siebel_stats (
    p_schema_owner   IN VARCHAR2 DEFAULT '&&default_schema_owner.',
    p_process_type   IN VARCHAR2 DEFAULT 'N',
    p_rows_threshold IN NUMBER   DEFAULT &&default_rows_threshold. );
END siebel_stats;
/

CREATE OR REPLACE PACKAGE BODY siebel_stats AS
  FUNCTION gather_siebel_stats (
    p_schema_owner   IN VARCHAR2 DEFAULT '&&default_schema_owner.',
    p_process_type   IN VARCHAR2 DEFAULT 'N',
    p_rows_threshold IN NUMBER   DEFAULT &&default_rows_threshold.,
    p_commands_only  IN VARCHAR2 DEFAULT 'N' )
  RETURN DBMS_DEBUG_VC2COLL PIPELINED
  IS
    num_rows NUMBER;
    estimate_percent VARCHAR2(32767);
    frequency DATE;
    granularity VARCHAR2(32767);
    degree VARCHAR2(32767);
    method_opt VARCHAR2(32767);
    table_count NUMBER := 0;
    l_rdbms_version VARCHAR2(17);
    l_rdbms_release NUMBER;
    l_schema_owner VARCHAR2(30);
    l_rows_threshold NUMBER;
    l_exec VARCHAR2(12);
  BEGIN
    -- validates process type
    BEGIN
      IF p_process_type NOT IN ('N', 'B') THEN
        RAISE_APPLICATION_ERROR(-20400, 'Invalid process type: '||p_process_type);
      END IF;
    END;

    l_rows_threshold := NVL(p_rows_threshold, &&default_rows_threshold.);

    IF p_commands_only = 'N' THEN
      PIPE ROW('REM $Header: coe_gather_statistics.sql 11.2 2010/11/19 csierra $');
      PIPE ROW('-- begin script generation: '||TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS'));
      PIPE ROW('SPO coe_gather_statistics_'||TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS')||'.log;');
      PIPE ROW('SET ECHO ON TIM ON;');
      PIPE ROW('CL TIMI;');
      PIPE ROW('WHENEVER SQLERROR EXIT SQL.SQLCODE;');
      l_exec := 'EXEC ';
    ELSE
      l_exec := NULL;
    END IF;

    FOR i IN (SELECT t.owner, t.table_name, t.temporary, t.partitioned, t.num_rows, t.last_analyzed, s.stattype_locked, s.stale_stats
                FROM all_tables t,
                     all_tab_statistics s
               WHERE t.owner = l_schema_owner
                 AND (t.table_name LIKE 'S^_%' ESCAPE '^' -- "S_%"
                  OR  t.table_name LIKE 'CX^_%' ESCAPE '^') -- "CX_%"
                 AND t.table_name NOT LIKE 'S^_ETL%' ESCAPE '^' -- "S_ETL%"
                 AND t.table_name NOT LIKE 'BIN$%' -- recycle bin
                 AND (t.iot_type IS NULL OR t.iot_type <> 'IOT_OVERFLOW')
                 AND t.owner = s.owner
                 AND t.table_name = s.table_name
                 AND s.object_type = 'TABLE'
               ORDER BY
                     TRUNC(t.last_analyzed) NULLS FIRST,
                     t.num_rows,
                     t.table_name)
    LOOP
      table_count := table_count + 1;

      -- count up to 101 rows for each table
      EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM "'||i.owner||'"."'||i.table_name||'" WHERE ROWNUM <= 101' INTO num_rows;

      IF p_commands_only = 'N' THEN
        PIPE ROW('--'||CHR(10)||'-- '||table_count||' '||i.owner||'.'||i.table_name||' temp='||i.temporary||' part='||i.partitioned||' rows='||i.num_rows||' anlz='||i.last_analyzed||' lock='||i.stattype_locked||' stale='||i.stale_stats||' count='||num_rows);
      END IF;

      IF i.temporary = 'Y' OR num_rows <= l_rows_threshold THEN -- small or temporary tables should have no stats
        IF i.num_rows IS NOT NULL OR i.last_analyzed IS NOT NULL THEN -- if they have stats then delete and lock them
          IF i.stattype_locked IS NOT NULL THEN -- unlock first, but only if they were locked
            PIPE ROW(l_exec||'DBMS_STATS.UNLOCK_TABLE_STATS(''"'||i.owner||'"'', ''"'||i.table_name||'"'');');
          END IF;
          -- delete stats and lock them
          PIPE ROW(l_exec||'DBMS_STATS.DELETE_TABLE_STATS(''"'||i.owner||'"'', ''"'||i.table_name||'"'', force => TRUE);');
          PIPE ROW(l_exec||'DBMS_STATS.LOCK_TABLE_STATS(''"'||i.owner||'"'', ''"'||i.table_name||'"'');');
        ELSIF i.stattype_locked IS NULL THEN -- lock stats if they were empty but unlocked
          PIPE ROW(l_exec||'DBMS_STATS.LOCK_TABLE_STATS(''"'||i.owner||'"'', ''"'||i.table_name||'"'');');
        END IF;
      ELSE -- bigger tables (num_rows > rows_threshold)
        IF num_rows > 100 THEN
          IF i.num_rows IS NULL OR i.last_analyzed IS NULL THEN -- no stats, then count rows (sample 1%)
            EXECUTE IMMEDIATE 'SELECT COUNT(*) * 100 FROM "'||i.owner||'"."'||i.table_name||'" SAMPLE(1)' INTO num_rows;
          ELSE -- use num rows from prior stats gathering
            num_rows := i.num_rows;
          END IF;
        END IF;

        -- determine sample size and frequency as per current table size
        IF    num_rows BETWEEN   0 AND 1e6 THEN estimate_percent := '100'; frequency := SYSDATE - 21;
        ELSIF num_rows BETWEEN 1e6 AND 1e7 THEN estimate_percent :=  '30'; frequency := SYSDATE - 28;
        ELSIF num_rows BETWEEN 1e7 AND 1e8 THEN estimate_percent :=  '10'; frequency := SYSDATE - 35;
        ELSIF num_rows BETWEEN 1e8 AND 1e9 THEN estimate_percent :=   '3'; frequency := SYSDATE - 42;
        ELSE                                    estimate_percent :=   '1'; frequency := SYSDATE - 49;
        END IF;

        -- if 11g then use auto sample size instead (ok only if gathering with no histograms)
        IF l_rdbms_release >= 11 THEN
          estimate_percent := 'DBMS_STATS.AUTO_SAMPLE_SIZE';
        END IF;

        -- gather stats if this is a baseline, or stats are old, or stats are empty or stale
        IF p_process_type = 'B' OR i.last_analyzed < frequency OR i.last_analyzed IS NULL OR i.stale_stats = 'YES' THEN
          -- unlock stats if they were locked
          IF i.stattype_locked IS NOT NULL THEN
            PIPE ROW(l_exec||'DBMS_STATS.UNLOCK_TABLE_STATS(''"'||i.owner||'"'', ''"'||i.table_name||'"'');');
          END IF;

          IF i.partitioned = 'YES' THEN
            granularity := 'granularity => ''GLOBAL AND PARTITION'', ';
          ELSE
            granularity := NULL;
          END IF;

          -- use parallel execution to gather stats if table has more than 10k rows
          IF num_rows > 1e4 THEN
            degree := 'degree => DBMS_STATS.DEFAULT_DEGREE, ';
          ELSE
            degree := NULL;
          END IF;

          IF i.table_name IN ('S_POSTN_CON', 'S_ORG_BU', 'S_ORG_GROUP') THEN
            method_opt := 'FOR ALL COLUMNS SIZE 254';
          ELSE
            method_opt := 'FOR ALL INDEXED COLUMNS SIZE 254';
          END IF;

          IF p_process_type = 'B' AND method_opt = 'FOR ALL INDEXED COLUMNS SIZE 254' THEN
            -- delete column stats for non-indexed columns (if they do have stats)
            FOR j IN (SELECT tc.column_name
                        FROM all_tab_cols tc
                       WHERE tc.owner = i.owner
                         AND tc.table_name = i.table_name
                         AND tc.last_analyzed IS NOT NULL
                         AND NOT EXISTS (
                      SELECT NULL
                        FROM all_ind_columns ic
                       WHERE ic.table_owner = tc.owner
                         AND ic.table_name = tc.table_name
                         AND ic.column_name = tc.column_name)
                       ORDER BY
                             tc.column_id ASC NULLS LAST,
                             tc.column_name)
            LOOP
              PIPE ROW(l_exec||'DBMS_STATS.DELETE_COLUMN_STATS(''"'||i.owner||'"'', ''"'||i.table_name||'"'', ''"'||j.column_name||'"'', no_invalidate => TRUE);');
            END LOOP;
          END IF;

          PIPE ROW(l_exec||'DBMS_STATS.GATHER_TABLE_STATS(''"'||i.owner||'"'', ''"'||i.table_name||'"'', estimate_percent => '||estimate_percent||', method_opt => '''||method_opt||''', '||degree||granularity||'cascade => TRUE);');
        END IF;
      END IF;
    END LOOP;

    IF p_commands_only = 'N' THEN
      PIPE ROW('--');
      PIPE ROW('WHENEVER SQLERROR CONTINUE;');
      PIPE ROW('SET ECHO OFF TIM OFF;');
      PIPE ROW('SPO OFF;');
      PIPE ROW('-- end script generation: '||TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS'));
    END IF;

    RETURN;
  END gather_siebel_stats;

  PROCEDURE gather_siebel_stats (
    p_schema_owner   IN VARCHAR2 DEFAULT '&&default_schema_owner.',
    p_process_type   IN VARCHAR2 DEFAULT 'N',
    p_rows_threshold IN NUMBER   DEFAULT &&default_rows_threshold. )
  IS
    l_errors NUMBER;
    l_error VARCHAR2(4000);
  BEGIN
    DELETE siebel_stats_log;
    INSERT INTO siebel_stats_log (line_id, dbms_stats_command)
    SELECT siebel_stats_line_id_s.NEXTVAL, column_value FROM
    TABLE(siebel_stats.gather_siebel_stats(p_schema_owner, p_process_type, p_rows_threshold, 'Y'));

    FOR i IN (SELECT ROWID row_id, dbms_stats_command FROM siebel_stats_log ORDER BY line_id)
    LOOP
      UPDATE siebel_stats_log SET start_time = SYSDATE WHERE ROWID = i.row_id;
      DBMS_OUTPUT.PUT_LINE(TO_CHAR(SYSDATE, 'YYYYMMDD HH24:MI:SS ')||i.dbms_stats_command);
      BEGIN
        EXECUTE IMMEDIATE ('BEGIN '||i.dbms_stats_command||' END;');
      EXCEPTION
        WHEN OTHERS THEN
          l_error := SQLERRM;
          UPDATE siebel_stats_log SET error = l_error WHERE ROWID = i.row_id;
          DBMS_OUTPUT.PUT_LINE(TO_CHAR(SYSDATE, 'YYYYMMDD HH24:MI:SS ')||'*** '||l_error);
      END;
    END LOOP;

    SELECT COUNT(*) INTO l_errors FROM siebel_stats_log WHERE error IS NOT NULL;
    IF l_errors > 0 THEN
      RAISE_APPLICATION_ERROR(-20500, 'There were '||l_errors||' error(s). Review SIEBEL_STATS_LOG.');
    END IF;
  END gather_siebel_stats;
END siebel_stats;
/

SHOW ERRORS;

SET FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 TRIMS ON TIM OFF NUMF "" RECSEP OFF SERVEROUT ON SIZE 1000000 FOR TRU;

SPO coe_gather_statistics.sql;
SELECT * FROM TABLE(siebel_stats.gather_siebel_stats(:schema_owner, :process_type));

SPO coe_driver.sql;
BEGIN
  IF :auto_execute = 'Y' THEN
    DBMS_OUTPUT.PUT_LINE('PRO executing coe_gather_statistics.sql');
    DBMS_OUTPUT.PUT_LINE('START coe_gather_statistics.sql');
  ELSE
    DBMS_OUTPUT.PUT_LINE('PRO review coe_gather_statistics.sql');
  END IF;
END;
/

SPO OFF;
UNDEFINE default_rows_threshold default_schema_owner 1 process_type 2 auto_execute 3 schema_owner
SET DEF ON TERM ON ECHO OFF FEED 6 VER ON SHOW OFF HEA ON LIN 80 NEWP 1 PAGES 14 TRIMS OFF TIM OFF NUMF "" RECSEP WR SERVEROUT OFF;
WHENEVER SQLERROR CONTINUE;
START coe_driver.sql;

