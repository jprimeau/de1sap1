library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity sap1_cpu is
    port (
        clk     : in std_logic;
        reset   : in std_logic;
        
        pc_out  : out std_logic_vector(3 downto 0);
        mar_out  : out std_logic_vector(3 downto 0);
        acc_out  : out std_logic_vector(7 downto 0);
        b_out  : out std_logic_vector(7 downto 0);
        i_out  : out std_logic_vector(7 downto 0);
        o_out  : out std_logic_vector(7 downto 0);
        con_out : out std_logic_vector(11 downto 0);
        bus_out : out std_logic_vector(7 downto 0);
        op_out : out integer
    );
end entity sap1_cpu;

architecture microcoded of sap1_cpu is

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
    signal ns, ps : t_cpu_state;

    signal ACC_reg  : t_data;
    signal B_reg    : t_data;
    signal PC_reg   : t_address;
    signal MAR_reg  : t_address;
    signal I_reg    : t_data;
    signal O_reg    : t_data;
    
    signal w_bus    : t_data;
    
    signal op_code  : integer;
    
    constant iLDA   : integer := 16#0#;
    constant iADD   : integer := 16#1#;
    constant iSUB   : integer := 16#2#;
    constant iOUT   : integer := 16#E#;
    constant iHLT   : integer := 16#F#;
    
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
    constant HALT   : integer := 12;
   
    signal con       : std_logic_vector(11 downto 0) := (others => '0');

begin

    pc_out <= PC_reg;
    mar_out <= MAR_reg;
    acc_out <= ACC_reg;
    b_out <= B_reg;
    i_out <= I_reg;
    o_out <= O_reg;
    con_out <= con;
    bus_out <= w_bus;
    op_out <= op_code;

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
            w_bus(3 downto 0) <= I_reg(3 downto 0);
            op_code <= conv_integer(I_reg(7 downto 4));
        else
            w_bus <= (others => 'Z');
        end if;
    end process I_register;
    
    O_register:
    process (clk)
    begin
        if reset = '1' then
            O_reg <= (others => '1');
        elsif clk'event and clk = '0' then
            if con(Lo) = '1' then
                O_reg <= w_bus;
            end if;
        end if;
    end process O_register;
    
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