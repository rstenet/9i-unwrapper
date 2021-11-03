create or replace procedure uw_parse(p_name VARCHAR2) is
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

begin

    execute IMMEDIATE 'truncate table uw_src';
    execute IMMEDIATE 'truncate table uw_lex';
    execute IMMEDIATE 'truncate table uw_diana';

    select max(line) into l_number_of_lines 
    from user_source where name= p_name;

    FOR i IN 1 .. l_number_of_lines LOOP
        select text into l_sql_line 
        from user_source 
        where name= p_name 
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

    -- ignore 3 lines with 0
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

/*
create global TEMPORARY table uw_src ( idx number, src varchar2(80) );

CREATE GLOBAL TEMPORARY TABLE UW_LEX (IDX NUMBER, SRC VARCHAR2(4000 BYTE) ) ON COMMIT PRESERVE ROWS;
CREATE INDEX UW_LEX_INDEX1 ON UW_LEX (IDX ASC);

CREATE GLOBAL TEMPORARY TABLE UW_DIANA ( P NUMBER, IDX NUMBER, VAL NUMBER ) ON COMMIT PRESERVE ROWS;
CREATE INDEX UW_DIANA_INDEX1 ON UW_DIANA (P ASC, IDX ASC);
*/


end;
