library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity sap1_cpu is
    port (
        clock   : in std_logic;
        reset   : in std_logic;

        p0_out  : out std_logic_vector(7 downto 0)
    );
end entity sap1_cpu;

architecture microcoded of sap1_cpu is

    signal clk  : std_logic;

    subtype t_address is std_logic_vector(3 downto 0);
    subtype t_data is std_logic_vector(7 downto 0);
    type t_ram is array (0 to 15) of t_data;
    
    signal ram : t_ram := (
         0 => x"09",    -- LDA 9h
         1 => x"EF",    -- OUT
         2 => x"1A",    -- ADD Ah
         3 => x"EF",    -- OUT
         4 => x"1B",    -- ADD Bh
         5 => x"2C",    -- SUB Ch
         6 => x"EF",    -- OUT
         7 => x"FF",    -- HLT Result: 0Bh
         8 => x"FF",
         9 => x"05",    -- 05h
         10=> x"07",    -- 07h
         11=> x"03",    -- 03h
         12=> x"04",    -- 04h
         13=> x"FF",
         14=> x"FF",
         15=> x"FF" );
    
    type t_cpu_state is (S1, S2, S3, S4, S5, S6, SX);
    signal ns, ps   : t_cpu_state;

    signal ACC_reg  : t_data;
    signal B_reg    : t_data;
    signal PC_reg   : t_address;
    signal MAR_reg  : t_address;
    signal I_reg    : t_data;
    signal O_reg    : t_data;
    
    signal w_bus    : t_data;
    
    subtype t_opcode is std_logic_vector(3 downto 0);
    signal op_code  : t_opcode;
    
    constant iLDA   : t_opcode := x"0";
    constant iADD   : t_opcode := x"1";
    constant iSUB   : t_opcode := x"2";
    constant iOUT   : t_opcode := x"E";
    constant iHLT   : t_opcode := x"F";
    
    constant Cp     : integer := 00;
    constant Ep     : integer := 01;
    constant Lm     : integer := 02;
    constant Em     : integer := 03;
    constant Li     : integer := 04;
    constant Ei     : integer := 05;
    constant La     : integer := 06;
    constant Ea     : integer := 07;
    constant Eu     : integer := 08;
    constant Su     : integer := 09;
    constant Lb     : integer := 10;
    constant Lo     : integer := 11;
    constant HLT    : integer := 12;
   
    signal con      : std_logic_vector(12 downto 0) := (others => '0');
    
    procedure full_adder(
        a        : in std_logic_vector(7 downto 0);
        b        : in std_logic_vector(7 downto 0);
        cin      : in std_logic;
        q        : out std_logic_vector(7 downto 0);
        cout     : out std_logic
    ) is
        variable c1, c2, c3, c4, c5, c6, c7 : std_logic;
    begin
        c1 := (a(0) and b(0)) or (a(0) and cin) or (b(0) and cin);
        c2 := (a(1) and b(1)) or (a(1) and c1) or (b(1) and c1);
        c3 := (a(2) and b(2)) or (a(2) and c2) or (b(2) and c2);
        c4 := (a(3) and b(3)) or (a(3) and c3) or (b(3) and c3);
        c5 := (a(4) and b(4)) or (a(4) and c4) or (b(4) and c4);
        c6 := (a(5) and b(5)) or (a(5) and c5) or (b(5) and c5);
        c7 := (a(6) and b(6)) or (a(6) and c6) or (b(6) and c6);
        cout := (a(7) and b(7)) or (a(7) and c7) or (b(7) and c7);
        q(0) := a(0) xor b(0) xor cin;
        q(1) := a(1) xor b(1) xor c1;
        q(2) := a(2) xor b(2) xor c2;
        q(3) := a(3) xor b(3) xor c3;
        q(4) := a(4) xor b(4) xor c4;
        q(5) := a(5) xor b(5) xor c5;
        q(6) := a(6) xor b(6) xor c6;
        q(7) := a(7) xor b(7) xor c7;
    end full_adder;

begin

    p0_out <= O_reg;
    
    run:
    process (clock)
    begin
        if reset = '1' then
            clk <= '0';
        else
            if con(HLT) = '1' then
                clk <= '0';
            else
                clk <= clock;
            end if;
        end if;
    end process run;

    program_counter:
    process (clk)
    begin
        if reset = '1' then
            PC_reg <= (others => '0');
        elsif clk'event and clk = '0' then
            if con(Cp) = '1' then
                PC_reg <= PC_reg + 1;
            end if;
        end if;
        if con(Ep) = '1' then
            w_bus(3 downto 0) <= PC_reg;
        else
            w_bus <= (others => 'Z');
        end if;
    end process program_counter;
    
    MAR_register:
    process (clk)
    begin
        if reset = '1' then
            MAR_reg <= (others => '0');
        elsif clk'event and clk = '0' then
            if con(Lm) = '1' then
                MAR_reg <= w_bus(3 downto 0);
            end if;
        end if;
    end process MAR_register;
    
    memory:
    process (clk)
    begin
        if con(Em) = '1' then
            w_bus <= ram(conv_integer(MAR_reg));
        else
            w_bus <= (others => 'Z');
        end if;
    end process memory;
    
    ACC_register:
    process (clk)
    begin
        if reset = '1' then
            ACC_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(La) = '1' then
                ACC_reg <= w_bus;
            end if;
        end if;
        if con(Ea) = '1' then
            w_bus <= ACC_reg;
        else
            w_bus <= (others => 'Z');
        end if;
    end process ACC_register;
    
    B_register:
    process (clk)
    begin
        if reset = '1' then
            B_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Lb) = '1' then
                B_reg <= w_bus;
            end if;
        end if;
    end process B_register;
    
    I_register:
    process (clk)
    begin
        if reset = '1' then
            I_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if con(Li) = '1' then
                I_reg <= w_bus;
            end if;
        end if;
        if con(Ei) = '1' then
            w_bus <= I_reg;
        else
            w_bus <= (others => 'Z');
        end if;
    end process I_register;
    
    op_code <= I_reg(7 downto 4);

    O_register:
    process (clk)
    begin
        if reset = '1' then
            O_reg <= (others => '0');
        elsif clk'event and clk = '0' then
            if con(Lo) = '1' then
                O_reg <= w_bus;
            end if;
        end if;
    end process O_register;

    arithmetic_logic_unit:
    process (clk)
        variable a, b, q : std_logic_vector(7 downto 0);
        variable cin, cout : std_logic;
    begin
        if con(Eu) = '1' then
            if con(Su) = '0' then
                cin := '0';
                a := ACC_reg;
                b := B_reg;
                full_adder(a, b, cin, q, cout);
            else
                cin := '1';
                a := ACC_reg;
                b := not B_reg;
                full_adder(a, b, cin, q, cout);
            end if;
            w_bus <= q;
        else
            w_bus <= (others => 'Z');
        end if;
   end process arithmetic_logic_unit;
    
    cpu_state_machine_reg:
    process (clk)
    begin
        if reset = '1' then
            ps <= S1;
        elsif clk'event and clk='1' then
            ps <= ns;
        end if;
    end process cpu_state_machine_reg;
    
    cpu_state_machine_transitions:
    process (ps)
    begin
        con <= (others => '0');
        case ps is
		when S1 => -- Fetch address
            con(Ep) <= '1';
            con(Lm) <= '1';
			ns <= S2;
		when S2 => -- Increment program counter
            con(Cp) <= '1';
			ns <= S3;
		when S3 => -- Load instruction
            con(Em) <= '1';
            con(Li) <= '1';
			ns <= S4;
		when S4 =>
            ns <= S1;
			if op_code = iLDA or op_code = iADD or op_code = iSUB then
                con(Ei) <= '1';
                con(Lm) <= '1';
                ns <= S5;
			elsif op_code = iOUT then
                con(Ea) <= '1';
                con(Lo) <= '1';
			elsif op_code = iHLT then
                con(HLT) <= '1';
			end if;
		when S5 =>
            ns <= S1;
			if op_code = iLDA then
                con(Em) <= '1';
                con(La) <= '1';
			elsif op_code = iADD or op_code = iSUB then
                con(Em) <= '1';
                con(Lb) <= '1';
                ns <= S6;
			end if;
		when S6 =>
            ns <= S1;
			if op_code = iADD or op_code = iSUB then
                con(Eu) <= '1';
                con(La) <= '1';
				if op_code = iSUB then
					con(Su) <= '1';
				end if;
			end if;
		when others =>
			con <= (others=>'0');
			ns <= S1;
		end case;
    end process cpu_state_machine_transitions;

end architecture microcoded;