Ref: https://oracle-base.com/articles/10g/scheduler-10g



CREATE OR REPLACE PROCEDURE SCHEDULAR_DEMO
IS
	V_CURRENT_DATE             TIMESTAMP(6);
BEGIN
	V_CURRENT_DATE          := TRUNC(SYSDATE);

	FOR I IN (SELECT * from dual) LOOP
					
		--DBMS_OUTPUT.PUT_LINE(CHR(13)||CHR(10));
		--DBMS_OUTPUT.PUT_LINE('TEST');
    
		--write your logic here.
					
	END LOOP;
END SCHEDULAR_DEMO;
/


---------------------------------------------------Scheduling job-------------------------------------------------------
DECLARE
v_cnt1 number ;
v_cnt2 number ;
v_cnt3 number ;

BEGIN
--Create A Schedule:
select count(*) into v_cnt1 FROM User_Scheduler_Schedules where schedule_name ='SCHEDULAR_DEMO_SCHEDULE' ;

If v_cnt1 = 0 Then 
Dbms_scheduler.create_schedule
(schedule_name => 'SCHEDULAR_DEMO_SCHEDULE',
Start_date => TRUNC(SYSDATE),
Repeat_interval => 'FREQ=DAILY; BYDAY=MON,TUE,WED,THU,FRI,SAT,SUN; BYHOUR=00; BYMINUTE=00; BYSECOND=00', --scheduling to run at mid-night every day.
Comments => 'Execute this task every day at 00.01');

End If ;

--Create A Program:
select count(*) into v_cnt2 FROM User_Scheduler_Programs where program_name = 'SCHEDULAR_DEMO_PROG' ;

If v_cnt2 = 0 Then
Dbms_scheduler.create_program
(program_name => 'SCHEDULAR_DEMO_PROG',
Program_type =>'STORED_PROCEDURE',
Program_action => 'SCHEDULAR_DEMO',
Enabled => TRUE,
Comments => 'Execute a procedure to check if a valid proposal exist for employer-client and to update is_client_liev accordingly.');

End If  ;
--Create A Job:
select count(*) into v_cnt3 FROM USER_SCHEDULER_JOBS where job_name = 'SCHEDULAR_DEMO_JOB' ;

If v_cnt3 =0 Then
Dbms_scheduler.create_job
(Job_name => 'SCHEDULAR_DEMO_JOB',
Program_name => 'SCHEDULAR_DEMO_PROG',
Schedule_name => 'SCHEDULAR_DEMO_SCHEDULE',
Enabled => TRUE,
Comments => 'This job will update IS_CLIENT_LIVE column of CLIENT_EMPLOYER table.');
End if ;

END;
/

--------------------------------------------Updating Schedule interval------------------------------------------
begin
dbms_scheduler.set_attribute (
name               =>  'SCHEDULAR_DEMO_JOB',
attribute          =>  'repeat_interval',
value              =>  'freq=daily; byhour=3');
end;
/

--------------------------------------------Droping schedular and job-------------------------------------------

BEGIN
  DBMS_SCHEDULER.drop_job (job_name => 'SCHEDULAR_DEMO_JOB');
  DBMS_SCHEDULER.drop_program (program_name => 'SCHEDULAR_DEMO_PROG');
  DBMS_SCHEDULER.drop_schedule (schedule_name => 'SCHEDULAR_DEMO_SCHEDULE');
END; 
/