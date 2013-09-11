library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use Package_CB_Configuration.ALL;


entity CellProcessor is
	generic (CrystalNo : integer);
    Port ( Neighbour1 : in  STD_LOGIC;
           Neighbour2 : in  STD_LOGIC;
           Neighbour3 : in  STD_LOGIC;
           Neighbour4 : in  STD_LOGIC;
           Neighbour5 : in  STD_LOGIC;
           Neighbour6 : in  STD_LOGIC;
           Neighbour7 : in  STD_LOGIC;
           Neighbour8 : in  STD_LOGIC;
           Neighbour9 : in  STD_LOGIC;
           Neighbour10 : in  STD_LOGIC;
           Neighbour11 : in  STD_LOGIC;
           Neighbour12 : in  STD_LOGIC;
           ActualCrystalState : out  STD_LOGIC;
			  LoadCrystalState : in STD_LOGIC;
			  ProcessingActive : in STD_LOGIC;
           CellReadyStep2 : out  STD_LOGIC;
           Reset : in  STD_LOGIC;
			  clock : in  STD_LOGIC;
			  Rule5ActiveCell : in STD_LOGIC  -- to enable only one rule 2.5.x at the same time
			  );
end CellProcessor;

architecture Behavioral of CellProcessor is
	signal Ngh123 : STD_LOGIC_Vector(1 to 3);
	signal Ngh45, Ngh67, Ngh89 : STD_LOGIC_Vector(1 to 2);
	signal Ngh1235610 : STD_LOGIC_Vector(1 to 6);
	signal InternalActualCrystalState : STD_LOGIC;
begin
	Ngh123 <= Neighbour1&Neighbour2&Neighbour3;
	Ngh45 <= Neighbour4&Neighbour5;
	Ngh67 <= Neighbour6&Neighbour7;
	Ngh89 <= Neighbour8&Neighbour9;
	Ngh1235610 <= Ngh123&Neighbour5&Neighbour6&Neighbour10;

	ActualCrystalState <= InternalActualCrystalState;
	
	process (Reset, ProcessingActive, clock, LoadCrystalState)
	begin
		if (Reset = '1') then
			InternalActualCrystalState <= LoadCrystalState;
		elsif rising_edge(clock) and (ProcessingActive = '1') then
					
			-- Falls StateHealingModeActive = '0' dann ist die Zweite Phase erreicht
			-- Regel 2.1.1, 2.2.1 und 2.3.1
			if (Ngh123 = "100") and (Ngh45 /= "0") then
				InternalActualCrystalState <= '0';
			end if;
			-- Regel 2.1.2, 2.2.2 und 2.3.2
			if (Ngh123 = "010") and (Ngh67 /= "0") then
				InternalActualCrystalState <= '0';
			end if;
			-- Regel 2.1.3, 2.2.3 und 2.3.3
			if (Ngh123 = "001") and (Ngh89 /= "0") then
				InternalActualCrystalState <= '0';
			end if;
			
			-- Regel 2.4.1
			if (Ngh123 = "100") and (Ngh45 = "00") and 
				(
					-- up cell and not cutEdge
					( (CBCrystalsOrientation(CrystalNo) = '1') and (CBCrystalsIsCutEdge(CrystalNo) = '0') )
				or
					-- down cell and cutEdge
					( (CBCrystalsOrientation(CrystalNo) = '0') and (CBCrystalsIsCutEdge(CrystalNo) = '1') )
				) then
				InternalActualCrystalState <= '0';
			end if;
			-- Regel 2.4.2, up cell only
			if (Ngh123 = "010") and (Ngh67 = "00") and 
				(CBCrystalsOrientation(CrystalNo) = '1') then
				InternalActualCrystalState <= '0';
			end if;
			-- Regel 2.4.3, up cell only
			if (Ngh123 = "001") and (Ngh89 = "00") and 
				(CBCrystalsOrientation(CrystalNo) = '1') then
				InternalActualCrystalState <= '0';
			end if;

			-- Regel 2.5.1
			if (Ngh1235610 = "110111") and 
				(
					--if not pole cell
					(CBCrystalsIsPole(CrystalNo) = '0')
				or
					--if pole cell, then only if it's cell 5/1/1 or cell 4/1/1
					(CBCrystalsIsOnly2Pole(CrystalNo) = '1')
				)
				and 
				(
					--up cell and (turns mod 6) = 0
					( (CBCrystalsOrientation(CrystalNo) = '1') and (Rule5ActiveCell = '1') )
				or
					--down cell and (turns mod 6) = 3
					( (CBCrystalsOrientation(CrystalNo) = '0') and (Rule5ActiveCell = '0') )
				) then
				InternalActualCrystalState <= '0';
			end if;
			
		end if;
	end process;
	
	CellReadyStep2 <= '1' when 
		(Reset = '0') and ( (LoadCrystalState = '0') or (Ngh123 = "000") or (InternalActualCrystalState = '0') ) 
		else '0';

end Behavioral;