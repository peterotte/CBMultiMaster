
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;



entity FlexibleAdder is
	generic (SizeOfInput1, SizeOfInput2, SizeOfOutput : integer);
    Port ( BitPattern1 : in  STD_LOGIC_VECTOR (SizeOfInput1-1 downto 0);
           BitPattern2 : in  STD_LOGIC_VECTOR (SizeOfInput2-1 downto 0);
           BitCounts : out  STD_LOGIC_VECTOR (SizeOfOutput-1 downto 0)); --SizeOfOutput always needs to be 1 number greater than biggest
end FlexibleAdder;

architecture Behavioral of FlexibleAdder is
	signal mytest1, mytest2, mytest, temp : unsigned(SizeOfOutput-1 downto 0);
begin
	temp <= (others => '0');
	mytest1 <= temp(SizeOfOutput-1 downto SizeOfInput1)&unsigned(BitPattern1);
	mytest2 <= temp(SizeOfOutput-1 downto SizeOfInput2)&unsigned(BitPattern2);
	
	mytest <= mytest1 + mytest2;
	
	BitCounts <= STD_LOGIC_VECTOR( mytest );
end Behavioral;

