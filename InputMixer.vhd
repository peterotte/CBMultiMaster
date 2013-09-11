----------------------------------------------------------------------------------
-- Peter-Bernd Otte 
-- Create Date:    07:54:35 11/28/2012 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity InputMixer is
    Port ( Module1IN : in  STD_LOGIC_VECTOR (31 downto 0);
           Module2IN : in  STD_LOGIC_VECTOR (31 downto 0);
           Module3IN : in  STD_LOGIC_VECTOR (31 downto 0);
           Module4IN : in  STD_LOGIC_VECTOR (31 downto 0);
           Module5IN : in  STD_LOGIC_VECTOR (31 downto 0);
           Module6IN : in  STD_LOGIC_VECTOR (19 downto 0);
           CompleteHitPatternRegisterOut : out  STD_LOGIC_VECTOR (179 downto 0));
end InputMixer;

architecture Behavioral of InputMixer is
	type TCBBunches is array (90 downto 1) of std_logic_vector(1 downto 0);
	signal CBBunches : TCBBunches;
begin
	--Module 1
	CBBunches(13) <= Module1IN(1+2*0 downto 2*0);
	CBBunches(14) <= Module1IN(1+2*1 downto 2*1);
	CBBunches(21) <= Module1IN(1+2*2 downto 2*2);
	CBBunches(22) <= Module1IN(1+2*3 downto 2*3);
	CBBunches(31) <= Module1IN(1+2*4 downto 2*4);
	CBBunches(32) <= Module1IN(1+2*5 downto 2*5);
	CBBunches(3)  <= Module1IN(1+2*6 downto 2*6);
	CBBunches(4)  <= Module1IN(1+2*7 downto 2*7);
	CBBunches(39) <= Module1IN(1+2*8 downto 2*8);
	CBBunches(40) <= Module1IN(1+2*9 downto 2*9);
	CBBunches(7)  <= Module1IN(1+2*10 downto 2*10);
	CBBunches(8)  <= Module1IN(1+2*11 downto 2*11);
	CBBunches(25) <= Module1IN(1+2*12 downto 2*12);
	CBBunches(26) <= Module1IN(1+2*13 downto 2*13);
	CBBunches(19) <= Module1IN(1+2*14 downto 2*14);
	CBBunches(20) <= Module1IN(1+2*15 downto 2*15);

	--Module 2
	CBBunches(1)  <= Module2IN(1+2*0 downto 2*0);
	CBBunches(2)  <= Module2IN(1+2*1 downto 2*1);
	CBBunches(85) <= Module2IN(1+2*2 downto 2*2);
	CBBunches(86) <= Module2IN(1+2*3 downto 2*3);
	CBBunches(37) <= Module2IN(1+2*4 downto 2*4);
	CBBunches(38) <= Module2IN(1+2*5 downto 2*5);
	CBBunches(79) <= Module2IN(1+2*6 downto 2*6);
	CBBunches(80) <= Module2IN(1+2*7 downto 2*7);
	CBBunches(73) <= Module2IN(1+2*8 downto 2*8);
	CBBunches(74) <= Module2IN(1+2*9 downto 2*9);
	CBBunches(55) <= Module2IN(1+2*10 downto 2*10);
	CBBunches(56) <= Module2IN(1+2*11 downto 2*11);
	CBBunches(61) <= Module2IN(1+2*12 downto 2*12);
	CBBunches(62) <= Module2IN(1+2*13 downto 2*13);
	CBBunches(43) <= Module2IN(1+2*14 downto 2*14);
	CBBunches(44) <= Module2IN(1+2*15 downto 2*15);

	--Module 3
	CBBunches(49) <= Module3IN(1+2*0 downto 2*0);
	CBBunches(50) <= Module3IN(1+2*1 downto 2*1);
	CBBunches(57) <= Module3IN(1+2*2 downto 2*2);
	CBBunches(58) <= Module3IN(1+2*3 downto 2*3);
	CBBunches(67) <= Module3IN(1+2*4 downto 2*4);
	CBBunches(68) <= Module3IN(1+2*5 downto 2*5);
	CBBunches(75) <= Module3IN(1+2*6 downto 2*6);
	CBBunches(76) <= Module3IN(1+2*7 downto 2*7);
	CBBunches(81) <= Module3IN(1+2*8 downto 2*8);
	CBBunches(82) <= Module3IN(1+2*9 downto 2*9);
	CBBunches(63) <= Module3IN(1+2*10 downto 2*10);
	CBBunches(64) <= Module3IN(1+2*11 downto 2*11);
	CBBunches(69) <= Module3IN(1+2*12 downto 2*12);
	CBBunches(70) <= Module3IN(1+2*13 downto 2*13);
	CBBunches(59) <= Module3IN(1+2*14 downto 2*14);
	CBBunches(60) <= Module3IN(1+2*15 downto 2*15);

	--Module 4
	CBBunches(77) <= Module4IN(1+2*0 downto 2*0);
	CBBunches(78) <= Module4IN(1+2*1 downto 2*1);
	CBBunches(51) <= Module4IN(1+2*2 downto 2*2);
	CBBunches(52) <= Module4IN(1+2*3 downto 2*3);
	CBBunches(65) <= Module4IN(1+2*4 downto 2*4);
	CBBunches(66) <= Module4IN(1+2*5 downto 2*5);
	CBBunches(87) <= Module4IN(1+2*6 downto 2*6);
	CBBunches(88) <= Module4IN(1+2*7 downto 2*7);
	CBBunches(83) <= Module4IN(1+2*8 downto 2*8);
	CBBunches(84) <= Module4IN(1+2*9 downto 2*9);
	CBBunches(71) <= Module4IN(1+2*10 downto 2*10);
	CBBunches(72) <= Module4IN(1+2*11 downto 2*11);
	CBBunches(89) <= Module4IN(1+2*12 downto 2*12);
	CBBunches(90) <= Module4IN(1+2*13 downto 2*13);
	CBBunches(53) <= Module4IN(1+2*14 downto 2*14);
	CBBunches(54) <= Module4IN(1+2*15 downto 2*15);

	--Module 5
	CBBunches(9)  <= Module5IN(1+2*0 downto 2*0);
	CBBunches(10) <= Module5IN(1+2*1 downto 2*1);
	CBBunches(15) <= Module5IN(1+2*2 downto 2*2);
	CBBunches(16) <= Module5IN(1+2*3 downto 2*3);
	CBBunches(23) <= Module5IN(1+2*4 downto 2*4);
	CBBunches(24) <= Module5IN(1+2*5 downto 2*5);
	CBBunches(27) <= Module5IN(1+2*6 downto 2*6);
	CBBunches(28) <= Module5IN(1+2*7 downto 2*7);
	CBBunches(29) <= Module5IN(1+2*8 downto 2*8);
	CBBunches(30) <= Module5IN(1+2*9 downto 2*9);
	CBBunches(33) <= Module5IN(1+2*10 downto 2*10);
	CBBunches(34) <= Module5IN(1+2*11 downto 2*11);
	CBBunches(41) <= Module5IN(1+2*12 downto 2*12);
	CBBunches(42) <= Module5IN(1+2*13 downto 2*13);
	CBBunches(47) <= Module5IN(1+2*14 downto 2*14);
	CBBunches(48) <= Module5IN(1+2*15 downto 2*15);

	--Module 6
	CBBunches(45) <= Module6IN(1+2*0 downto 2*0);
	CBBunches(46) <= Module6IN(1+2*1 downto 2*1);
	CBBunches(5)  <= Module6IN(1+2*2 downto 2*2);
	CBBunches(6)  <= Module6IN(1+2*3 downto 2*3);
	CBBunches(17) <= Module6IN(1+2*4 downto 2*4);
	CBBunches(18) <= Module6IN(1+2*5 downto 2*5);
	CBBunches(11) <= Module6IN(1+2*6 downto 2*6);
	CBBunches(12) <= Module6IN(1+2*7 downto 2*7);
	CBBunches(35) <= Module6IN(1+2*8 downto 2*8);
	CBBunches(36) <= Module6IN(1+2*9 downto 2*9);


	CompileCompleteHitPatternRegisterOut: for i in 1 to 90 generate begin
		CompleteHitPatternRegisterOut(1+(i-1)*2 downto 0+(i-1)*2) <= CBBunches(i);
	end generate;

end Behavioral;

