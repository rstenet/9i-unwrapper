CREATE OR REPLACE FUNCTION UW_SIMPLE_B
(
  param_a number,
  param_b varchar2,
  param_c number default 5,
  param_d varchar2 default 'ABCDE'
)
RETURN VARCHAR2 AS 
    L_PI CONSTANT REAL := 3.14159;
    L_VAR_A number(10,2) := 123.45;
	-- long string to see how lines are split
    L_VAR_B varchar2(200) := 'A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9'; 
	-- use of colon (:) in string 
	-- (2 :e:) on line 31 should be read as "colon escapes colon"
	L_NOW   varchar2(100) := TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS');
    function l_sum( f_param_a number, f_param_b number ) return number is
    begin
        return f_param_a + f_param_b;
    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
    end;
BEGIN
  L_VAR_A := (param_a + param_c) * L_VAR_A;
  L_VAR_A := L_VAR_A + l_sum(param_a, param_c);
  RETURN L_VAR_A || ' -- ' || L_VAR_B;
END UW_SIMPLE_B;
