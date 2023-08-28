library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity up_counter1 is
		port	(rst, clk_fpga : in std_logic;
				random_out1,random_out2,random_out3  : out std_logic_vector(3 downto 0)
				
				);
end entity up_counter1;

architecture count of up_counter1 is



signal random_single, random_multi_1, random_multi_2 : std_logic_vector(3 downto 0);
signal s_seven1, s_seven2, s_seven3 : std_logic_vector(6 downto 0);
signal seed1,seed2, seed3 				: std_logic_vector(3 downto 0) := "1000";
signal s_clk : std_logic;

begin
	

	s_clk <= clk_fpga;
	
	process(s_clk)
	variable delay : integer range 0 to 100e6 := 0;
	variable update_count : std_logic := '0';
	variable new_bit1,new_bit2,new_bit3 : std_logic;
	variable sum,mod_sum : integer := 0;
	variable limit1 : std_logic_vector(3 downto 0) := "0101";
	
	begin
	
		if rst = '0' then 
			random_multi_2 <= (others => '0');
			random_multi_1 <= (others => '0');
			random_single <= (others => '0');
			
		elsif rising_edge(s_clk) then
			if delay >= 50e6 then
				delay := 0;
				update_count := '1';
			else
				delay := delay + 1;
				update_count := '0';
			end if;
		
		
			
		
			if update_count = '1' then
					new_bit1 := seed1(3) XOR seed1(0); -- XOR feedback
					new_bit2 := seed2(3) XOR seed2(0); -- XOR feedback
					new_bit3 := seed3(3) XOR seed3(0); -- XOR feedback
					
					
					random_single <= seed1;
					
					random_multi_1 <= seed2;
					
					seed1 <= new_bit1 & seed1(3 downto 1);
					seed2 <= new_bit2 & seed2(3 downto 1);
					
					mod_sum := to_integer(unsigned(seed3)) mod 10;
					
					if mod_sum < 5 then
						sum :=  mod_sum + to_integer(unsigned(limit1)); 
						random_multi_2 <= std_logic_vector(to_unsigned(sum,random_multi_2'length));
					else
						random_multi_2 <= std_logic_vector(to_unsigned(mod_sum,random_multi_2'length));
						
						
					end if;
						
				
					seed3 <= new_bit3 & seed3(3 downto 1);
			end if;
		end if;
	end process;
	
	
	random_out1 <= random_single;
	random_out2 <= random_multi_1;
	random_out3 <= random_multi_2;
	
	
end architecture count;



