library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity sap1_cpu is
    port (
        clk     : in std_logic;
        reset   : in std_logic;
        
        p0_out  : out std_logic_vector(7 downto 0)
    );
end entity sap1_cpu;

architecture microcoded of sap1_cpu is

    type t_ram is array (0 to 15) of std_logic_vector(7 downto 0);
    
    type t_cpu_state is (S1, S2, S3, S4, S5, S6, SX);
    signal ns, ps : t_cpu_state;

    signal ACC_reg  : std_logic_vector(7 downto 0);
    signal B_reg    : std_logic_vector(7 downto 0);
    signal PC_reg   : std_logic_vector(3 downto 0);
    signal MAR_reg  : std_logic_vector(3 downto 0);
    signal I_reg    : std_logic_vector(7 downto 0);
    signal O_reg    : std_logic_vector(7 downto 0);
    
    signal w_bus    : std_logic_vector(7 downto 0);
    
    signal increment_pc
    signal enable_pc
    signal load_mar
    signal enable_mem
    signal load_o  :
    signal load_b
    signal load_i
    signal enable_i
    signal load_a
    signal enable_a
    signal enable_alu
    signal 

begin

    p0_out <= PC_reg;

    program_counter:
    process (clk)
    begin
        if reset = '1' then
            PC_reg <= (others => '0');
        elsif clk'event and clk = '0' then
            if increment_pc = '1' then
                PC_reg <= PC_reg + 1;
            end if;
        end if;
        if enable_pc = '1' then
            w_bus <= PC_reg;
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
            if load_mar = '1' then
                MAR_reg <= w_bus;
            end if;
        end if;
    end process program_counter;
    
    ACC_register:
    process (clk)
    begin
        if reset = '1' then
            A_reg <= (others => '0');
        elsif clk'event and clk = '0' then
            if load_a = '1' then
                A_reg <= w_bus;
            end if;
        end if;
        if enable_a = '1' then
            w_bus <= A_reg;
        else
            w_bus <= (others => 'Z');
        end if;
    end process program_counter;
    
    B_register:
    process (clk)
    begin
        if reset = '1' then
            B_reg <= (others => '0');
        elsif clk'event and clk = '0' then
            if load_b = '1' then
                B_reg <= w_bus;
            end if;
        end if;
        if enable_b = '1' then
            w_bus <= B_reg;
        else
            w_bus <= (others => 'Z');
        end if;
    end process program_counter;
    
    O_register:
    process (clk)
    begin
        if reset = '1' then
            O_reg <= (others => '0');
        elsif clk'event and clk = '0' then
            if load_o = '1' then
                O_reg <= w_bus;
            end if;
        end if;
    end process program_counter;
    
    
    cpu_state_machine_reg:
    process (clk)
    begin
        if reset = '1' then
            ps <= S0;
        elsif clk'event and clk='1' then
            ps <= ns;
        end if;
    end process cpu_state_machine_reg;


end architecture microcoded;