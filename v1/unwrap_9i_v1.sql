create or replace procedure unwrap_9i_v1(p_name VARCHAR2 := ' ') is

/*
CREATE GLOBAL TEMPORARY TABLE UW_SRC ( IDX NUMBER, SRC VARCHAR2(80),
    CONSTRAINT "UW_SRC_PK" PRIMARY KEY ("IDX") ENABLE);
    
CREATE GLOBAL TEMPORARY TABLE UW_DIANA ( P NUMBER, IDX NUMBER, VAL NUMBER,
    CONSTRAINT "UW_DIANA_PK" PRIMARY KEY ("P", "IDX") ENABLE ) ON COMMIT PRESERVE ROWS;
    
CREATE GLOBAL TEMPORARY TABLE UW_LEX (IDX NUMBER, SRC VARCHAR2(4000 BYTE),
    CONSTRAINT "UW_LEX_PK" PRIMARY KEY ("IDX") ENABLE) ON COMMIT PRESERVE ROWS;    
    
    
set SERVEROUTPUT ON
exec unwrap_9_v1('name_wrapped_code');
exec unwrap_9_v1('');
    
*/

    l_sql_line varchar2(4000);
    l_tmp_clob clob;
    l_sql_clob clob;
    l_number_of_lines number;

    l_offset pls_integer:=1;
    l_line varchar2(32767);
    l_total_length pls_integer;
    l_line_length pls_integer;

    l_idx number := 1;

    section_len number;
    lex_line varchar2(32767) := '';
    rpt number := 1;        -- repeat next hex n times

    cr varchar(2) := chr(10);
    global_section_len number;
    is_not_cur BOOLEAN := TRUE;
    aggreg_link varchar2(5) := ' AND ';
    range_link varchar2(5) := ' AND ';
    


    type t_node_name is varray(300) of VARCHAR2(20);
    l_node_name t_node_name := t_node_name(
    'D_ABORT', 'D_ACCEPT', 'D_ACCESS', 'D_ADDRES', 'D_AGGREG', 'D_ALIGNM', 'D_ALL', 'D_ALLOCA', 'D_ALTERN', 'D_AND_TH', 'D_APPLY', 'D_ARRAY', 
    'D_ASSIGN', 'D_ASSOC', 'D_ATTRIB', 'D_BINARY', 'D_BLOCK', 'D_BOX', 'D_C_ATTR', 'D_CASE', 'D_CODE', 'D_COMP_R', 'D_COMP_U', 'D_COMPIL', 
    'D_COND_C', 'D_COND_E', 'D_CONSTA', 'D_CONSTR', 'D_CONTEX', 'D_CONVER', 'D_D_AGGR', 'D_D_VAR', 'D_DECL', 'D_DEF_CH', 'D_DEF_OP', 'D_DEFERR', 
    'D_DELAY', 'D_DERIVE', 'D_ENTRY', 'D_ENTRY_', 'D_ERROR', 'D_EXCEPT', 'D_EXIT', 'D_F_', 'D_F_BODY', 'D_F_CALL', 'D_F_DECL', 'D_F_DSCR', 'D_F_FIXE', 
    'D_F_FLOA', 'D_F_INTE', 'D_F_SPEC', 'D_FIXED', 'D_FLOAT', 'D_FOR', 'D_FORM', 'D_FORM_C', 'D_GENERI', 'D_GOTO', 'D_IF', 'D_IN', 'D_IN_OP', 'D_IN_OUT', 
    'D_INDEX', 'D_INDEXE', 'D_INNER_', 'D_INSTAN', 'D_INTEGE', 'D_L_PRIV', 'D_LABELE', 'D_LOOP', 'D_MEMBER', 'D_NAMED', 'D_NAMED_', 'D_NO_DEF', 
    'D_NOT_IN', 'D_NULL_A', 'D_NULL_C', 'D_NULL_S', 'D_NUMBER', 'D_NUMERI', 'D_OR_ELS', 'D_OTHERS', 'D_OUT', 'D_P_', 'D_P_BODY', 'D_P_CALL', 'D_P_DECL', 
    'D_P_SPEC', 'D_PARENT', 'D_PARM_C', 'D_PARM_F', 'D_PRAGMA', 'D_PRIVAT', 'D_QUALIF', 'D_R_', 'D_R_REP', 'D_RAISE', 'D_RANGE', 'D_RENAME', 'D_RETURN', 
    'D_REVERS', 'D_S_', 'D_S_BODY', 'D_S_CLAU', 'D_S_DECL', 'D_S_ED', 'D_SIMPLE', 'D_SLICE', 'D_STRING', 'D_STUB', 'D_SUBTYP', 'D_SUBUNI', 'D_T_BODY', 
    'D_T_DECL', 'D_T_SPEC', 'D_TERMIN', 'D_TIMED_', 'D_TYPE', 'D_U_FIXE', 'D_U_INTE', 'D_U_REAL', 'D_USE', 'D_USED_B', 'D_USED_C', 'D_USED_O', 
    'D_V_', 'D_V_PART', 'D_VAR', 'D_WHILE', 'D_WITH', 'DI_ARGUM', 'DI_ATTR_', 'DI_COMP_', 'DI_CONST', 'DI_DSCRM', 'DI_ENTRY', 'DI_ENUM', 'DI_EXCEP', 
    'DI_FORM', 'DI_FUNCT', 'DI_GENER', 'DI_IN', 'DI_IN_OU', 'DI_ITERA', 'DI_L_PRI', 'DI_LABEL', 'DI_NAMED', 'DI_NUMBE', 'DI_OUT', 'DI_PACKA', 
    'DI_PRAGM', 'DI_PRIVA', 'DI_PROC', 'DI_SUBTY', 'DI_TASK_', 'DI_TYPE', 'DI_U_ALY', 'DI_U_BLT', 'DI_U_NAM', 'DI_U_OBJ', 'DI_USER', 'DI_VAR', 
    'DS_ALTER', 'DS_APPLY', 'DS_CHOIC', 'DS_COMP_', 'DS_D_RAN', 'DS_D_VAR', 'DS_DECL', 'DS_ENUM_', 'DS_EXP', 'DS_FORUP', 'DS_G_ASS', 'DS_G_PAR', 'DS_ID',
    'DS_ITEM', 'DS_NAME', 'DS_P_ASS', 'DS_PARAM', 'DS_PRAGM', 'DS_SELEC', 'DS_STM', 'DS_UPDNW', 'Q_ALIAS_', 'Q_AT_STM', 'Q_BINARY', 'Q_BIND', 'Q_C_BODY',
    'Q_C_CALL', 'Q_C_DECL', 'Q_CHAR', 'Q_CLOSE_', 'Q_CLUSTE', 'Q_COMMIT', 'Q_COMMNT', 'Q_CONNEC', 'Q_CREATE', 'Q_CURREN', 'Q_CURSOR', 'Q_DATABA', 
    'Q_DATE', 'Q_DB_COM', 'Q_DECIMA', 'Q_DELETE', 'Q_DICTIO', 'Q_DROP_S', 'Q_EXP', 'Q_EXPR_S', 'Q_F_CALL', 'Q_FETCH_', 'Q_FLOAT', 'Q_FRCTRN', 'Q_GENSQL', 
    'Q_INSERT', 'Q_LEVEL', 'Q_LINK', 'Q_LOCK_T', 'Q_LONG_V', 'Q_NUMBER', 'Q_OPEN_S', 'Q_ORDER_', 'Q_RLLBCK', 'Q_ROLLBA', 'Q_ROWNUM', 'Q_S_TYPE', 
    'Q_SAVEPO', 'Q_SCHEMA', 'Q_SELECT', 'Q_SEQUE', 'Q_SET_CL', 'Q_SMALLI', 'Q_SQL_ST', 'Q_STATEM', 'Q_SUBQUE', 'Q_SYNON', 'Q_TABLE', 'Q_TBL_EX', 
    'Q_UPDATE', 'Q_VAR', 'Q_VARCHA', 'Q_VIEW', 'QI_BIND_', 'QI_CURSO', 'QI_DATAB', 'QI_SCHEM', 'QI_TABLE', 'QS_AGGR', 'QS_SET_C', 'D_ADT_BODY', 
    'D_ADT_SPEC', 'D_CHARSET_SPEC', 'D_EXT_TYPE', 'D_EXTERNAL', 'D_LIBRARY', 'D_S_PT', 'D_T_PTR', 'D_T_REF', 'D_X_CODE', 'D_X_CTX', 'D_X_FRML', 'D_X_NAME',
    'D_X_RETN', 'D_X_STAT', 'DI_LIBRARY', 'DS_X_PARM', 'Q_BAD_TYPE', 'Q_BFILE', 'Q_BLOB', 'Q_CFILE', 'Q_CLOB', 'Q_RTNING', 'D_FORALL', 'D_IN_BIND', 'D_IN_OUT_BIND', 
    'D_OUT_BIND', 'D_S_OPER', 'D_X_NAMED_RESULT', 'D_X_NAMED_TYPE', 'DI_BULK_ITER', 'DI_OPSP', 'DS_USING_BIND', 'Q_BULK', 'Q_DOPEN_STM', 'Q_DSQL_ST', 'Q_EXEC_IMMEDIATE', 
    'D_PERCENT', 'D_SAMPLE', 'D_ALT_TYPE', 'D_ALTERN_EXP', 'D_AN_ALTER', 'D_CASE_EXP', 'D_COALESCE', 'D_ELAB', 'D_IMPL_BODY', 'D_NULLIF', 'D_PIPE', 'D_SQL_STMT', 
    'D_SUBPROG_PROP', 'VTABLE_ENTRY');
    
    

    function get_node (p_idx number) return number 
    is
        l_node number;
    begin
        select val into l_node 
        from uw_diana 
        where idx = p_idx 
          and p = 1;
        return l_node;
    end get_node;

    function subnode (p_idx number, seq number) return number 
    is
        l_idx number;
    begin
        select i5.val into l_idx 
        from uw_diana i2,
             uw_diana i5
        where (i2.val+seq) = i5.idx(+)
          and i2.idx = p_idx
          and i2.p = 2 and i5.p = 5;
        return l_idx;
    end subnode;

    function get_lex (p_idx number) return varchar2
    is
        l_str varchar2(4000);
    begin
        select l.src into l_str 
        from uw_diana i2,
             uw_diana i5,
             uw_lex l
        where i2.val = i5.idx(+)
          and i2.idx = p_idx
          and i5.val = l.idx(+)
          and i2.p = 2 and i5.p = 5;
        return l_str;
    end get_lex;

    function get_lex_direct (p_idx number) return varchar2
    is
        l_str varchar2(4000);
    begin
        select l.src into l_str 
        from uw_lex l
        where l.idx = p_idx;
        return l_str;
    end get_lex_direct;

    function get_node_name (p_nid number) return varchar2 is
    begin
        return l_node_name(p_nid);
    end get_node_name;


    procedure get_len (p_idx number, list_length in out number, list_offset in out number) is
    begin
        select i6.val, i6.idx into list_length,  list_offset
        from uw_diana i2,
             uw_diana i5,
             uw_diana i6
        where i2.val = i5.idx(+)
          and i2.idx = p_idx
          and i5.val = i6.idx(+)
          and i2.p = 2 and i5.p = 5 and i6.p = 6;
    end get_len;

    function get_len2 (p_idx number, p_attr_idx number) return number
    is
        l_len number;
    begin
        select i6.val into l_len 
        from uw_diana i2,
             uw_diana i5,
             uw_diana i6
        where (i2.val+p_attr_idx) = i5.idx(+)
          and i2.idx = p_idx
          and i5.val = i6.idx(+)
          and i2.p = 2 and i5.p = 5 and i6.p = 6;
        return l_len;
    EXCEPTION WHEN OTHERS THEN
        return 0;
    end get_len2;


    procedure get_len3 (p_idx number, p_attr_idx number, list_length in out number, list_offset in out number) is
    begin
        select i6.val, i6.idx into list_length,  list_offset 
        from uw_diana i2,
             uw_diana i5,
             uw_diana i6
        where (i2.val+p_attr_idx) = i5.idx(+)
          and i2.idx = p_idx
          and i5.val = i6.idx(+)
          and i2.p = 2 and i5.p = 5 and i6.p = 6;
    EXCEPTION WHEN OTHERS THEN
        null;
    end get_len3;


    function get_list (p_offset number, seq number) return number
    is
        l_val number;
    begin
        select val into l_val
          from uw_diana
          where p = 6
            and idx = p_offset + seq;
        return l_val;
    EXCEPTION
      WHEN OTHERS THEN
        return 0;
    end get_list;
    
    -- to be done
    procedure ident (p_level number) is
    begin
        null;
        --dbms_output.put( LPAD(' ', p_level*2) );
    end ident;



    procedure recurse (p_idx number, p_lvl number) is --we pass the idx not the node
        len integer;
        n number;
        list_length number;
        list_offset number;
        a_up number;
        l_level number;
        l_oper varchar2(100);
        l_string varchar2(32767);
   begin

        if p_idx = 0 then
            return;
        end if;
        
--        l_level := p_lvl + 1;

        n := get_node(p_idx);


/*
0	9	A_CONTEX	1	1
1	40	A_UNIT_B	1	1
2	62	AS_PRAGM	1	1
3	114	SS_SQL	    30	0
4	113	SS_EXLST	30	0
5	111	SS_BINDS	30	0
6	41	A_UP	    1	0
7	138	A_AUTHID	2	0
8	142	A_SCHEMA	2	0
*/        
        if( n = 23) then --top of DIANA   --  diana.d_comp_u
            --recurse( subnode(p_idx,0), l_level ); -- ??
            recurse( subnode(p_idx,1), l_level );   -- D_S_BODY
            --recurse( subnode(p_idx,2), l_level ); -- to be done

            
/*
0	10	A_D_	    1	1
1	21	A_HEADER	1	1
2	4	A_BLOCK_	1	1
3	41	A_UP	    1	0
*/
        elsif( n = 104 ) then --diana.d_s_body
            recurse( subnode(p_idx,0), l_level );
            recurse( subnode(p_idx,1), l_level );
            recurse( subnode(p_idx,2), l_level );


/*
0	56	AS_ITEM	    1	1
1	64	AS_STM	    1	1
2	43	AS_ALTER	1	1
3	69	C_OFFSET	3	0
4	114	SS_SQL	    30	0
5	66	C_FIXUP	    11	0
6	79	S_BLOCK	    1	0
7	103	S_SCOPE	    1	0
8	88	S_FRAME	    1	0
9	41	A_UP	    1	0
10	92	S_LAYER	    6	0
11	135	S_FLAGS	    4	0
*/
        elsif( n = 17 ) then --d_block
            a_up := get_node((subnode(p_idx,9)));
            if a_up not in (183) then           -- DS_STM
                dbms_output.put_line(' IS --' || l_level);
            end if;
            -- local variables
            if a_up in (183) then       -- DS_STM
                ident(l_level);
                dbms_output.put_line('DECLARE');
            end if;
            recurse( subnode(p_idx,0), l_level );   -- DS_ITEM
            if a_up not in (189) then       -- Q_C_BODY
                ident(l_level);
                dbms_output.put_line('BEGIN --' || l_level);
            end if;
            recurse( subnode(p_idx,1), l_level );   -- DS_BODY
            recurse( subnode(p_idx,2), l_level );   -- DS_ALTER
            if a_up not in (189) then       -- Q_C_BODY
                ident(l_level);
                dbms_output.put('END');
            end if;
            if a_up not in (104, 164, 177, 189) then       -- D_S_BODY, DS_ALTER, DS_ITEM, Q_C_BODY
                dbms_output.put_line(';--d_block:' || p_idx);
            end if;



/*
0	57	AS_LIST	30	1
1	41	A_UP	1	0
*/
        elsif( n = 183 ) then --ds_stm
            get_len( p_idx, list_length, list_offset );
            for i in 1..list_length loop
                recurse( get_list(LIST_OFFSET,i), l_level ); 
            end loop;


/*
0	75	L_SYMREP	2	0
1	105	S_SPEC	    1	0
2	80	S_BODY	    1	0
3	93	S_LOCATI	6	0
4	107	S_STUB	    1	0
5	87	S_FIRST	    1	0
6	69	C_OFFSET	3	0
7	66	C_FIXUP	    11	0
8	67	C_FRAME_	3	0
9	65	C_ENTRY_	3	0
10	88	S_FRAME 	1	0
11	41	A_UP	    1	0
12	92	S_LAYER	    6	0
13	131	L_RESTRICT_REFERENCES	3	0
14	123	A_METH_FLAGS	3	0
15	137	SS_PRAGM_L	    1	0
16	146	S_INTRO_VERSION	3	0
17	163	A_PARALLEL_SPEC	1	0
18	172	C_VT_INDEX	    4	0
19	171	C_ENTRY_PT	    3	0
*/
        elsif( n = 154 ) then --di_proc
            dbms_output.put( 'PROCEDURE ' || get_lex(p_idx) );


/*
0	75	L_SYMREP	2	0
1	105	S_SPEC	    1	0
2	80	S_BODY	    1	0
3	93	S_LOCATI	6	0
4	107	S_STUB	    1	0
5	87	S_FIRST	    1	0
6	69	C_OFFSET	3	0
7	66	C_FIXUP	    11	0
8	67	C_FRAME_	3	0
9	65	C_ENTRY_	3	0
10	88	S_FRAME	    1	0
11	41	A_UP	    1	0
12	92	S_LAYER	    6	0
13	131	L_RESTRICT_REFERENCES	3	0
14	123	A_METH_FLAGS	3	0
15	137	SS_PRAGM_L	    1	0
16	146	S_INTRO_VERSION	3	0
17	163	A_PARALLEL_SPEC	1	0
18	172	C_VT_INDEX	    4	0
19	171	C_ENTRY_PT	    3	0
*/
        elsif( n = 141 ) then --DI_FUNCT
            dbms_output.put_line( 'FUNCTION ' || get_lex(p_idx) );


/*
0	57	AS_LIST	30	1
*/
        elsif( n = 180 ) then -- 180 DS_PARAM
            get_len(p_idx, list_length, list_offset); -- list_... are IN OUT
            if list_length > 0 then
                dbms_output.put( '(' );
                for i in 1..list_length loop
                    recurse( get_list(LIST_OFFSET,i), l_level );
                    if i < list_length then
                        dbms_output.put( ', ' );
                    end if;
                end loop;
                dbms_output.put( ') ' );
              end if;
              

        -- parameter definition
        elsif( n = 61 ) then           --d_in declare IN param
            recurse( subnode(p_idx,0), l_level );
            recurse( subnode(p_idx,1), l_level );
            --default value
            if ( get_len2(p_idx,2) != 0 ) then
                dbms_output.put( ' := ' );
                recurse( subnode(p_idx,2), l_level ); 
            end if;


        -- parameter definition
        elsif( n = 84 ) then           --D_OUT declare OUT param
            recurse( subnode(p_idx,0), l_level );
            dbms_output.put( 'OUT ' );
            recurse( subnode(p_idx,1), l_level );
            --default value
            if ( get_len2(p_idx,2) != 0 ) then
                dbms_output.put( ' := ' );
                recurse( subnode(p_idx,2), l_level ); 
            end if;


        -- parameter definition
        elsif( n = 63 ) then           --D_IN_OUT declare IN OUT param
            recurse( subnode(p_idx,0), l_level );
            dbms_output.put( 'IN OUT ' );
            recurse( subnode(p_idx,1), l_level );
            --default value
            if ( get_len2(p_idx,2) != 0 ) then
                dbms_output.put( ' := ' );
                recurse( subnode(p_idx,2), l_level ); 
            end if;



        elsif( n = 143 ) then           -- di_in parameter name
          dbms_output.put( ' ' || get_lex(p_idx) || '  ');

        elsif( n = 150 ) then           -- DI_OUT parameter name
          dbms_output.put( ' ' || get_lex(p_idx) || '  ');

        elsif( n = 144 ) then           -- DI_IN_OU parameter name
          dbms_output.put( ' ' || get_lex(p_idx) || '  ');


        elsif( n = 176 ) then --ds_id
            get_len(p_idx, list_length, list_offset);
            for i in 1..list_length loop
                recurse( get_list(LIST_OFFSET,i), l_level ); 
            end loop;

/*
0	75	L_SYMREP	    2	0
1	83	S_DEFN_PRIVATE	1	0
2	112	SS_BUCKE	    11	0
3	71	L_DEFAUL	    3	0
*/
        elsif( n = 160 ) then        --DI_U_NAM print from lex
          dbms_output.put( get_lex(p_idx));

/*
0	60	AS_P_	    1	1
1	98	S_OPERAT	10	0
2	30	A_P_IFC	    1	0
3	41	A_UP	    1	0
*/
        -- PROCEDUTE
        elsif( n = 85 ) then -- d_p_
            recurse( subnode(p_idx,0), l_level );

        -- FUNCTION
        elsif( n = 44 ) then -- d_f_ declare function params
            get_len( subnode(p_idx,0), list_length, list_offset );
            if LIST_LENGTH > 0 then
                dbms_output.put_line('(  ');
                for i in 1..LIST_LENGTH loop
                    if (i>1) then 
                        dbms_output.put_line(',');
                    end if;
                    recurse( get_list(LIST_OFFSET,i), l_level );
                end loop;
                dbms_output.put_line( cr || ') ' );
            end if;
            ident(l_level);
            dbms_output.put('RETURN ');
            recurse( subnode(p_idx,1), l_level );


        elsif( n = 177 ) then   -- 177 ds_item
            get_len( p_idx, list_length, list_offset );
            for i in 1..list_length loop
                recurse( get_list(LIST_OFFSET,i), l_level );
                dbms_output.put_line( ';--DS_ITEM:' || p_idx );
            end loop;

        -- private variable definition
        elsif( n = 129 ) then --d_var
            recurse( subnode(p_idx,0), l_level );
            recurse( subnode(p_idx,1), l_level );
            if ( get_len2(p_idx,2) != 0 ) then
                dbms_output.put( ' := ' );
                recurse( subnode(p_idx,2), l_level );
            end if;

        elsif( n = 119  ) then             -- D_TYPE declare TYPE
            recurse( subnode(p_idx,0), l_level );
            recurse( subnode(p_idx,1), l_level );
            recurse( subnode(p_idx,2), l_level );

/*
0	50	AS_DSCRT	1	1
1	7	A_CONSTD	1	1
2	104	S_SIZE	    1	0
3	99	S_PACKIN	1	0
4	128	A_TFLAG	    3	0
*/
        elsif( n = 12 ) then           -- D_ARRAY declare VARRAY or TABLE OF
            if  subnode(p_idx,4) = 2 then --  VARRAY 
                dbms_output.put('VARRAY(' );
                get_len( subnode(p_idx,0), list_length, list_offset );
                recurse( subnode(get_list(LIST_OFFSET,1) ,1), l_level );
                dbms_output.put( ') OF ' );
                recurse( subnode(p_idx,1), l_level ); 
            elsif subnode(p_idx,4) = 0 then    -- TABLE OF
                dbms_output.put('TABLE OF ');
                recurse( subnode(p_idx,1), l_level ); -- D_CONSTR
                recurse( subnode(p_idx,0), l_level ); -- D_INDEX
            else -- No Idea what subnode(p_idx,4) = 1 is or 3 (if exists)
                dbms_output.put_line('  -- COLLECTION not implemented Node:' || n || ' Name:' || get_node_name(n) || ' idx:' || p_idx) ;
            end if;

        elsif( n = 64 ) then --D_INDEX
            dbms_output.put( ' INDEX BY ' );
            recurse( subnode(p_idx,0), l_level );  -- go to D_CONSTR

        -- private CONSTANT definition
        elsif( n = 27 ) then           --D_CONSTA declare CONSTANT
            recurse( subnode(p_idx,0), l_level );
            dbms_output.put( ' ' );
            recurse( subnode(p_idx,1), l_level );
            if ( get_len2(p_idx,2) != 0 ) then
                dbms_output.put( ' := ' );
                recurse( subnode(p_idx,2), l_level ); 
            end if;

        elsif( n = 163 ) then --di_var
          dbms_output.put( '  ' || get_lex(p_idx) || ' ');

        elsif( n = 157 ) then           -- DI_TYPE declare TAPE NAME
          dbms_output.put( '  TYPE ' || get_lex(p_idx) || ' IS ');


        elsif( n = 168 ) then           -- DS_D_RAN RANGE / INTERVAL
            get_len( p_idx, list_length, list_offset );
            for i in 1..list_length loop
                recurse( get_list(LIST_OFFSET,i), l_level );
                if i < list_length then  dbms_output.put_line(','); end if;
            end loop;

        elsif( n = 135 ) then --DI_CONST
          dbms_output.put( '  ' || get_lex(p_idx) || ' CONSTANT');

        elsif( n = 96 ) then --D_R_
            dbms_output.put_line( ' RECORD (' );
            get_len( p_idx, list_length, list_offset );
            for i in 1..list_length loop
                dbms_output.put('  ');
                recurse( get_list(LIST_OFFSET,i), l_level );
                if i < list_length then  dbms_output.put_line(','); end if;
            end loop;
            dbms_output.put( '  )' );

        elsif( n = 28 ) then --D_CONSTR
            recurse( subnode(p_idx,0), l_level ); -- data type
            if ( get_len2( subnode(p_idx,1),0 ) != 0 ) then
                dbms_output.put( '(' );
                recurse( subnode(p_idx,1), l_level );
                dbms_output.put( ')'  );
            end if;

        elsif( n = 15 ) then --D_ATTRIB
            recurse( subnode(p_idx,0), l_level );
            dbms_output.put( '%' );
            recurse( subnode(p_idx,1), l_level );

/*
0	26	A_NAME	    1	1
1	11	A_D_CHAR	1	1
2	86	S_EXP_TY	1	0
*/
        elsif( n = 107  ) then --D_S_ED
            recurse( subnode(p_idx,0), l_level );
            dbms_output.put( '.' );
            recurse( subnode(p_idx,1), l_level );
            

        elsif( n = 165 ) then --DS_APPLY
            get_len( p_idx, list_length, list_offset );
            for i in 1..list_length loop
                if i > 1 then dbms_output.put( ',' ); end if;
                recurse( get_list(LIST_OFFSET,i), l_level ); 
            end loop;

        elsif( n = 11 ) then --D_APPLY
            recurse( subnode(p_idx,0), l_level );
            dbms_output.put( '(' );
            recurse( subnode(p_idx,1), l_level );
            dbms_output.put( ')' );


/*
0	26	A_NAME	    1	1
1	15	A_EXP	    1	1
2	69	C_OFFSET	3	0
3	41	A_UP	    1	0
*/
        elsif( n = 13 ) then --D_ASSIGN
            dbms_output.put( ' ' );
            recurse( subnode(p_idx,0), l_level ); -- left side
            dbms_output.put( ' := ' );
            recurse( subnode(p_idx,1), l_level ); -- rigth side
            dbms_output.put_line( ';--D_ASSIGN:' || p_idx );




/*
0	26	A_NAME	        1	1
1	61	AS_P_ASS	    1	1
2	86	S_EXP_TY	    1	0
3	110	S_VALUE	        4	0
4	94	S_NORMARGLIST	1	0
*/
        -- see diutil body line 425 DS_PARAM=180
        elsif( n = 46  ) then  --D_F_CALL
--            if get_node(subnode(p_idx,1)) != 180  then -- <> DS_PARAM : this is not working properly 
            l_oper := get_lex(subnode(p_idx,0));
            if ( get_node(subnode(p_idx,0)) != 126                    -- <> 126:D_USED_O 
                ---  distinct lex where node_dec = 126 (D_USED_O) 
                or l_oper not in        -- USED_O can be functions like MOD, DIV, ... So let them here as ordinary function call
                ('+', '-', '*', '/', '!=', '||', 'LIKE', '<', 'IS NULL', '>', 'NOT', '=', 'IS NOT NULL', '<>', '>=', '<=') 
            ) 
            then
                -- ordinary function call
                recurse( subnode(p_idx,0), l_level );
                get_len( subnode(p_idx,1), list_length, list_offset );
                if list_length > 0 then
                    dbms_output.put( '(' );
                    for i in 1..list_length loop
                        recurse( get_list(LIST_OFFSET,i), l_level );
                        if i < list_length then
                            dbms_output.put( ', ' );
                        end if;
                end loop;
                dbms_output.put( ')' );
                end if;
            else
                get_len( subnode(p_idx,1), list_length, list_offset );
                if list_length = 0 then --no params
                    recurse( subnode(p_idx,0), l_level );
                elsif list_length = 1 then --unary 
                    if l_oper like ('IS%') then     --IF not X / if X is not null
                        recurse( get_list(LIST_OFFSET,1), l_level );
                        recurse( subnode(p_idx,0), l_level );
                    else
                        recurse( subnode(p_idx,0), l_level );
                        dbms_output.put( ' ' );
                        recurse( get_list(LIST_OFFSET,1), l_level );
                    end if;
                else
                    for i in 1..list_length loop
                        recurse( get_list(LIST_OFFSET,i), l_level );
                        if i < list_length then
                            dbms_output.put( ' ' );
                            recurse( subnode(p_idx,0), l_level );
                            dbms_output.put( ' ' );
                        end if;
                    end loop;
                end if;
            end if;




/*
0	26	A_NAME	        1	1
1	61	AS_P_ASS	    1	1
2	94	S_NORMARGLIST	1	0
3	69	C_OFFSET	    3	0
4	41	A_UP	        1	0
*/
        elsif( n = 87  ) then  --D_P_CALL
            -- ordinary procedure call
            recurse( subnode(p_idx,0), l_level );
            get_len( subnode(p_idx,1), list_length, list_offset );
            if list_length > 0 then
                dbms_output.put( '(' );
                for i in 1..list_length loop
                    recurse( get_list(LIST_OFFSET,i), l_level );
                    if i < list_length then
                        dbms_output.put( ', ' );
                    end if;
                end loop;
                dbms_output.put_line( ');' );
            else
                dbms_output.put_line( ';--D_P_CALL:' || p_idx );
            end if;



        -- cursor declaration
        elsif( n = 189  ) then  --Q_C_BODY declare explicit cursor
            is_not_cur := false;
            dbms_output.put( '  CURSOR ' );
            recurse( subnode(p_idx,0), l_level );        --cursor info
            --dbms_output.put_line( ' IS' );
            recurse( subnode(p_idx,1), l_level );        --cursor parameters
            recurse( subnode(p_idx,2), l_level );        --body blocks info    D_BLOCK inserts begin    
            is_not_cur := true;

        elsif( n = 244  ) then  --QI_CURSO  cursor info
            dbms_output.put( get_lex(p_idx) || ' ' );
            
        elsif( n = 200  ) then  --Q_CURSOR  cursor parameters
            recurse( subnode(p_idx,0), l_level ); --ds_param

/*
0	27	A_NAME_V	1	1
1	34	A_STM	    1	1
2	69	C_OFFSET	3	0
3	70	C_VAR	    9	0
4	41	A_UP	    1	0
*/            
        elsif( n = 233  ) then  --Q_SQL_ST  execute sql statement
            recurse( subnode(p_idx,1), l_level ); --A_STM


/* 229	Q_SELECT
0	15	A_EXP	    1	1
1	55	AS_INTO_	1	1
2	59	AS_ORDER	1	1
3	97	S_OBJ_TY	1	0
4	58	AS_NAME	    1	1
5	135	S_FLAGS	    4	0*/
        elsif( n = 229  ) then  --Q_SELECT  SELECT statement
            dbms_output.put( '  SELECT ' ); --if any
            recurse( subnode(p_idx,0), l_level ); --A_EXP Q_EXP
            recurse( subnode(p_idx,1), l_level ); --AS_INTO_
            if get_len2( subnode(p_idx,2), 0 ) > 0 then
                dbms_output.put( cr || '  ORDER BY ' );
                recurse( subnode(p_idx,2), l_level ); --AS_ORDER
            end if;
            dbms_output.put_line( ';--Q_SELECT:' || p_idx );


/*
0	71	L_DEFAUL	3	0
1	51	AS_EXP	1	1
2	15	A_EXP	1	1
3	74	L_Q_HINT	2	0
*/
        elsif( n = 208  ) then  --Q_EXP         query info
             --subnode(p_idx,1) ) -- make list columns
            get_len( subnode(p_idx,1), list_length, list_offset );
            if list_length > 0 then
                for i in 1..list_length loop
                    recurse( get_list(LIST_OFFSET,i), l_level );
                    if i < list_length then
                        dbms_output.put( ', ' );
                    end if;
                end loop;
                dbms_output.put_line( ' ' );
            else 
                dbms_output.put( '*' );
            end if;
            recurse( subnode(p_idx,2), l_level ); -- Q_TBL_EX


/*
0	52	AS_FROM	    1	1
1	42	A_WHERE	    1	1
2	6	A_CONNEC	1	1
3	53	AS_GROUP	1	1 
4	20	A_HAVING	1	1
5	79	S_BLOCK	    1	0
6	92	S_LAYER	    6	0
*/
        elsif( n = 238  ) then  --Q_TBL_EX  
            dbms_output.put( ' FROM ' );
            get_len( subnode(p_idx,0), list_length, list_offset ); 
            if list_length > 0 then
                for i in 1..list_length loop
                    recurse( get_list(LIST_OFFSET,i), l_level );
                    if i < list_length then
                        dbms_output.put( ', ' );
                    end if;
                end loop;
                --dbms_output.put_line( ' ' );
            end if;
            if subnode(p_idx,1) != 0 then
                dbms_output.put( cr || ' WHERE ' ); 
                recurse( subnode(p_idx,1), l_level ); -- A_WHERE to D_BINARY
            end if;
            recurse( subnode(p_idx,2), l_level );     --A_CONNEC
            --  TO DO



/*
0	16	A_EXP1	    1	1
1	3	A_BINARY	1	1
2	17	A_EXP2	    1	1
3	86	S_EXP_TY	1	0
4	110	S_VALUE	    4	0
*/
        elsif( n = 16 ) then --D_BINARY execute binar-logic expression
            recurse( subnode(p_idx,0), l_level );
            recurse( subnode(p_idx,1), l_level );
            recurse( subnode(p_idx,2), l_level );
            --dbms_output.put( ' D_BINARY ' ); 

        elsif( n = 10 ) then --D_AND_TH
            dbms_output.put( ' AND ' ); 


        elsif( n = 172 ) then --DS_EXP
            get_len( p_idx, list_length, list_offset ); 
            if list_length > 0 then
                for i in 1..list_length loop
                    recurse( get_list(LIST_OFFSET,i), l_level );
                    if i < list_length then
                        dbms_output.put( ', ' );
                    end if;
                end loop;
                --dbms_output.put_line( ' ' );
            end if;


        elsif( n = 185 ) then --Q_ALIAS_
            dbms_output.put( get_lex(subnode(p_idx,0)) || ' ' ); -- table name
            dbms_output.put( get_lex(subnode(p_idx,1)) );        -- alias

/*
0	71	L_DEFAUL	3	0
1	15	A_EXP	1	1
*/
        elsif( n = 222 ) then --Q_ORDER_
            recurse( subnode(p_idx,1), l_level );
            if subnode(p_idx,0) = 1 then 
                dbms_output.put( ' ASC' );
            elsif subnode(p_idx,0) = 2 then 
                dbms_output.put( ' DESC' );
            end if;


        elsif( n = 126 ) then --D_USED_O
            dbms_output.put( ' ' || get_lex(p_idx) );

        elsif( n =  90 ) then --D_PARENT
            dbms_output.put( '(' );
            recurse( subnode(p_idx,0), l_level );
            dbms_output.put( ')' );

        elsif( n = 81 ) then --D_NUMERI
            dbms_output.put( get_lex(p_idx) );

        elsif( n = 110 ) then --D_STRING
            l_string := get_lex(p_idx);
            if instr(l_string,'''') != 0 then
                dbms_output.put( 'q''~' || get_lex(p_idx) || '~''' );
            else
                dbms_output.put( ''''||get_lex(p_idx)||'''');
            end if;


        elsif( n = 101 ) then --D_RETURN
            dbms_output.put( ' RETURN ');
            recurse( subnode(p_idx,0), l_level );
            dbms_output.put_line( ';--Q_RETURN:' || p_idx );

        elsif( n = 77 ) then  --d_null_a
            dbms_output.put('NULL');
        elsif( n = 78 ) then  --d_null_c
            null;
        elsif( n = 79 ) then  --d_null_s
            dbms_output.put('NULL;');

        elsif( n = 42 ) then  --D_EXCEPT
            recurse( subnode(p_idx,0), l_level );

        -- needs more work
        elsif( n = 139 ) then  --DI_EXCEP
            dbms_output.put('  ' || get_lex(p_idx) || ' EXCEPTION' );


/*empty*/
        elsif( n = 62 ) then  --D_IN_OP 
            null;
--            range_link := ' AND ';
--            dbms_output.put( ' BETWEEN '  );

/*
0	15	A_EXP	1	1
1	25	A_MEMBER	1	1
2	38	A_TYPE_R	1	1
*/
        elsif( n = 72 ) then  --D_MEMBER --execute set/range operation
            recurse( subnode(p_idx,0), l_level );
--            recurse( subnode(p_idx,1) );  -- D_IN_OP: in, between / ???
            if get_node(subnode(p_idx,2)) = 99 then --D_RANGE
                range_link := ' AND ';
                dbms_output.put( ' BETWEEN '  );
            elsif get_node(subnode(p_idx,2)) = 5 then --D_AGGREG
                aggreg_link := ', ';
                dbms_output.put( ' IN ('  );
            end if;
            recurse( subnode(p_idx,2), l_level );
            if get_node(subnode(p_idx,2)) = 5 then --D_AGGREG
                dbms_output.put( ')'  );
            end if;

/*
0	16	A_EXP1	1	1
1	17	A_EXP2	1	1
2	78	S_BASE_T	1	0
3	177	S_LENGTH_SEMANTICS	3	0
*/
        elsif( n = 99 ) then  --D_RANGE ???
            --dbms_output.put( get_lex(subnode(p_idx,0))  );
            recurse( subnode(p_idx,0), l_level );
            dbms_output.put( range_link  );
            --dbms_output.put( get_lex(subnode(p_idx,1))  );
            recurse( subnode(p_idx,1), l_level );


/*
0	26	A_NAME	        1	1
1	61	AS_P_ASS	    1	1
2	94	S_NORMARGLIST	1	0
3	41	A_UP	        1	0
*/
        elsif( n = 221 ) then  --Q_OPEN_S
            dbms_output.put( ' OPEN '  );
            dbms_output.put( get_lex(subnode(p_idx,0))  );
            if get_len2( subnode(p_idx,1),0) != 0 then
--                dbms_output.put( ' bebug:' || subnode(p_idx,1) || ':end_debug ' );
                dbms_output.put( '('  );
                recurse( subnode(p_idx,1), l_level );
                dbms_output.put( ')'  );
            end if;
            dbms_output.put_line( ';--Q_OPEN_S:' || p_idx  );


/*
0	26	A_NAME	1	1
1	41	A_UP	1	0
*/
        elsif( n = 193 ) then  --Q_CLOSE_
            dbms_output.put( ' CLOSE '  );
            dbms_output.put( get_lex(subnode(p_idx,0))  );
            dbms_output.put_line( ';--Q_CLOSE:' || p_idx );


/*
0	24	A_ITERAT	1	1       --0 or FOR or ???
1	64	AS_STM	    1	1
2	69	C_OFFSET	3	0
3	66	C_FIXUP	    11	0
4	79	S_BLOCK	    1	0
5	103	S_SCOPE	    1	0
6	41	A_UP	    1	0
*/
        elsif( n = 71 ) then  --D_LOOP
            recurse( subnode(p_idx,0), l_level );
            dbms_output.put_line(  ' LOOP' );
            recurse( subnode(p_idx,1), l_level );
            dbms_output.put_line(  ' END LOOP; '  );


/*
0	22	A_ID	1	1
1	12	A_D_R_	1	1
*/
        elsif( n = 55 ) then  --D_FOR
            dbms_output.put(  ' FOR ' );
            recurse( subnode(p_idx,0), l_level );
            dbms_output.put(  ' IN ' );
            range_link := '..';
            if get_node(subnode(p_idx,1)) = 298 then dbms_output.put(  '(' ); end if;
            recurse( subnode(p_idx,1), l_level );
            if get_node(subnode(p_idx,1)) = 298 then dbms_output.put(  ')' ); end if;


        elsif( n = 145 ) then  --DI_ITERA
            dbms_output.put( get_lex( p_idx) );



/*
0	26	A_NAME	1	1
1	22	A_ID	1	1
2	41	A_UP	1	0
3	135	S_FLAGS	4	0
4	147	A_LIMIT	1	1
*/
        elsif( n = 211 ) then  --Q_FETCH_
            dbms_output.put(  ' FETCH '  );
            dbms_output.put( get_lex(subnode(p_idx,0))  );
            dbms_output.put(  ' INTO '  );
            aggreg_link := ', ';
            recurse( subnode(p_idx,1), l_level );
            dbms_output.put_line(  ';--Q_FETCH_' || p_idx  );
            aggreg_link := ' AND ';

/*
0	27	A_NAME_V	1	1
1	18	A_EXP_VO	1	1
2	106	S_STM	    1	0
3	69	C_OFFSET	3	0
4	79	S_BLOCK	    1	0
5	41	A_UP	    1	0
*/
        elsif( n = 43 ) then  --D_EXIT
            dbms_output.put(  ' EXIT '  );
            recurse( subnode(p_idx,0), l_level );
            if subnode(p_idx,1) != 0 then
                dbms_output.put(  ' WHEN '  );
                recurse( subnode(p_idx,1), l_level );
            end if;
            dbms_output.put_line(  ';--D_EXIT:' || p_idx  );



/*
0	157	A_HANDLE	    9  	0
1	162	A_ORIGINAL	    2	0       <= link to lex
2	159	A_KIND	        4	0       <= 1 ???
3	175	S_CURRENT_OF	1	1
4	182	SS_LOCALS	    30	1
5	181	SS_INTO	        30	1
6	178	S_STMT_FLAGS	3	0
7	180	SS_FUNCTIONS	30	0
8	183	SS_TABLES	    30	0
9	97	S_OBJ_TY	    1	0
10	69	C_OFFSET	    3	0        
11	41	A_UP	        1	0       
*/
        elsif( n = 298 ) then  --D_SQL_STMT  ??? ONLY for: plain text of SQL statement
            dbms_output.put( get_lex_direct(subnode(p_idx,1))  );
            if get_node(subnode(p_idx,11)) in (177, 183) then           --DS_ITEM DS_STM
                dbms_output.put_line(  ';--D_SQL_STMT:' || p_idx  );
            end if;
            



/*
0	57	AS_LIST	    30	1
1	69	C_OFFSET	3	0
2	41	A_UP	    1	0
*/
        elsif( n = 60 ) then  --D_IF
            get_len( p_idx, list_length, list_offset ); 
            if list_length > 0 then
                for i in 1..list_length loop
--                    if i = 1 then --i < list_length
--                        dbms_output.put( '  IF ' );
                    if i > 1 then
                        dbms_output.put( '  ELS' );
                    end if;
                    recurse( get_list(LIST_OFFSET,i), l_level ); --D_COND_C
                end loop;
                --dbms_output.put_line( ' ' );
            end if;
            dbms_output.put_line( '  END IF; --' || p_idx );
/*
0	18	A_EXP_VO	1	1
1	64	AS_STM	    1	1
2	103	S_SCOPE	    1	0
3	41	A_UP	    1	0
*/
        elsif( n = 25 ) then  --D_COND_C
            if subnode(p_idx,0) != 0 then
                dbms_output.put( 'IF ' );
                recurse( subnode(p_idx,0), l_level );
                dbms_output.put_line( ' THEN --D_COND_C:' ||  p_idx  );
                recurse( subnode(p_idx,1), l_level );
            else
                dbms_output.put( 'E ' );
                recurse( subnode(p_idx,1), l_level );
            end if;




/*
0	34	A_STM	                1	1
1	69	C_OFFSET	            3	0
2	131	L_RESTRICT_REFERENCES	3	0
3	41	A_UP	                1	0
*/
        elsif( n = 285 ) then  --Q_DSQL_ST
            recurse( subnode(p_idx,0), l_level );



/*
0	143	A_STM_STRING	1	1
1	22	A_ID	        1	1
2	145	AS_USING_	    1	1
3	126	A_RTNING	    1	1
4	135	S_FLAGS	        4 	0
*/
        elsif( n = 286 ) then  -- Q_EXEC_IMMEDIATE ???
            dbms_output.put( ' EXECUTE IMMEDIATE ' );
            recurse( subnode(p_idx,0), l_level );
            recurse( subnode(p_idx,2), l_level );
            dbms_output.put_line( ';--Q_EXEC_IMMEDIATE:' ||  p_idx );


/*
0	26	A_NAME	        1	1
1	143	A_STM_STRING	1	1
2	145	AS_USING_	    1	1
*/
        elsif( n = 284 ) then  -- Q_DOPEN_STM
            dbms_output.put( ' OPEN ' );
            recurse( subnode(p_idx,0), l_level );
            dbms_output.put( ' FOR ' );
            recurse( subnode(p_idx,1), l_level  ); -- we don't need the ('), 
            --dbms_output.put( 'q''~' || get_lex(subnode(p_idx,1)) || '~''' );
            recurse( subnode(p_idx,2), l_level ); -- USING  if any
            dbms_output.put_line( ';--Q_DOPEN_STM:' || p_idx );
            


/*
0	57	AS_LIST	30	1
*/
        elsif( n = 282 ) then  -- DS_USING_BIND
            get_len( p_idx, list_length, list_offset ); 
            if list_length > 0 then
                dbms_output.put( ' USING ' ); 
                for i in 1..list_length loop
                    recurse( get_list(LIST_OFFSET,i), l_level ); --D_COND_C
                    if i < list_length then
                        dbms_output.put( ', ' );
                    end if;
                end loop;
                --dbms_output.put_line( ' ' );
            end if;
--            dbms_output.put_line( '  ;' );



/*
0	15	A_EXP	1	1
*/
        elsif( n = 274 ) then  -- D_IN_BIND
            recurse( subnode(p_idx,0), l_level );


/*
0	26	A_NAME	1	1
*/
        elsif( n = 275 ) then  -- D_IN_OUT_BIND
            dbms_output.put( ' IN OUT ' );
            recurse( subnode(p_idx,0), l_level );


/*
0	26	A_NAME	1	1
*/
        elsif( n = 276 ) then  -- D_OUT_BIND
            dbms_output.put( ' OUT ' );
            recurse( subnode(p_idx,0), l_level );

/*
0	15	A_EXP	    1	1
1	43	AS_ALTER	1	1
2	69	C_OFFSET	3	0
3	41	A_UP	    1	0
4	174	S_CMP_TY	1	0
*/
        elsif( n = 20 ) then  -- D_CASE
            dbms_output.put( '  CASE ' );
            recurse( subnode(p_idx,0), l_level );
            dbms_output.put_line( '' );
            recurse( subnode(p_idx,1), l_level ); -- DS_ALTER
            dbms_output.put_line( '  END CASE;' );





/*
0	57	AS_LIST	30	1
1	79	S_BLOCK	1	0
2	103	S_SCOPE	1	0
3	41	A_UP	1	0 CASE or EXCEPTION
*/
        elsif( n = 164 ) then --DS_ALTER  CASE/EXCEPTION
            get_len( p_idx, list_length, list_offset ); 
            if list_length != 0 then 
                -- CASE or EXCEPTION
                if get_node((subnode(p_idx,3))) in (17) then
                    dbms_output.put( ' EXCEPTION --' || p_idx );
                end if;
                for i in 1..list_length loop
--                    if i = list_length then
--                        dbms_output.put( ' ELSE ' );
--                    end if;
                    recurse( get_list(LIST_OFFSET,i), l_level );  --D_ALTERN
                end loop;
            end if;
            --dbms_output.put_line( ';--DS_ALTER' || p_idx );


/*
0	45	AS_CHOIC	1	1
1	64	AS_STM	    1	1
2	103	S_SCOPE	    1	0
3	69	C_OFFSET	3	0
4	41	A_UP	    1	0
*/
        elsif( n = 9 ) then --D_ALTERN
            recurse( subnode(p_idx,0), l_level ); --DS_CHOIC (when ... then) or (else ... )
            if subnode(p_idx,0) = 0 then 
                dbms_output.put( ' ELSE ' );
            end if;
            recurse( subnode(p_idx,1), l_level );


/*
0	45	AS_CHOIC	1	1
1	15	A_EXP	    1	1
*/
        elsif( n = 290 ) then --D_ALTERN_EXP
            recurse( subnode(p_idx,0), l_level ); --DS_CHOIC (when ... then) or (else ... )
            if subnode(p_idx,0) = 0 then 
                dbms_output.put( ' ELSE ' );
            end if;
            recurse( subnode(p_idx,1), l_level );


/*
0	57	AS_LIST	    30	1
*/
        elsif( n = 166 ) then --DS_CHOIC
            get_len( p_idx, list_length, list_offset );
            dbms_output.put( cr || ' WHEN ' );
            recurse( get_list(LIST_OFFSET,1), l_level );  --OTHERS,...
            dbms_output.put( cr || ' THEN ');


/*empty*/
        elsif( n = 83 ) then --D_OTHERS
            dbms_output.put( ' OTHERS ' );


/*
0	27	A_NAME_V	1	1
1	69	C_OFFSET	3	0
2	41	A_UP	    1	0
*/
        elsif( n = 98 ) then --D_RAISE
            dbms_output.put( ' RAISE ' );
            recurse( subnode(p_idx,0), l_level );
            dbms_output.put_line( ';--D_RAISE:' || p_idx );


/*
0	57	AS_LIST	        30	1
1	86	S_EXP_TY	    1	0
2	82	S_CONSTR	    1	0
3	94	S_NORMARGLIST	1	0
*/
        elsif( n = 5 ) then --D_AGGREG
            get_len( p_idx, list_length, list_offset ); 
            if list_length != 0 then 
                for i in 1..list_length loop
                    recurse( get_list(LIST_OFFSET,i), l_level );
                    if i < list_length then
                        dbms_output.put( aggreg_link );
                    end if;
                end loop;
            end if;


/*
0	15	A_EXP	    1	1
1	57	AS_LIST	    30	1
2	86	S_EXP_TY	1	0
3	174	S_CMP_TY	1	0
*/
        elsif( n = 292 ) then --D_CASE_EXP
            dbms_output.put( '  CASE ' );
            recurse( subnode(p_idx,0), l_level );
            get_len3( p_idx ,1, list_length, list_offset );
            if list_length != 0 then 
                for i in 1..list_length loop
                    recurse( get_list(LIST_OFFSET,i), l_level );
--                    if i < list_length then
--                        dbms_output.put( ' AND ' );
--                    end if;
                end loop;
            end if;
            dbms_output.put_line( '  END' );
            

/*empty*/
        elsif( n = 82 ) then --D_OR_ELS
            dbms_output.put( ' OR ' );


/*
0	10	A_D_	    1	1
1	1	A_ACTUAL	1	1
*/
        elsif( n = 14 ) then --D_ASSOC
            recurse( subnode(p_idx,0), l_level );
            dbms_output.put( ' => ' );
            recurse( subnode(p_idx,1), l_level );
   
        
/*
0	15	A_EXP	1	1
1	41	A_UP	1	0
*/
        elsif( n = 130 ) then --D_WHILE
            dbms_output.put( ' WHILE ' );
            recurse( subnode(p_idx,0), l_level );


/*
0	22	A_ID	    1	1
1	61	AS_P_ASS	1	1
2	41	A_UP	    1	0
*/
        elsif( n = 93 ) then --D_PRAGMA
            dbms_output.put( ' PRAGMA ' );
            recurse( subnode(p_idx,0), l_level );
            recurse( subnode(p_idx,1), l_level );



        else
          --dbms_output.put_line('  -- NOT IMPLEMENTED  Node nr:' || n || ' Name:' || pidl.ptattnnm(n) || ' idx:' || p_idx) ;
            dbms_output.put_line('  -- NOT IMPLEMENTED  Node nr:' || n || ' Name:' || get_node_name(n) || ' idx:' || p_idx) ;
        end if;
        --
    end recurse;


begin

-- use filled tables from previous run
-- for multi K code this saves lot of time
if length(p_name) != 0 then 

    execute IMMEDIATE 'truncate table uw_src';
    execute IMMEDIATE 'truncate table uw_lex';
    execute IMMEDIATE 'truncate table uw_diana';

    select max(line) into l_number_of_lines 
    from user_source where name = upper(p_name);

    FOR i IN 1 .. l_number_of_lines LOOP
        select text into l_sql_line 
        from user_source 
        where name= upper(p_name) 
          and line = i; 
        l_tmp_clob := l_sql_line;
        l_sql_clob := l_sql_clob || l_tmp_clob;
    END LOOP; 

    l_total_length := DBMS_LOB.GETLENGTH( l_sql_clob );
    while l_offset<=l_total_length loop
        l_line_length:=instr(l_sql_clob,chr(10),l_offset)-l_offset;
        if l_line_length<0 then
            l_line_length:=l_total_length+1-l_offset;
        end if;
        l_line:=substr(l_sql_clob,l_offset,l_line_length);
        -- ignore empty lines
        if length(l_line)>0 THEN
            insert into uw_src values (l_idx, l_line);
            l_idx := l_idx + 1;
        end if;
        l_offset:=l_offset+l_line_length+1;
    end loop;


    -- Parse the Lexicon into uw_lex
    select to_number(src,'XXXXXXXX') into section_len --Get Lexicon Length in DEC
        from uw_src where idx = 24; 
    l_idx := 1; 
    l_offset := 26;
    while l_idx<=section_len loop
       select src into l_line
            from uw_src where idx = l_offset; 
        if ( SUBSTR(l_line, -1) = ':') then --line ends
            lex_line := lex_line || REPLACE(SUBSTR(l_line,2,length(l_line)-2 ),'::',':');
            lex_line := REPLACE(lex_line, ':n', chr(10) );
            insert into uw_lex values (l_idx, lex_line);
            lex_line := '';
            l_idx := l_idx + 1;
        elsif (SUBSTR(l_line, -1) = '+') then --line continues
            lex_line := lex_line || REPLACE(SUBSTR(l_line,2,length(l_line)-2 ),'::',':');
        end if;
        l_offset := l_offset + 1;
    end loop;

    -- skip 3 lines with 0
    l_offset := l_offset + 3;

    -- Parse next 6 sections into uw_diana
    for s in 1..6 loop
        l_idx := 0; 
        select to_number(src,'XXXXXXXX') into section_len
          from uw_src where idx = l_offset; 

        l_offset := l_offset + 2;

        while l_idx < section_len loop
            select src into l_line
                from uw_src where idx = l_offset; 

            FOR FOO IN ( -- split the line into hex numbers
                SELECT REGEXP_SUBSTR (l_line, '[^ ]+', 1, LEVEL) TXT
                FROM DUAL
                CONNECT BY REGEXP_SUBSTR (l_line, '[^ ]+', 1, LEVEL) IS NOT NULL
                )
            LOOP
                if( substr(FOO.TXT,1,1) = ':' ) then                -- set repeater for next value
                    rpt := to_number(substr(FOO.TXT,2),'XXXXXXXX');
                else
                    for i in 1 .. rpt loop
                        insert into uw_diana values ( s, l_idx, to_number(FOO.TXT,'XXXXXXXX') );
                        l_idx := l_idx + 1;
                    end loop;
                    rpt := 1;
                end if;
            END LOOP;

            l_offset := l_offset + 1;
        end loop;
    end loop;

end if;

    select max(idx) into global_section_len
    from uw_diana where p = 1;

    if get_node(global_section_len) != 181 then
        raise_application_error(-20001,'Global node is not DS_PRAGM 0xB5.');
    end if;

    if get_node(global_section_len-1) != 23 then
        raise_application_error(-20001,'Root node D_COMP_U 0x17 is not found where expected.');
    else
        dbms_output.put('CREATE OR REPLACE ');
        recurse(global_section_len-1, -1);
        dbms_output.put_line( ';' );
    end if;

end;
