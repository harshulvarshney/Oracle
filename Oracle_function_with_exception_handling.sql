/*
Offers:
	how to handle EXCEPTION for all function or for a single query inside function.
	how to use TO_NUMBER function.
	how to print exception code, error message and line number at which error occured.
	how to add/substract days from dates.

*/


CREATE OR REPLACE FUNCTION IS_RENEWAL_DEADLINE_REACHED(
    P_COVERAGE_END_DATE IN DATE,
    P_EXCHANGE_ID       IN VARCHAR2)
  RETURN BOOLEAN
IS
  V_RENEWAL_DEADLINE         DATE;   --date until which a proposal renewal is allowed
  V_OEP_TO_AND_EFF_DATE_GAP  NUMBER; --min gap required between oep to date and proposal effective date
  V_OEP_TO_AND_FROM_DATE_GAP NUMBER; --min gap required between oep to date and oep from date
  V_SHARE_TO_FROM_DATE_GAP   NUMBER; --min gap required between proposal share date and oep to date
  V_NEW_EFF_DATE             DATE;
  V_NEW_OEP_TO_DATE          DATE;
  V_NEW_OEP_FROM_DATE        DATE;
BEGIN
	--dbms_output.put_line('exchange: ' || P_EXCHANGE_ID);

	--KEY1
	BEGIN
		SELECT TO_NUMBER(VALUE) INTO V_OEP_TO_AND_EFF_DATE_GAP
		FROM TABLE1 T1
		JOIN TABLE2 T2 ON T1.CONFIG_GROUP_ID = T2.ID
		WHERE T1.KEY          = 'KEY1'
		AND T1.EXCHANGE_ID    = P_EXCHANGE_ID						--FIRST CHECK FOR EXCHANGE
		AND (T2.PORTAL        = 'BROKER' OR T2.PORTAL          = 'ALL');
	EXCEPTION
	WHEN NO_DATA_FOUND THEN
		SELECT TO_NUMBER(VALUE) INTO V_OEP_TO_AND_EFF_DATE_GAP
		FROM TABLE1 T1
		JOIN TABLE2 T2 ON T1.CONFIG_GROUP_ID = T2.ID
		WHERE T1.KEY          = 'KEY1'
		AND T1.EXCHANGE_ID    IS NULL								--SET DEFAULT VALUE IF CONFIGURATION DOES NOT EXIST FOR EXCHANGE.
		AND (T2.PORTAL        = 'BROKER' OR T2.PORTAL          = 'ALL');
	END;

	--KEY2
	BEGIN
		SELECT TO_NUMBER(VALUE) INTO V_OEP_TO_AND_FROM_DATE_GAP
		FROM TABLE1 T1
		JOIN TABLE2 T2 ON T1.CONFIG_GROUP_ID         = T2.ID
		WHERE KEY                     = 'KEY2'
		AND T1.EXCHANGE_ID    = P_EXCHANGE_ID
		AND (T2.PORTAL                = 'BROKER' OR T2.PORTAL                  = 'ALL');
	EXCEPTION
	WHEN NO_DATA_FOUND THEN
		SELECT TO_NUMBER(VALUE) INTO V_OEP_TO_AND_FROM_DATE_GAP
		FROM TABLE1 T1
		JOIN TABLE2 T2 ON T1.CONFIG_GROUP_ID         = T2.ID
		WHERE KEY                     = 'KEY2'
		AND T1.EXCHANGE_ID    IS NULL
		AND (T2.PORTAL                = 'BROKER' OR T2.PORTAL                  = 'ALL');
	END;

	--KEY3
	BEGIN
		SELECT TO_NUMBER(VALUE) INTO V_SHARE_TO_FROM_DATE_GAP
		FROM TABLE1 T1
		JOIN TABLE2 T2 ON T1.CONFIG_GROUP_ID         = T2.ID
		WHERE KEY                     = 'KEY3'
		AND T1.EXCHANGE_ID    = P_EXCHANGE_ID
		AND (T2.PORTAL                = 'BROKER' OR T2.PORTAL                  = 'ALL');
	EXCEPTION
	WHEN NO_DATA_FOUND THEN
		SELECT TO_NUMBER(VALUE) INTO V_SHARE_TO_FROM_DATE_GAP
		FROM TABLE1 T1
		JOIN TABLE2 T2 ON T1.CONFIG_GROUP_ID         = T2.ID
		WHERE KEY                     = 'KEY3'
		AND T1.EXCHANGE_ID    IS NULL
		AND (T2.PORTAL                = 'BROKER' OR T2.PORTAL                  = 'ALL');
	END;

	V_NEW_EFF_DATE      := P_COVERAGE_END_DATE + 1;
	V_NEW_OEP_TO_DATE   := V_NEW_EFF_DATE      - V_OEP_TO_AND_EFF_DATE_GAP;
	V_NEW_OEP_FROM_DATE := V_NEW_OEP_TO_DATE   - V_OEP_TO_AND_FROM_DATE_GAP;
	V_RENEWAL_DEADLINE  := V_NEW_OEP_FROM_DATE - V_SHARE_TO_FROM_DATE_GAP;

	--dbms_output.put_line('V_NEW_EFF_DATE: ' || V_NEW_EFF_DATE || ', V_NEW_OEP_TO_DATE: ' || V_NEW_OEP_TO_DATE || ', V_NEW_OEP_FROM_DATE: ' || V_NEW_OEP_FROM_DATE);
	--dbms_output.put_line('deadlie date: ' || V_RENEWAL_DEADLINE);

	
	IF V_RENEWAL_DEADLINE is not null and V_RENEWAL_DEADLINE < SYSDATE THEN
	  RETURN TRUE;
	ELSE
	  RETURN FALSE;
	END IF;
EXCEPTION
	WHEN others THEN
	  DBMS_OUTPUT.PUT_LINE (SQLCODE || ' ' || SUBSTR(SQLERRM, 1, 64) || ' ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
	  RETURN TRUE;
END;