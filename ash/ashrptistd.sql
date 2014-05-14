Rem
Rem $Header: rdbms/admin/ashrptistd.sql /main/1 2008/10/16 17:59:23 sburanaw Exp $
Rem
Rem ashrptistd.sql
Rem
Rem Copyright (c) 2008, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      ashrptistd.sql - SQL*Plus helper script for obtaining user input
Rem                       when ASH report is run on standby instance
Rem
Rem    DESCRIPTION
Rem      
Rem
Rem    NOTES
Rem      This script expects a variable stdby_flag to be already declared. 
Rem      The user choice (standby/primary) is stored in this variable
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    akini       09/11/08 - ash report script for user input on standby
Rem                           instance
Rem    akini       09/11/08 - Created
Rem

prompt 
prompt You are running ASH report on a Standby database. To generate the report
prompt over data sampled on the Primary database, enter 'P'. 
prompt Defaults to 'S' - data sampled in the Standby database.

column src new_value stdbyflag;
set heading off
select 'Using Primary (P) or Standby (S):',
       (case when '&&stdbyflag' IS NULL 
             then 'S'
             else '&&stdbyflag' end) as src
from   dual;
set heading on 

begin
  select decode('&&stdbyflag', 'S', 1, 'P', 2, 1) into :stdby_flag from dual;
end;
/

-- cleanup
undefine stdbyflag;
