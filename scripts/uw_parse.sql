create or replace procedure uw_poc is

    cr varchar(2) := chr(10);
    global_section_len number;
    
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

    procedure get_len (p_idx number, list_length in out number, list_offset in out number)
    is
        l_len number;
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

    function get_param (p_offset number, seq number) return number
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
    end get_param;

    procedure recurse (p_idx number) is --we pass the idx not the node
        len integer;
        n number;
        list_length number;
        list_offset number;
    begin
    
        if p_idx = 0 then
            return;
        end if;
    
        n := get_node(p_idx);

        if( n = diana.d_comp_u) then --top of DIANA
            recurse( subnode(p_idx,1) ); --0 is D_CONTEX / 1 is D_S_BODY

        elsif ( n = diana.d_s_body) then
            recurse( subnode(p_idx,0) );       -- 0 A_D_     
            recurse( subnode(p_idx,1) );       -- 1 A_HEADER 
            recurse( subnode(p_idx,2) );       -- 2 A_BLOCK_
            dbms_output.put('END');

        elsif( n = diana.d_block) then
            dbms_output.put_line('IS ');
            -- local variables
            recurse( subnode(p_idx,0) );   -- DS_ITEM
            dbms_output.put_line('BEGIN');
            recurse( subnode(p_idx,1) );   -- DS_BODY
            recurse( subnode(p_idx,2) );   -- DS_ALTER

        elsif( n = diana.di_proc) then
            dbms_output.put_line('PROCEDURE ' || get_lex(p_idx) );

        elsif( n = diana.di_funct) then
            dbms_output.put_line('FUNCTION ' || get_lex(p_idx) );

        elsif( n = diana.DS_PARAM) then -- 180
            get_len(p_idx, list_length, list_offset); -- list_... are IN OUT

        -- parameter definition
        elsif( n = diana.d_in) then           --declare IN param
            recurse( subnode(p_idx,0) );
            recurse( subnode(p_idx,1) );
            --default value
            if ( get_len2(p_idx,2) != 0 ) then
                dbms_output.put( ' := ' );
                recurse( subnode(p_idx,2) ); 
            end if;

        elsif( n = diana.di_in) then           --parameter name
          --dbms_output.put( diana.l_symrep(n) || '  '); 
          dbms_output.put( ' ' || get_lex(p_idx) || '  ');

        elsif( n = diana.ds_id ) then
            get_len(p_idx, list_length, list_offset);
            for i in 1..list_length loop
                recurse( get_param(LIST_OFFSET,i) ); 
            end loop;

        elsif( n = diana.DI_U_NAM) then        --print from lex
          dbms_output.put( get_lex(p_idx));

        -- PROCEDUTE
        elsif( n = diana.d_p_) then
            recurse( subnode(p_idx,0) );

        -- FUNCTION
        elsif( n = diana.d_f_) then -- declare function params
            get_len( subnode(p_idx,0), list_length, list_offset );
            if LIST_LENGTH > 0 then
                dbms_output.put_line('(  ');
                for i in 1..LIST_LENGTH loop
                    if (i>1) then 
                        dbms_output.put_line(',');
                    end if;
                    recurse( get_param(LIST_OFFSET,i) );
                end loop;
                dbms_output.put_line( cr || ') ' );
            end if;
            dbms_output.put(' RETURN ');
            recurse( subnode(p_idx,1) );
            dbms_output.put_line('');

        elsif( n = diana.ds_stm ) then
            get_len( p_idx, list_length, list_offset );
            for i in 1..list_length loop
                recurse( get_param(LIST_OFFSET,i) ); 
            end loop;

        elsif( n = diana.ds_item) then   -- 177
            get_len( p_idx, list_length, list_offset );
            for i in 1..list_length loop
                recurse( get_param(LIST_OFFSET,i) );
                dbms_output.put_line(';');
            end loop;

        -- private variable definition
        elsif( n = diana.d_var) then
            recurse( subnode(p_idx,0) );
            recurse( subnode(p_idx,1) );
            if ( get_len2(p_idx,2) != 0 ) then
                dbms_output.put( ' := ' );
                recurse( subnode(p_idx,2) );
            end if;

        elsif( n = diana.D_TYPE  ) then             --declare TYPE
            recurse( subnode(p_idx,0) );
            recurse( subnode(p_idx,1) );
            recurse( subnode(p_idx,2) );

        elsif( n = diana.D_ARRAY) then           --declare VARRAY or TABLE OF
            if  subnode(p_idx,4) = 2 then --  VARRAY 
                dbms_output.put('VARRAY(' );
                get_len( subnode(p_idx,0), list_length, list_offset );
                recurse( subnode(get_param(LIST_OFFSET,1) ,1) );
                dbms_output.put( ') OF ' );
                recurse( subnode(p_idx,1) ); 
            elsif subnode(p_idx,4) = 0 then    -- TABLE OF
                dbms_output.put('TABLE OF ');
                recurse( subnode(p_idx,1) ); -- D_CONSTR
                recurse( subnode(p_idx,0) ); -- D_INDEX
            else -- No Idea what subnode(p_idx,4) = 1 is or 3 (if exists)
                dbms_output.put_line('  -- ARRAY not implemented Node:' || n || ' Name:' || pidl.ptattnnm(n) || ' idx:' || p_idx) ;
            end if;

        elsif( n = diana.D_INDEX) then
            dbms_output.put( ' INDEX BY ' );
            recurse( subnode(p_idx,0) );  -- go to D_CONSTR

        -- private CONSTANT definition
        elsif( n = diana.D_CONSTA) then           --declare CONSTANT
            recurse( subnode(p_idx,0) );
            dbms_output.put( ' ' );
            recurse( subnode(p_idx,1) );
            if ( get_len2(p_idx,2) != 0 ) then
                dbms_output.put( ' := ' );
                recurse( subnode(p_idx,2) ); 
            end if;

        elsif( n = diana.di_var) then
          dbms_output.put( '  ' || get_lex(p_idx) || ' ');

        elsif( n = diana.DI_TYPE) then           --declare TAPE NAME
          dbms_output.put( '  TYPE ' || get_lex(p_idx) || ' IS ');


        elsif( n = diana.DS_D_RAN) then           --RANGE / INTERVAL
            get_len( p_idx, list_length, list_offset );
            for i in 1..list_length loop
                recurse( get_param(LIST_OFFSET,i) );
                if i < list_length then  dbms_output.put_line(','); end if;
            end loop;

        elsif( n = diana.DI_CONST) then
          dbms_output.put( '  ' || get_lex(p_idx) || ' CONSTANT');

        elsif( n = diana.D_R_) then
            dbms_output.put_line( ' RECOERD (' );
            get_len( p_idx, list_length, list_offset );
            for i in 1..list_length loop
                dbms_output.put('  ');
                recurse( get_param(LIST_OFFSET,i) );
                if i < list_length then  dbms_output.put_line(','); end if;
            end loop;
            dbms_output.put( '  )' );

        elsif( n = diana.D_CONSTR ) then
            recurse( subnode(p_idx,0) ); -- data type
            if ( get_len2( subnode(p_idx,1),0 ) != 0 ) then
                dbms_output.put( '(' );
                recurse( subnode(p_idx,1) );
                dbms_output.put( ')'  );
            end if;

        elsif( n = diana.D_ATTRIB  ) then
            recurse( subnode(p_idx,0) );
            dbms_output.put( '%' );
            recurse( subnode(p_idx,1) );

        elsif( n = diana.D_S_ED  ) then
            recurse( subnode(p_idx,0) );
            dbms_output.put( '.' );
            recurse( subnode(p_idx,1) );

        elsif( n = diana.DS_APPLY  ) then
            get_len( p_idx, list_length, list_offset );
            for i in 1..list_length loop
                if i > 1 then dbms_output.put( ',' ); end if;
                recurse( get_param(LIST_OFFSET,i) ); 
            end loop;

        elsif( n = diana.D_APPLY  ) then
            recurse( subnode(p_idx,0) );
            dbms_output.put( '(' );
            recurse( subnode(p_idx,1) );
            dbms_output.put( ')' );

        elsif( n = diana.D_ASSIGN  ) then
            dbms_output.put( ' ' );
            recurse( subnode(p_idx,0) ); -- left side
            dbms_output.put( ' := ' );
            recurse( subnode(p_idx,1) ); -- rigth side
            dbms_output.put_line( ';' );

        -- needs more work
        -- see diutil body line 425
        elsif( n = diana.D_F_CALL  ) then 
            get_len( subnode(p_idx,1), list_length, list_offset );
            if list_length = 1 then --unary
                recurse( get_param(LIST_OFFSET,1) );
                recurse( subnode(p_idx,0) );
            else
                for i in 1..list_length loop
                    recurse( get_param(LIST_OFFSET,i) );
                    if i < list_length then
                        dbms_output.put( ' ' );
                        recurse( subnode(p_idx,0) );
                        dbms_output.put( ' ' );
                    end if;
                end loop;
            end if;

        elsif( n = diana.D_USED_O  ) then
            dbms_output.put( get_lex(p_idx) );

        elsif( n = diana.D_PARENT  ) then
            dbms_output.put( '(' );
            recurse( subnode(p_idx,0) );
            dbms_output.put( ')' );

        elsif( n = diana.D_NUMERI  ) then
            dbms_output.put( get_lex(p_idx) );

        elsif( n = diana.D_STRING  ) then
            dbms_output.put( ''''||get_lex(p_idx)||'''');

        elsif( n = diana.D_RETURN  ) then
            dbms_output.put( ' RETURN ');
            recurse( subnode(p_idx,0) );
            dbms_output.put_line( ';');

        elsif( n = diana.d_null_a) then
            dbms_output.put('0');
        elsif( n = diana.d_null_c) then
            null;
        elsif( n = diana.d_null_s) then
            dbms_output.put('NULL;');
            
--        elsif( n = diana.ds_alter) then
            

        else
            dbms_output.put_line('  -- NOT IMPLEMENTED  Node nr:' || n || ' Name:' || pidl.ptattnnm(n) || ' idx:' || p_idx) ;
        end if;
        --
    end recurse;

begin

    select max(idx) into global_section_len
    from uw_diana where p = 1;

    -- ANALYZE... 
    
    if get_node(global_section_len) != 181 then
        raise_application_error(-20001,'Global node is not DS_PRAGM 0xB5.');
    else
        --dbms_output.put_line( 'Global node is DS_PRAGM (B5) - OK ' );
        null;
    end if;
    
    if get_node(global_section_len-1) != 23 then
        raise_application_error(-20001,'Root node D_COMP_U 0x17 is not found where expected.');
    else
        --dbms_output.put_line( 'Root is D_COMP_U (17) - OK' );
        dbms_output.put('CREATE OR REPLACE ');
        recurse(global_section_len-1);
        dbms_output.put_line(';' || cr || '/');
    end if;


end;