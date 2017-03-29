/*
Offers:
	How to write an Oracle procedure.
	How to define a record type in procedure definition.
	How to write switch-case in Oracle.
*/

create or replace PROCEDURE BROKER_PREMIUM_KPI(
	p_broker_identifier        IN VARCHAR,--unique identifier for broker
	p_broker_organization_id   OUT NUMBER,
	p_medical_premium          OUT FLOAT,--total premium for medical plan
	p_dental_premium           OUT FLOAT,--total premium for dental plan
	p_vision_premium           OUT FLOAT,--total premium for vision plan
	p_basic_life_premium       OUT FLOAT,--total premium for basic life plan
	p_vol_life_premium         OUT FLOAT,--total premium for vol life plan
	p_vol_adnd_premium         OUT FLOAT,--total premium for vol ad&d plan
	p_basic_std_premium        OUT FLOAT,--total premium for employer paid std plan
	p_vol_std_premium          OUT FLOAT,--total premium for employee paid std plan
	p_basic_ltd_premium        OUT FLOAT,--total premium for employer paid ltd plan
	p_vol_ltd_premium          OUT FLOAT,--total premium for employee paid ltd plan
	p_accident_ins_premium     OUT FLOAT,--total premium for accident insurence plan
	p_critical_illness_premium OUT FLOAT)--total premium for critical illness plan
AS
	v_premium                 FLOAT(126) := 0.0;
	V_CURRENT_DATE            TIMESTAMP(6);
	v_combined_premium        FLOAT(126) := 0.0;
	v_employer_contribution   FLOAT(126) := 0.0;

  TYPE MPH_REC_TYPE
  IS
  RECORD
  (
    PRODUCT_CATEGORY        MEMBER_PLAN_HISTORY.PRODUCT_CATEGORY%type,
    EMPLOYEE_PREMIUM        MEMBER_PLAN_HISTORY.EMPLOYEE_PREMIUM%type,
    EMPLOYER_PREMIUM        MEMBER_PLAN_HISTORY.EMPLOYER_PREMIUM%type,
    START_DATE              MEMBER_PLAN_HISTORY.START_DATE%type,
    END_DATE                MEMBER_PLAN_HISTORY.END_DATE%type
  );

  MPH_REC                   MPH_REC_TYPE;
  --timestart number;
  --loop_count    number := 0;
BEGIN
	--dbms_output.enable;
	--timestart := dbms_utility.get_time();
    V_CURRENT_DATE := trunc(sysdate);
    p_medical_premium := 0.0;
    p_dental_premium := 0.0;
    p_vision_premium := 0.0;
    p_basic_life_premium := 0.0;
    p_vol_life_premium := 0.0;
    p_vol_adnd_premium := 0.0;
    p_basic_std_premium := 0.0;
    p_vol_std_premium := 0.0;
    p_basic_ltd_premium := 0.0;
    p_vol_ltd_premium := 0.0;
    p_accident_ins_premium := 0.0;
    p_critical_illness_premium := 0.0;

	SELECT BROKER_ORGANIZATION_ID INTO P_BROKER_ORGANIZATION_ID FROM BROKER WHERE BROKER_IDENTIFIER = P_BROKER_IDENTIFIER;

	--dbms_output.Put_line(chr(13)||chr(10) || 'Employee: ' || EE_CODE.EMPLOYEE_CODE);
	FOR i IN (SELECT E.ENROLLMENT_IDENTIFIER as ENROLLMENT_IDENTIFIER,
					 Upper(CPA.PRODUCT_CATEGORY) as PRODUCT_CATEGORY,
					 AT.NAME as APPLICANT_TYPE,
					 A.CONTACT_NAME,
					 A.APPLICANT_IDENTIFIER,
					 CPA.APPLICANT_SHARE_PREMIUM,
					 CPA.CONTRIBUTION,
					 CPA.COMBINED_CONTRIBUTION,
					 trunc(EPI.EFFECTIVE_DATE) as EFFECTIVE_DATE,
					 trunc(EPI.END_DATE) as end_date,
					 ep.plan_identifier as plan_identifier,
					 ep.IS_BASIC_ANCILLARY_PLAN
			  FROM   ENROLLMENT_SETUP ES
					 JOIN ENROLLMENT E
					   ON ES.ENROLLMENT_SETUP_IDENTIFIER = E.ENROLLMENT_SETUP_ID
					 JOIN APPLICANT A
					   ON E.ID = A.ENROLLMENT_ID
					 JOIN COVERAGE_PLAN_APPLICANT CPA
					   ON A.ID = CPA.APPLICANT_ID
					 JOIN ENROLLMENT_PLAN_INFO EPI
					   ON CPA.ENROLLMENT_PLAN_INFO_ID = EPI.ID
					 join ENROLLMENT_PLAN EP
					  on ep.id = cpa.plan_id
					 JOIN APPLICANT_TYPE AT
					   ON A.APPLICANT_TYPE_ID = AT.ID
					 JOIN STATUS_TYPE ST
					   ON ST.ID = E.STATUS_TYPE_ID
					 JOIN STATUS_TYPE_PLAN STP
					   ON STP.ID = EPI.STATUS_TYPE_ID
			  WHERE  ES.CREATOR_USER_ID = p_broker_identifier
			         AND ES.STATUS IN (2,6,12,13,14,15,16,19,21)
					 AND ES.DELETED = 0
					 AND E.DELETED = 0
					 AND E.CONTEXT = 'SHOP'
					 AND A.DELETED = 0
					 AND CPA.DELETED = 0
					 AND ST.NAME IN ('SUBMITTED','PROCESSING','APPROVED','LSC_SUBMITTED','LSC_TERMINATED','TERMINATED')
					 AND ((STP.NAME IN ('APPROVED','TERMINATED','TERMINATION_APPROVED','SYSTEM_TERMINATED','SUBMISSION_APPROVED'))
						 OR (STP.NAME = 'TERMINATION_REQUESTED' AND ST.NAME = 'LSC_TERMINATED'))
					 AND TRUNC(EPI.EFFECTIVE_DATE) <= V_CURRENT_DATE
					 AND TRUNC(EPI.END_DATE) >= V_CURRENT_DATE
					 AND TRUNC(EPI.ENRL_SETUP_END_DATE) >= V_CURRENT_DATE
					 AND TRUNC(EPI.EFFECTIVE_DATE) <= TRUNC(EPI.END_DATE)	--why:1to get a valid coverage period from EPI.
					 AND Upper(CPA.PRODUCT_CATEGORY) in ('MEDICAL','DENTAL','VISION','BASICLIFE','SUPPLEMENTALLIFE','SUPPLEMENTALADD','LTD','STD','SHORTTERM','CRITICALILLNESS','ACCIDENTINSURANCE'))
					 LOOP
		--dbms_output.Put_line('enrollment_identifier: ' || i.ENROLLMENT_IDENTIFIER || ', Product: ' || i.PRODUCT_CATEGORY
		--|| ', eff-date: ' || i.EFFECTIVE_DATE || ', end-date: ' || i.end_date || ', plan-id: ' || i.plan_identifier);
		--dbms_output.Put_line('Applicant: ' || i.APPLICANT_TYPE || '>>>>');
		v_premium := 0.0;
		v_combined_premium        := 0.0;
		v_employer_contribution   := 0.0;
		--loop_count := loop_count + 1;

		BEGIN
			SELECT UPPER(PRODUCT_CATEGORY),
				   EMPLOYEE_PREMIUM,
				   EMPLOYER_PREMIUM,
				   trunc(START_DATE),
				   trunc(END_DATE)
			INTO MPH_REC
			FROM MEMBER_PLAN_HISTORY
			WHERE MEMBER_INFO_HISTORY_ID = (SELECT ID
											FROM   MEMBER_INFO_HISTORY
											WHERE  ENROLLMENT_IDENTIFIER = i.ENROLLMENT_IDENTIFIER
											AND MEMBER_IDENTIFIER = i.APPLICANT_IDENTIFIER)
				  AND UPPER(PRODUCT_CATEGORY) = i.PRODUCT_CATEGORY
				  AND TRUNC(START_DATE) <= V_CURRENT_DATE
				  AND TRUNC(END_DATE) >= V_CURRENT_DATE
				  AND TRUNC(START_DATE) <= TRUNC(END_DATE)
				  AND plan_identifier = I.PLAN_IDENTIFIER;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
			MPH_REC := null;
		END;

		--dbms_output.Put_line('CPA : CONTRIBUTION=' || i.contribution || ', APPLICANT_SHARE_PREMIUM=' || i.APPLICANT_SHARE_PREMIUM || ', COMBINED_CONTRIBUTION=' || i.COMBINED_CONTRIBUTION);
		--if MPH_REC.PRODUCT_CATEGORY is not null then
			--dbms_output.Put_line('MemberPlanHistory: EE-premium=' || MPH_REC.EMPLOYEE_PREMIUM || ' ER-premium=' || MPH_REC.EMPLOYER_PREMIUM);
		--end if;

		IF I.APPLICANT_TYPE = 'PRIMARY' THEN
			IF MPH_REC.EMPLOYEE_PREMIUM IS NOT NULL THEN
				v_combined_premium :=  v_combined_premium + MPH_REC.EMPLOYEE_PREMIUM;
			END IF;
			IF MPH_REC.EMPLOYER_PREMIUM IS NOT NULL THEN
				v_employer_contribution :=  v_employer_contribution + MPH_REC.EMPLOYER_PREMIUM;
			END IF;
		ELSE
			v_combined_premium :=  v_combined_premium + I.APPLICANT_SHARE_PREMIUM;
			v_employer_contribution :=  v_employer_contribution + I.CONTRIBUTION;
		END IF;

		v_premium := v_premium + v_combined_premium + v_employer_contribution;
		--DBMS_OUTPUT.PUT_LINE('TOTAL PREMIUM = ' || V_PREMIUM);

		CASE i.product_category
			WHEN 'MEDICAL' THEN
				p_medical_premium := p_medical_premium + v_premium;
			WHEN 'DENTAL' THEN
				p_dental_premium := p_dental_premium + v_premium;
			WHEN 'VISION' THEN
				p_vision_premium := p_vision_premium + v_premium;
			WHEN 'BASICLIFE' THEN
				p_basic_life_premium := p_basic_life_premium + v_premium;
			WHEN 'SUPPLEMENTALLIFE' THEN
				p_vol_life_premium := p_vol_life_premium + v_premium;
			WHEN 'SUPPLEMENTALADD' THEN
				p_vol_adnd_premium := p_vol_adnd_premium + v_premium;
			WHEN 'STD' THEN
				if i.IS_BASIC_ANCILLARY_PLAN = 1 then
				  p_basic_std_premium := p_basic_std_premium + v_premium;
				else
				  p_vol_std_premium := p_vol_std_premium + v_premium;
				end if;
			WHEN 'LTD' THEN
				if i.IS_BASIC_ANCILLARY_PLAN = 1 then
				  p_basic_ltd_premium := p_basic_ltd_premium + v_premium;
				else
				  p_vol_ltd_premium := p_vol_ltd_premium + v_premium;
				end if;
			WHEN 'ACCIDENTINSURANCE' THEN
				p_accident_ins_premium := p_accident_ins_premium + v_premium;
			WHEN 'CRITICALILLNESS' THEN
				p_critical_illness_premium := p_critical_illness_premium + v_premium;
			ELSE DBMS_OUTPUT.PUT_LINE('NO DATA FOUND');
		END CASE;

	END LOOP;
 --dbms_output.put_line((dbms_utility.get_time() - timestart)/100 || 'seconds' || ' and ' || loop_count || ' times loop ran');
END BROKER_PREMIUM_KPI;
