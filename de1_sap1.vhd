library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity de1_sap1 is
    port (
        CLOCK_50    : in std_logic;
        SW          : in std_logic_vector(9 downto 0);
        LEDG        : out std_logic_vector(7 downto 0)
    );
    
end de1_sap1;

architecture rtl of de1_sap1 is

signal clk_1hz          : std_logic;
signal reset            : std_logic;
signal clk              : std_logic;
signal counter_1hz      : std_logic_vector(25 downto 0);
signal p0_out           : std_logic_vector(7 downto 0);

begin

    reset <= not SW(9);

    -- Generate a 1Hz clock.
    process(CLOCK_50)
    begin
        if CLOCK_50'event and CLOCK_50 = '1' then
            if reset = '1' then
                clk_1hz <= '0';
                counter_1hz <= (others => '0');
            else
                if conv_integer(counter_1hz) = 50000000 then
                    counter_1hz <= (others => '0');
                    clk_1hz <= not clk_1hz;
                else
                    counter_1hz <= counter_1hz + 1;
                end if;
            end if;
        end if;
    end process;

    soc: entity work.sap1_cpu
    port map (
        clk     => clk_1hz,
        reset   => reset,
        
        p0_out  => p0_out
    );
    
    LEDG <= p0_out;

end architecture rtl;