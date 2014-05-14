set markup html on 
spool public_html/conc.html

SELECT 
   fcr.request_id request_id
   ,to_char(fcr.REQUESTED_START_DATE,'DD-MON-YYYY HH24:MI') req_start_date
   ,to_char(fcr.actual_start_date,'DD-MON-YYYY HH24:MI') start_date
   ,to_char(fcr.actual_completion_date,'DD-MON-YYYY HH24:MI') completion_date
   ,ROUND( ( NVL( fcr.actual_completion_date, sysdate ) - actual_start_date ) * 24, 2 ) duration 
   ,fcp.concurrent_program_name conc_prog
   ,fcpt.user_concurrent_program_name user_conc_prog
   ,DECODE(fcr.phase_code,
      'C', 'Completed ',
          'I', 'Inactive',
          'P', 'Pending',
          'R', 'Running',
      fcr.phase_code)
 phase_code
   ,DECODE(fcr.status_code,
          'A', 'Waiting', 
          'B', 'Resuming',
          'C', 'Normal', 
          'D', 'Cancelled',
          'E', 'Errored', 
          'F', 'Scheduled',
          'G', 'Warning', 
          'H', 'On Hold',
          'I', 'Normal', 
          'M', 'No Manager',
          'Q', 'Standby', 
          'R', 'Normal',
          'S', 'Suspended', 
          'T', 'Terminating',
          'U', 'Disabled', 
          'W', 'Paused',
          'X', 'Terminated', 
          'Z', 'Waiting',
          fcr.status_code
          ) status_code
   ,fusr.user_name user_name
FROM
  fnd_concurrent_programs fcp,
  fnd_concurrent_programs_tl fcpt,
  fnd_concurrent_requests fcr,
  fnd_user fusr
WHERE 
   fcr.requested_start_date>(SYSDATE-1) and 
   --fcr.phase_code<>'C' and
   fcr.requested_by = fusr.user_id and 
  -- fusr.user_name not in ('SYSADMIN','TSD_SUPPORT','APPSMGR') and
   fcp.concurrent_program_name not in ('ALECDC','FNDOAMCOL','OAMCHARTCOL','FNDRSSUB','FNDWFLSC','FNDRSSTG') and
   (fcr.phase_code<>'P' and fusr.user_name  not in ('SYSADMIN')) and
   fcr.concurrent_program_id = fcp.concurrent_program_id and 
   fcr.program_application_id = fcp.application_id and 
   fcr.concurrent_program_id = fcpt.concurrent_program_id and 
   fcr.program_application_id = fcpt.application_id ORDER BY 
   requested_start_date desc;       

spool off;
exit
    
