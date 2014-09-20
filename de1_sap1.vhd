library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity de1_sap1 is
    port (
        CLOCK_50    : in std_logic;
        SW          : in std_logic_vector(9 downto 0);
        LEDR        : out std_logic_vector(9 downto 0);
        LEDG        : out std_logic_vector(7 downto 0);
        HEX0        : out std_logic_vector(0 to 6);
        HEX1        : out std_logic_vector(0 to 6);
        HEX2        : out std_logic_vector(0 to 6);
        HEX3        : out std_logic_vector(0 to 6)
    );
    
end de1_sap1;

architecture rtl of de1_sap1 is

    signal reset            : std_logic;
    signal clk_1hz          : std_logic;
    signal counter_1hz      : std_logic_vector(25 downto 0);
    signal clk_10hz         : std_logic;
    signal counter_10hz     : std_logic_vector(25 downto 0);
    signal cpu_clk          : std_logic;
    signal halt             : std_logic;
    signal p0_out           : std_logic_vector(7 downto 0);
    
    -- Converts hex nibble to 7-segment (sinthesizable).
    -- Segments ordered as "GFEDCBA"; '0' is ON, '1' is OFF
    function nibble_to_7seg(nibble : std_logic_vector(3 downto 0))
                            return std_logic_vector is
    begin
        case nibble is
        when X"0"       => return "0000001";
        when X"1"       => return "1001111";
        when X"2"       => return "0010010";
        when X"3"       => return "0000110";
        when X"4"       => return "1001100";
        when X"5"       => return "0100100";
        when X"6"       => return "0100000";
        when X"7"       => return "0001111";
        when X"8"       => return "0000000";
        when X"9"       => return "0000100";
        when X"A"       => return "0001000";
        when X"B"       => return "1100000";
        when X"C"       => return "0110001";
        when X"D"       => return "1000010";
        when X"E"       => return "0110000";
        when X"F"       => return "0111000";
        when others     => return "0111111"; -- can't happen
        end case;
    end function nibble_to_7seg;

begin

    reset <= not SW(9);
    
    LEDR(9) <= SW(9);
    LEDR(8 downto 1) <= (others => '0');
    LEDR(0) <= cpu_clk;
    
    LEDG <= p0_out;
    
    HEX0 <= nibble_to_7seg(p0_out(3 downto 0));
    HEX1 <= nibble_to_7seg(p0_out(7 downto  4));
    HEX2 <= (others => '1');
    HEX3 <= (others => '1') when halt = '0' else "1001000";
    
    cpu_clk <= clk_1hz when SW(0) = '0' else clk_10hz;

    -- Generate a 1Hz clock.
    process(CLOCK_50)
    begin
        if CLOCK_50'event and CLOCK_50 = '1' then
            if reset = '1' then
                clk_1hz <= '0';
                counter_1hz <= (others => '0');
            else
                if conv_integer(counter_1hz) = 25000000 then
                    counter_1hz <= (others => '0');
                    clk_1hz <= not clk_1hz;
                else
                    counter_1hz <= counter_1hz + 1;
                end if;
            end if;
        end if;
    end process;
    
    -- Generate a 10Hz clock.
    process(CLOCK_50)
    begin
        if CLOCK_50'event and CLOCK_50 = '1' then
            if reset = '1' then
                clk_10hz <= '0';
                counter_10hz <= (others => '0');
            else
                if conv_integer(counter_10hz) = 2500000 then
                    counter_10hz <= (others => '0');
                    clk_10hz <= not clk_10hz;
                else
                    counter_10hz <= counter_10hz + 1;
                end if;
            end if;
        end if;
    end process;

    soc: entity work.sap1_cpu
    port map (
        clock   => cpu_clk,
        reset   => reset,
        
        halt    => halt,
        p0_out  => p0_out
    );

end architecture rtl;