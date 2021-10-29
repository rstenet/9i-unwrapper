CREATE OR REPLACE FUNCTION UW_SIMPLE_A 
(
  p_number_a number
)
RETURN VARCHAR2 AS 
  L_VAR_A number := 100;
BEGIN
  L_VAR_A := p_number_a * L_VAR_A;
  RETURN L_VAR_A;
END;
