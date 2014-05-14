SET serveroutput ON
SET VERIFY OFF
DECLARE
  ub                    NUMBER;
  ab                    NUMBER;
  v_avg_row_len         NUMBER;
  v_rows_to_be_inserted NUMBER :=&3;
  v_pct_free NUMBER;
  v_tablespace          VARCHAR2(30);
BEGIN
  SELECT tablespace_name,
    avg_row_len,
    v_pct_free
  INTO v_tablespace,
    v_avg_row_len,
    v_pct_free
  FROM dba_tables
  WHERE owner   ='&1'
  AND table_name = '&2';
  DBMS_SPACE.CREATE_TABLE_COST(v_tablespace,v_avg_row_len,v_rows_to_be_inserted,v_pct_free,ub,ab);
  DBMS_OUTPUT.PUT_LINE('Used Bytes      = ' || TO_CHAR(ub));
  DBMS_OUTPUT.PUT_LINE('Allocated Bytes = ' || TO_CHAR(ab));
END;
/

SET VERIFY ON