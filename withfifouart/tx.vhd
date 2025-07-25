library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Transmiter is
    generic (
        stop_bit_length : integer := 1;  -- 1=1 baud, 2=1.5 baud, 3=2 baud
        BaudRate        : integer := 115200;
        Clk_Freq        : integer := 100e6
    );
    port (
        clk      : in std_logic;
        tx       : out std_logic;
        dout  : in std_logic_vector(7 downto 0); -- data sent by rx
        rden  : out std_logic;
        valid : in std_logic;
        empty : in std_logic
    );
end Transmiter;

architecture Behavioral of Transmiter is
    type statetype is (idle, start, data, stop);
  constant bit_counting_value : integer                      := Clk_Freq/BaudRate;
    signal state              : statetype                    := idle;
    signal tempbyte           : std_logic_vector(7 downto 0) := "00000000";
    signal stopcount          : integer range 0 to Bit_counting_value         := 0; -- Extended range for different stop lengths
    signal counter            : integer range 0 to Bit_counting_value       := 0;
    signal bit_number         : integer range 0 to 7         := 0; -- Location of bit being sent
    signal notempty           : std_logic                    := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            rden <= '0';
            case state is
            
                when idle =>
                    if empty = '0' then
                        notempty <= '1';rden <= '1';
                    else
                        tx <= '1';
                    end if;
                    if notempty = '1' then 
                        rden <= '1';
                    end if;
                    if valid = '1' then
                        tempbyte <= dout; -- saves data in a temp
                        state <= start;
                    else
                        tx <= '1'; -- idle value is 1
                    end if;        
                when start =>
                        notempty <= '0';
                        rden <= '0';
                        state <= data;
                        Bit_number <= 0;
                        counter <= 0;
                        tx <= '0';
                   
                when data =>
                     if counter = bit_counting_value then
                        tx <= tempbyte(bit_number);
                        counter <= 0;
                        if bit_number = 7 then
                            state <= stop;
                        else
                            bit_number <= bit_number + 1;
                        end if;
                    else
                        counter <= counter + 1;
                    end if;
                    
                    
                when stop =>
                    if counter = bit_counting_value then
                        case stop_bit_length is
                            
                            when 3 =>
                            if counter = bit_counting_value + bit_counting_value then
                                state <= idle;
                                counter <= 0;
                            else
                                tx <= '1';
                                counter <= counter +1;
                            end if;
                            
                            when 2 =>
                            if counter = bit_counting_value/2 + bit_counting_value then
                                state <= idle;
                                counter <= 0;
                            else
                                tx <= '1';
                                counter <= counter +1;
                            end if;
                            
                            when others =>
                            if counter = bit_counting_value then
                                state <= idle;
                                counter <= 0;
                            else
                                tx <= '1';
                                counter <= counter +1;
                            end if;
                            
                        end case;
                else
                    counter <= counter + 1;
                end if;
            end case;
        end if;
    end process;
end Behavioral;
