
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--entity declaration for the enhanced reaction time game
entity Enhanced_ReactionTime_Game is
	port (clk_fpga, rst,clr  				  : in std_logic;
			SW        				      : in std_logic_vector(9 downto 0);
			LEDR 		 	    		  : out std_logic_vector(9 downto 0) := "0000000000";
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5 : out std_logic_vector(6 downto 0) := "1111111"
			);	
end entity Enhanced_ReactionTime_Game;


architecture Behaviour of Enhanced_ReactionTime_Game is
	
	--component for Hex displays
	component Display is
			port (input 	: in std_logic_vector(3 downto 0);
					segment  : out std_logic_vector(6 downto 0)
					);
	end component Display;
	
	--component for random number generator
	component up_counter1 is
		port	(rst, clk_fpga : in std_logic;
				 random_out    : out std_logic_vector(3 downto 0)
				);
	end component up_counter1;


	type fsm_states is (Easy, Medium, Hard); -- difficulty level of game 
	type game_mode  is (Single_Player,Multi_Player); -- gameplay mode
	
	
	--signals declaration
	signal mode																	  : game_mode:= Single_Player;
	signal State 	 		   							 					  : fsm_states;
	signal s_clk 	 	        						 						  : std_logic;
	signal s_count, s_count1,s_count3,s_count4,s_count5  			  : std_logic_vector(3 downto 0):="0000";
	signal s_count2 															  : std_logic_vector(3 downto 0) := "1111";
	signal segment0, segment1,segment2,segment3,segment4,segment5 : std_logic_vector(6 downto 0);
	signal random_number,random_number1,random_number2	 			  : std_logic_vector(3 downto 0);
	signal rand_test_single,rand_test_multi_1,rand_test_multi_2	  : std_logic_vector(3 downto 0);
	signal random_int ,random_int1,random_int2       	           : integer;
	signal compare_SW ,compare_SW1, compare_SW2      	           : std_logic;
	signal in_operation      							 					  : std_logic;
	signal score             							                 : std_logic_vector(6 downto 0);
	
	
begin	
	
	random_int 				<= to_integer(unsigned(random_number)) mod 10; --random integer for single player
	random_int1 			<= to_integer(unsigned(random_number1)) mod 5; --random integer for player_one in multiplayer mode
	random_int2 			<= to_integer(unsigned(random_number2)); --random integer for player_two in multiplayer mode
	score 					<= std_logic_vector(to_unsigned((to_integer(unsigned(s_count1)) * 10) + to_integer(unsigned(s_count)), score'length)); --single player score tracker
	s_clk       			<= clk_fpga;
	
	--object instantiation of display component
	disp0   : Display 				  			port map (input => s_count, segment => segment0);
	disp1   : Display 				  			port map (input => s_count1, segment => segment1);
	disp2   : Display 				  			port map (input => s_count2, segment => segment2);
	disp3   : Display 				  			port map (input => s_count3, segment => segment3);
	disp4   : Display 				  			port map (input => s_count4, segment => segment4);
	disp5   : Display 				  			port map (input => s_count5, segment => segment5);
	
	--object instantiation of counter component
	counter : work.up_counter1             port map (rst => rst, clk_fpga => clk_fpga, random_out1 => random_number,
														          random_out2=> random_number1, random_out3 => random_number2);
	
	
	process(s_clk,rst)
		variable delay        							  	      : integer range 0 to 100e6 := 0; --variable to generate a second
		variable store_number,store_number1,store_number2	: integer range 0 to 15; --variable to hold random numbers
		variable update_count 								      : integer range 0 to 10; --variable	to know game level durations
		variable start_game							            : integer; 
		variable chances 									         : integer := 0; --variable to determine available trials of a single player
		variable start_op     								      : std_logic;  --variable to ensure that game runs per second
		variable multi_player_time									: integer := 0; --variable to determine available trials for multi player
		variable game_state									      : std_logic;	--variable to toggle between game mode 
		
	begin
		if (rst='0') then
			start_game := 0;
			LEDR(9 downto 0) <= "0000000000";
			s_count  <= "0000";
			s_count1 <= "0000";
			s_count2  <= "1111";
			s_count3 <= "0000";
			s_count4  <= "0000";		

		elsif rising_edge(s_clk) then 
			if (delay >= 50e6) then
				update_count := update_count + 1;
				start_op := '1';
				delay := 0;
				
				if multi_player_time < 175 then  
					multi_player_time := multi_player_time + 1 ;
					
				end if;
				
				if start_game < 5 then --wait for 5 seconds before starting game(player must choose game mode within this time frame)
					start_game := start_game + 1;
					game_state := SW(0);
					LEDR(9 downto 0) <= "0000000000";
					
				else 
					start_game := 5;
				end if;	
				
				
			else
				delay := delay + 1;
				start_op := '0';
			end if;
			
			
			
			if (start_game = 5)  then
				if (game_state = '0') then 
					mode <= Single_Player;
				
				elsif (game_state  = '1') then
					mode <= Multi_Player;
				end if;

			
				if (start_op = '1') then
				
				--Single_Player mode activated
					if (mode = Single_Player) then
						s_count5 <= "0101";
						if(chances < 156) then
							
							chances := chances + 1;
							if (score <= "0001010") then
								if (in_operation = '0') then
									State <= Easy;
									store_number := random_int;
									LEDR(store_number) <= '1';
									compare_SW <= SW(store_number);
									update_count := 0;
									in_operation <= '1';
									
								else
									if (update_count = 4) then
										in_operation <= '0';
										LEDR(store_number) <= '0';
										update_count := 0;
										if (SW(store_number) /= compare_SW) then
											if (s_count = "1001") then
												s_count <= (others=>'0');
												s_count1 <= std_logic_vector(unsigned(s_count1) + 1);
											else
												s_count <= std_logic_vector(unsigned(s_count) + 1);
											end if;	
										else
											if (s_count > "0000") then
												s_count <= std_logic_vector(unsigned(s_count) - 1);
											elsif (s_count1 > "0000") then
												s_count <= "1001";
												s_count1 <= std_logic_vector(unsigned(s_count1) - 1);
											end if;
										end if;
									end if;
								end if;
							
							
							elsif (score > "0001010") and (score < "0101000") then
								if (in_operation = '0') then
									State <= Medium;
									store_number := random_int;
									LEDR(store_number) <= '1';
									compare_SW <= SW(store_number);
									update_count := 0;
									in_operation <= '1';
								else	
									if (update_count = 2) then
										in_operation <= '0';
										LEDR(store_number) <= '0';
										update_count := 0;
										if (SW(store_number) /= compare_SW) then
											if (s_count = "1001") then
												s_count <= (others=>'0');
												s_count1 <= std_logic_vector(unsigned(s_count1) + 1);
											else
												s_count <= std_logic_vector(unsigned(s_count) + 1);
											end if;
										else
											if (s_count > "0000") then
												s_count <= std_logic_vector(unsigned(s_count) - 1);
											elsif (s_count1 > "0000") then
												s_count <= "1001";
												s_count1 <= std_logic_vector(unsigned(s_count1) - 1);
											end if;
										end if;
									end if;
								end if;
								
								
							elsif (score >= "0101000") then
								if (in_operation = '0') then
									State <= Hard;
									store_number := random_int;
									LEDR(store_number) <= '1';
									compare_SW <= SW(store_number);
									update_count := 0;
									in_operation <= '1';
									
								else
									if (update_count = 1) then
										in_operation <= '0';
										LEDR(store_number) <= '0';
										update_count := 0;
										if (SW(store_number) /= compare_SW) then
											if (s_count = "1001") then
									
												if (s_count1 /= "1001") then
													s_count <= (others=>'0');
													s_count1 <= std_logic_vector(unsigned(s_count1) + 1);	
												end if;
											else
												s_count <= std_logic_vector(unsigned(s_count) + 1);
											end if;
										else
											if (s_count > "0000") then
												s_count <= std_logic_vector(unsigned(s_count) - 1);
											elsif (s_count1 > "0000") then
												s_count <= "1001";
												s_count1 <= std_logic_vector(unsigned(s_count1) - 1);
											end if;
										end if;
									end if;		
								end if;
							end if;
						
						else 
							
							start_game := 0;
							chances := 0;
						end if;
					
					elsif (mode = Multi_Player) then	
					
					--multi_player mode activated
						s_count5 <= "1110";
						chances := chances + 1;
						if (multi_player_time <= 60) then
							if (in_operation = '0') then
								State <= Easy;
								store_number1 := random_int1;
								store_number2 := random_int2;
								
								if (store_number1 = 5 ) then 
									LEDR(0) <= '1';
								else	
									LEDR(store_number1) <= '1';
									LEDR(store_number2) <= '1';
								end if;
									
								compare_SW1 <= SW(store_number1);
								compare_SW2 <= SW(store_number2);
								update_count := 0;
								in_operation <= '1';
								
							else
								if (update_count = 4) then
									in_operation <= '0';
									LEDR(store_number1) <= '0';
									LEDR(store_number2) <= '0';
									update_count := 0;

									if (SW(store_number1) /= compare_SW1) then
										if (s_count = "1001") then
											if (s_count1 /= "1001") then
												s_count <= (others=>'0');
												s_count1 <= std_logic_vector(unsigned(s_count1) + 1);
											end if;
										else
											s_count <= std_logic_vector(unsigned(s_count) + 1);
										end if;	
									else
										if (s_count > "0000") then
											s_count <= std_logic_vector(unsigned(s_count) - 1);
										elsif (s_count1 > "0000") then
											s_count <= "1001";
											s_count1 <= std_logic_vector(unsigned(s_count1) - 1);
										end if;
									end if;



									if (SW(store_number2) /= compare_SW2) then
										if (s_count3 = "1001") then
											if s_count4 /= "1001" then
												s_count3 <= (others=>'0');
												s_count4 <= std_logic_vector(unsigned(s_count4) + 1);
											end if;
										else
											s_count3 <= std_logic_vector(unsigned(s_count3) + 1);
										end if;	
									else
										if (s_count3 > "0000") then
											s_count3 <= std_logic_vector(unsigned(s_count3) - 1);
										elsif (s_count4 > "0000") then
											s_count3 <= "1001";
											s_count4 <= std_logic_vector(unsigned(s_count4) - 1);
										end if;
									end if;
								end if;
							end if;
						
						
						elsif (multi_player_time > 60) and (multi_player_time <= 120) then
							if (in_operation = '0') then
								State <= Medium;
								store_number1 := random_int1;
								store_number2 := random_int2;
								LEDR(store_number1) <= '1';
								LEDR(store_number2) <= '1';
								compare_SW1 <= SW(store_number1);
								compare_SW2 <= SW(store_number2);
								update_count := 0;
								in_operation <= '1';
							else	
								if (update_count = 2) then
									in_operation <= '0';
									LEDR(store_number1) <= '0';
									LEDR(store_number2) <= '0';
									update_count := 0;

									if (SW(store_number1) /= compare_SW1) then
										if (s_count = "1001") then
											if (s_count1 /= "1001") then
												s_count <= (others=>'0');
												s_count1 <= std_logic_vector(unsigned(s_count1) + 1);
											end if;
										else
											s_count <= std_logic_vector(unsigned(s_count) + 1);
										end if;	
									else
										if (s_count > "0000") then
											s_count <= std_logic_vector(unsigned(s_count) - 1);
										elsif (s_count1 > "0000") then
											s_count <= "1001";
											s_count1 <= std_logic_vector(unsigned(s_count1) - 1);
										end if;
									end if;



									if (SW(store_number2) /= compare_SW2) then
										if (s_count3 = "1001") then
											if s_count4 /= "1001" then
												s_count3 <= (others=>'0');
												s_count4 <= std_logic_vector(unsigned(s_count4) + 1);
											end if;
										else
											s_count3 <= std_logic_vector(unsigned(s_count3) + 1);
										end if;	
									else
										if (s_count3 > "0000") then
											s_count3 <= std_logic_vector(unsigned(s_count3) - 1);
										elsif (s_count4 > "0000") then
											s_count3 <= "1001";
											s_count4 <= std_logic_vector(unsigned(s_count4) - 1);
										end if;
									end if;
								end if;
							end if;
							
							
						elsif (multi_player_time > 120) and (multi_player_time <= 175) then
							if (in_operation = '0') then
								State <= Hard;
								store_number1 := random_int1;
								store_number2 := random_int2;
								LEDR(store_number1) <= '1';
								LEDR(store_number2) <= '1';
								compare_SW1 <= SW(store_number1);
								compare_SW2 <= SW(store_number2);
								update_count := 0;
								in_operation <= '1';
								
							else
								if (update_count = 1) then
									in_operation <= '0';
									LEDR(store_number1) <= '0';
									LEDR(store_number2) <= '0';
									update_count := 0;

									if (SW(store_number1) /= compare_SW1) then
										if (s_count = "1001") then
											if(s_count1 /= "1001") then  
												s_count <= (others=>'0');
												s_count1 <= std_logic_vector(unsigned(s_count1) + 1);
											end if;
										else
											s_count <= std_logic_vector(unsigned(s_count) + 1);
										end if;	
									else
										if (s_count > "0000") then
											s_count <= std_logic_vector(unsigned(s_count) - 1);
										elsif (s_count1 > "0000") then
											s_count <= "1001";
											s_count1 <= std_logic_vector(unsigned(s_count1) - 1);
										end if;
									end if;



									if (SW(store_number2) /= compare_SW2) then
										if (s_count3 = "1001") then
											if(s_count4 /= "1001") then  
												s_count3 <= (others=>'0');
												s_count4 <= std_logic_vector(unsigned(s_count4) + 1);
											end if;
										else
											s_count3 <= std_logic_vector(unsigned(s_count3) + 1);
										end if;	
									else
										if (s_count3 > "0000") then
											s_count3 <= std_logic_vector(unsigned(s_count3) - 1);
										elsif (s_count4 > "0000") then
											s_count3 <= "1001";
											
											s_count4 <= std_logic_vector(unsigned(s_count4) - 1);
										end if;
									end if;	
								end if;
							end if;
						else 
							start_game := 0;
							multi_player_time := 0;
						end if;
					end if;
				end if;
			end if;	
		end if;
	end process;
		
--assignment of hex for displays
HEX0 <= segment0;
HEX1 <= segment1;
HEX2 <= segment2;
HEX3 <= segment3;
HEX4 <= segment4;
HEX5 <= segment5;
end architecture Behaviour;




--Segment Displays

library ieee;
use ieee.std_logic_1164.all;

entity Display is
	port (input 	: in std_logic_vector(3 downto 0);
			segment  : out std_logic_vector(6 downto 0)
		  );
end entity Display;


architecture display_behaviour of Display is
begin
	WITH input SELECT
	segment <= "1000000" when "0000", --0
				  "1111001" when "0001", --1
				  "0100100" when "0010", --2
				  "0110000" when "0011", --3
				  "0011001" when "0100", --4
				  "0010010" when "0101", --5
				  "0000010" when "0110", --6
				  "0111000" when "0111", --7
				  "0000000" when "1000", --8
				  "0011000" when "1001", --9
				  "0111111" when "1111" , --dash
				  "0100001" when "1110" , --d
				  "1111111" when OTHERS; --invalid input
end architecture display_behaviour;










































































































































































































































































































































































































































































































