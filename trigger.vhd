-- Written by Peter Otte 2009-2012
--
-- history:
-- x1302156d: now scalers back
-- x1302156c: TAPS WIDTH now back to 130
-- x1302156b: TAPS delay now again 24, TAPS now really contributing to the Multiplicity
-- x1302156a: changed ToOsziAndScaler_out, Took TAPS LED1 into Multiplicity (but did not work)
-- x13021569: To match the CB and TAPS signals: Just let the TAPS signal come a bit earlier then the CB signals
--            new settings
-- x13021568: To match the CB and TAPS signals:
--            CB OR signal comes at 94 units (relative time) and TAPS between 86 and 105 units (mean: 93.5)
--            goal: slowest TAPS signal should be there before CB signal arrives
--            Changed: Strobe. TAPS delay now only 13 (was 25), TAPS width= 140 (was 130)
--            CB strobe is delayed by 4 units, and TAPS strobe is delayed by 24 units
-- x13021567: Added: Gates and changed TimeOut "		if (FSM2Step = FSM2ResetANDLoad) or (FSM2Step = FSM2TimeOut) then "
-- x13021566: Delayed all TAPS Signals (25 units), took Scalers out
-- x12120365: Changed length of FSM2TypeMultiplicityControllerStep from 3..0 to 2..0
-- x12120364:
-- x12112630: added Simulate_L1Strobe_Via_VME
-- x12112631: removed some VME readouts, resized SpecificAdder to 256 inputs only, 
--            MultiplicityControler: teilweise clock50 ersetzt durch clock100
-- x12112632: MyMultiplicityController now with 2* clock400
-- x12112636: Changed clocks and increased InterUsedTurnsForTrigger
-- x12112737: use bit 4 for InterUsedTurnsForTrigger
-- x12112738: ResetFSM reset now syncronous, changed VME addresses
-- x12112839: Changed: MultiplicityNumberOfClusters
-- x1211283a: Changed: trig_out
-- x1211303b: Changed: 	trig_out(31 downto 17) <= trig_in(15 downto 0);
-- x1211303c: Added CB_AllOR
-- x1211303d: Added FSMReset and dropped MasterReset

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;																						
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use Package_CB_Configuration.ALL;

entity trigger is
	port (
		clock50 : in STD_LOGIC;
		clock100 : in STD_LOGIC;
		clock200 : in STD_LOGIC;
		clock400 : in STD_LOGIC; 
		trig_in : in STD_LOGIC_VECTOR (32*7-1 downto 0);		
		trig_out : out STD_LOGIC_VECTOR (31 downto 0);		
		ToOsziAndScaler_out : out STD_LOGIC_VECTOR (32*8-1 downto 0);
		nim_in   : in  STD_LOGIC;
		nim_out  : out STD_LOGIC;
		led	     : out STD_LOGIC_VECTOR(8 downto 1); -- 8 LEDs onboard
		pgxled   : out STD_LOGIC_VECTOR(8 downto 1); -- 8 LEDs on PIG board
		VN2andVN1 : in std_logic_vector(7 downto 0);
--............................. vme interface ....................
		u_ad_reg :in std_logic_vector(11 downto 2);
		u_dat_in :in std_logic_vector(31 downto 0);
		u_data_o :out std_logic_vector(31 downto 0);
		oecsr, ckcsr:in std_logic
	);
end trigger;


architecture RTL of trigger is

	subtype sub_Address is std_logic_vector(11 downto 4);
	constant BASE_TRIG_ResetFSM_Via_VME : sub_Address      			:= x"01"; -- w
	constant BASE_TRIG_Simulate_Strobe_Via_VME : sub_Address 		:= x"02"; --write '1' into it

	constant BASE_TRIG_MultiplicityNumberOfClusters  : sub_Address	:= x"52"; -- r
	constant BASE_TRIG_GetFSMState : sub_Address   						:= x"56"; -- r
	constant BASE_TRIG_MultiplicityUsedTurnsForTrigger : sub_Address := x"58"; -- r

	---
	constant BASE_TRIG_HitPattern_AfterPro1  : sub_Address    		:= x"61"; -- r
	constant BASE_TRIG_HitPattern_AfterPro2  : sub_Address    		:= x"62"; -- r
	constant BASE_TRIG_HitPattern_AfterPro3  : sub_Address   		:= x"63"; -- r
	constant BASE_TRIG_HitPattern_AfterPro4  : sub_Address    		:= x"64"; -- r
	constant BASE_TRIG_HitPattern_AfterPro5  : sub_Address    		:= x"65"; -- r
	constant BASE_TRIG_HitPattern_AfterPro6  : sub_Address    		:= x"66"; -- r
	---
	constant BASE_TRIG_HitPattern_Simulation1  : sub_Address    	:= x"a1"; -- rw
	constant BASE_TRIG_HitPattern_Simulation2  : sub_Address    	:= x"a2"; -- rw
	constant BASE_TRIG_HitPattern_Simulation3  : sub_Address    	:= x"a3"; -- rw
	constant BASE_TRIG_HitPattern_Simulation4  : sub_Address    	:= x"a4"; -- rw
	constant BASE_TRIG_HitPattern_Simulation5  : sub_Address    	:= x"a5"; -- rw
	constant BASE_TRIG_HitPattern_Simulation6  : sub_Address    	:= x"a6"; -- rw
	--	
	constant BASE_TRIG_HitPattern_LeadingToTrigger_1 : sub_Address := x"b1"; -- r
	constant BASE_TRIG_HitPattern_LeadingToTrigger_2 : sub_Address := x"b2"; -- r
	constant BASE_TRIG_HitPattern_LeadingToTrigger_3 : sub_Address := x"b3"; -- r
	constant BASE_TRIG_HitPattern_LeadingToTrigger_4 : sub_Address := x"b4"; -- r
	constant BASE_TRIG_HitPattern_LeadingToTrigger_5 : sub_Address := x"b5"; -- r
	constant BASE_TRIG_HitPattern_LeadingToTrigger_6 : sub_Address := x"b6"; -- r
	constant BASE_TRIG_HitPattern_LeadingToTrigger_7 : sub_Address := x"b7"; -- r
	
	
	--debug
	constant BASE_TRIG_Debug_ActualState : sub_Address							:= x"e0"; --r
	constant BASE_TRIG_SelectedDebugInput_1 : sub_Address						:= x"e1"; --r/w
	constant BASE_TRIG_SelectedDebugInput_2 : sub_Address						:= x"e2"; --r/w
	constant BASE_TRIG_SelectedDebugInput_3 : sub_Address						:= x"e3"; --r/w
	constant BASE_TRIG_SelectedDebugInput_4 : sub_Address						:= x"e4"; --r/w

	---
	
	constant BASE_TRIG_FIXED : sub_Address 								:= x"f0" ; -- r
	constant TRIG_FIXED : std_logic_vector(31 downto 0) 				:= x"0800006e"; 
	
	--------------------------------------------
	-- external signals in
	signal AllStrobe, CBStrobe, CBStrobe_delayed : std_logic;
	-- external signal out
	signal TriggerBusy : std_logic; 
	--------------------------------------------

	--
	signal ResetFSM : std_logic;
	signal Simulate_Strobe_Via_VME : std_logic;
	signal ResetFSM_Via_VME : std_logic;
	
	signal CompleteHitPatternRegister, HitPatternRegister_Simulation : std_logic_vector (CBCrystalsCount-1 downto 0);
	signal InputPatternLeadingToSimpleTrigger : std_logic_vector(32*7-1 downto 0);

	--------------------------------------------
	--signals for MultiplicityController
	signal MultiplicityResetAndLoad : std_logic;
	signal MultiplicityNumberOfClusters : std_logic_vector(8 downto 0);
	signal MultiplicityUsedTurnsForTrigger : std_logic_Vector(10 downto 0);
	signal MultiplicityResetDueError_Out : std_logic;
	signal MultiplicityHitPatternAfterProcessing : std_Logic_vector(CBCrystalsCount-1 downto 0);
	--------------------------------------------
	
	component InputMixer is
		Port ( 
			Module1IN : in  STD_LOGIC_VECTOR (31 downto 0);
			Module2IN : in  STD_LOGIC_VECTOR (31 downto 0);
			Module3IN : in  STD_LOGIC_VECTOR (31 downto 0);
			Module4IN : in  STD_LOGIC_VECTOR (31 downto 0);
			Module5IN : in  STD_LOGIC_VECTOR (31 downto 0);
			Module6IN : in  STD_LOGIC_VECTOR (19 downto 0);
			CompleteHitPatternRegisterOut : out  STD_LOGIC_VECTOR (179 downto 0)
		);
	end component;
	
	--Always use gray code for FSM!! http://en.wikipedia.org/wiki/Gray_code
	attribute safe_recovery_state: string;
	attribute safe_implementation: string;
	attribute fsm_encoding: string;

	--------------------------------------------------
	signal CB_AllOR, TAPS_AllOR : std_logic;
	signal TAPS_CFDs, TAPS_LED1s, TAPS_LED2s, TAPS_PWOs : std_logic_vector(5 downto 0);
	
	--------------------------------------------------
	
	component gate_by_shiftreg
		Generic (
			WIDTH : integer
		);
		 Port ( CLK : in STD_LOGIC;
				  SIG_IN : in  STD_LOGIC;
				  GATE_OUT : out  STD_LOGIC
		);
	end component;
	
	
	component delay_by_shiftregister
		Generic (
			DELAY : integer
		);
		 Port ( CLK : in  STD_LOGIC;
				  SIG_IN : in  STD_LOGIC;
				  DELAY_OUT : out  STD_LOGIC);
	end component;
	
	signal tapsmaster_in_delayed, tapsmaster_in_delayed_gated : std_logic_vector(31 downto 0);



	--------------------------------------------------
	--for debugging purposes:
	constant NumberOfMultiplicityTriggers : integer := 10; --The highest one (NumberOfMultiplicityTriggers-1) covers always the rest > NumberOfMultiplicityTriggers-2: 
	signal MultiplicityTriggerOut, MultiplicityTriggerOutG : 
		std_logic_vector(NumberOfMultiplicityTriggers-1 downto 0) := (others => '0'); --During FSMPossiblyTriggerOut one 
		-- signal becomes '1' depending on the result of the Multiplicity
	
	
	
	-----------------------------------------------------------------------------------------------
	--Coming from Multiplicity Controller
	
	
	--FSM States
	subtype FSM2TypeMultiplicityControllerStep is std_logic_vector(2 downto 0);
	constant FSM2Recovery : FSM2TypeMultiplicityControllerStep 			:= "100";
	constant FSM2ResetANDLoad : FSM2TypeMultiplicityControllerStep 	:= "000";
	constant FSM2SecondStep : FSM2TypeMultiplicityControllerStep 		:= "001";
	constant FSM2Counting1 : FSM2TypeMultiplicityControllerStep 		:= "011";
	constant FSM2Counting2 : FSM2TypeMultiplicityControllerStep 		:= "010";
	constant FSM2SaveResults : FSM2TypeMultiplicityControllerStep 		:= "110";
	constant FSM2Ready : FSM2TypeMultiplicityControllerStep 				:= "111";
	constant FSM2TimeOut : FSM2TypeMultiplicityControllerStep 			:= "101";
	signal FSM2Step, FSM2Step_Next : FSM2TypeMultiplicityControllerStep;

	--Always use gray code for FSM!! http://en.wikipedia.org/wiki/Gray_code
	--attribute safe_recovery_state: string;
	attribute safe_recovery_state of FSM2Step:signal is "100";
	--attribute safe_implementation: string;
	attribute safe_implementation of FSM2Step: signal is "yes";
	--attribute fsm_encoding: string;
	attribute fsm_encoding of FSM2Step: signal is "user";

	----------------------------	
	
	subtype Type_HitPatternVector_CB is STD_LOGIC_VECTOR(CBCrystalsCount-1 downto 0);
	signal HitPatternVector_CB, HitPatternVector_Saved_CB : Type_HitPatternVector_CB;
	signal HitPatternVector_TAPS, HitPatternVector_Saved_TAPS : STD_LOGIC_VECTOR(5 downto 0);
	signal HitPatternVector_Saved_CBTAPS : STD_LOGIC_VECTOR(CBCrystalsCount-1+6 downto 0);
	signal CellsReadyStep2 : STD_LOGIC_VECTOR(CBCrystalsCount-1 downto 0);
	signal CellProcessingActive : std_logic;

	COMPONENT CellProcessor
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
	end COMPONENT;
	
	------------------------------------------------------------------------------------

	component SpecificAdder is
    Port ( Clock200 : in std_logic;
				EnableClusterCouting : in STD_LOGIC;
			  HitPattern : in  STD_LOGIC_VECTOR (CBCrystalsCount-1+6 downto 0);
           HitCounts : out  STD_LOGIC_VECTOR (8 downto 0)
			);
	end component;
	
	-- Cluster Couting Signals
	signal EnableClusterCouting : STD_LOGIC;
	signal ClusterCoutingResult, ClusterCoutingResult_Saved : STD_LOGIC_VECTOR (8 downto 0);

	------------------------------------------------------------------------------------
	-- Trigger Settings
	signal TriggerOnNumberOfEvents : STD_LOGIC_VECTOR(11 downto 0);
	signal StopAfterTrigger : STD_LOGIC;
	
	signal InterUsedTurnsForTrigger : std_logic_vector(10 downto 0);
	
	signal Rule5ActiveCell : std_logic := '0'; --To enable only one rule 5 at the same time
	

	constant NStep2Reduc : integer := 8;
	signal CellsReadyStep2_Part1, CellsReadyStep2_Part1_Saved : std_logic_vector(CBCrystalsCount/NStep2Reduc-1 downto 0);
	signal CellsReadyStep2_Part2 : std_logic;
	
	
	----------------------------------------------------------------------------------

	constant NDebugSignalOutputs : integer := 4;
	signal DebugSignals : std_logic_vector(255 downto 0);
	signal SelectedDebugInput : std_logic_vector(8*NDebugSignalOutputs-1 downto 0);
	signal Debug_ActualState : std_logic_vector(NDebugSignalOutputs-1 downto 0);

	COMPONENT DebugChSelector
	PORT(
		DebugSignalsIn : IN std_logic_vector(255 downto 0);
		SelectedInput : IN std_logic_vector(7 downto 0);          
		SelectedOutput : OUT std_logic
		);
	END COMPONENT;

	------------------------------------------------------------------------------
	

begin

	-------------------------------------------------------------------------------------------------
	-- Debug Selector
	DebugSignals(32*7-1 downto 0) <= trig_in(32*7-1 downto 0);
	DebugSignals(255) <= nim_in;
	DebugChSelectors: for i in 0 to NDebugSignalOutputs-1 generate
   begin
		Inst_DebugChSelector: DebugChSelector PORT MAP(
			DebugSignalsIn => DebugSignals,
			SelectedInput => SelectedDebugInput((i+1)*8-1 downto i*8),  ---needs VME write
			SelectedOutput => Debug_ActualState(i)
		);
	end generate;
	-------------------------------------------------------------------------------------------------


	------------------------------------------------------------------------------------------------
--	ResetFSM <= ResetFSM_Via_VME or nim_in;
	ResetFSM <= ResetFSM_Via_VME;


	--Simulated Inputs
	--CompleteHitPatternRegister <= HitPatternRegister_Simulation;
	
	--------------------------------------------------------
	-- CB Inputs
	--------------------------------------------------------
	--Real inputs
	MyInputMixer: InputMixer port map (
		Module1IN => trig_in(31+32*0 downto 0+32*0),
		Module2IN => trig_in(31+32*1 downto 0+32*1),
		Module3IN => trig_in(31+32*2 downto 0+32*2),
		Module4IN => trig_in(31+32*3 downto 0+32*3),
		Module5IN => trig_in(31+32*4 downto 0+32*4),
		Module6IN => trig_in(19+32*5 downto 0+32*5),
		CompleteHitPatternRegisterOut => CompleteHitPatternRegister
	);

	CB_AllOR <= '1' when CompleteHitPatternRegister /= "0" else '0';
	nim_out <= CB_AllOR;
	
	--------------------------------------------------------
	-- TAPS Inputs
	--------------------------------------------------------
	
	-- trig_in(7*32-1..6*32), INOUT4
	-- 5..0 (): CFD_SectorORs
	-- 11..6: LED1_SectorORs
	-- 17..12 (): LED2_SectorORs
	-- 23..18 (): PWO_SectorORs;
	TAPS_CFDs <= trig_in(6*32+5  downto 0+6*32);
	TAPS_LED1s <= trig_in(6*32+11 downto 6+6*32);
	TAPS_LED2s <= trig_in(6*32+17 downto 12+6*32);
	TAPS_PWOs  <= trig_in(6*32+23 downto 18+6*32);
	
	HitPatternVector_TAPS <= TAPS_LED1s; --Select LED1 from TAPS for the Multiplcitiy
	
	TAPS_AllOR <= '1' when TAPS_LED1s /= "0" else '0';
	
	TAPS_Delayboxes: for i in 0 to 32-1 generate --INOUT4
	begin
		delay_by_shiftregister_1: delay_by_shiftregister Generic MAP (	DELAY => 24 ) 
			 Port Map ( CLK => clock200,
					  SIG_IN => trig_in(i+6*32),
					  DELAY_OUT => tapsmaster_in_delayed(i)
			);
			
		TAPS_gate_by_shiftreg_GateSignal_1: gate_by_shiftreg Generic MAP (
				WIDTH => 130 --9.10.2012: Value=15 (ergab eine Gatelaenge von 12*5ns (mit 1-2*5ns jitter))
			)
			Port MAP ( CLK => clock200,
				  SIG_IN => tapsmaster_in_delayed(i),
				  GATE_OUT => tapsmaster_in_delayed_gated(i)
		);
	end generate;


	--------------------------------------------------------------
	-- Strobe
	--------------------------------------------------------------
	CBStrobe <= CB_AllOR;
	
	CB_DelayStrobe: delay_by_shiftregister Generic MAP ( DELAY=>4 ) 
		Port map ( CLK => clock200, SIG_IN => CBStrobe, DELAY_OUT => CBStrobe_delayed);

	AllStrobe <= CBStrobe_delayed or Simulate_Strobe_Via_VME;
	

	--------------------------------------------------------------

	------------------------------------------------------------------------------------------------
	-- Multiplicity
	------------------------------------------------------------------------------------------------

	------------------------------------------------------------------------------------------
	---- Generate 180 processing Cells for Crystal Ball
	------------------------------------------------------------------------------------------
	cells: for i in 0 to CBCrystalsCount-1 generate
   begin
		cellprocessor1: CellProcessor 
			GENERIC MAP (CrystalNo => i)
			PORT map (
			Neighbour1 => HitPatternVector_CB(CBCrystalNeighbours(i,1)), 
			Neighbour2 => HitPatternVector_CB(CBCrystalNeighbours(i,2)), 
			Neighbour3 => HitPatternVector_CB(CBCrystalNeighbours(i,3)), 
			Neighbour4 => HitPatternVector_CB(CBCrystalNeighbours(i,4)), 
			Neighbour5 => HitPatternVector_CB(CBCrystalNeighbours(i,5)), 
			Neighbour6 => HitPatternVector_CB(CBCrystalNeighbours(i,6)), 
			Neighbour7 => HitPatternVector_CB(CBCrystalNeighbours(i,7)), 
			Neighbour8 => HitPatternVector_CB(CBCrystalNeighbours(i,8)), 
			Neighbour9 => HitPatternVector_CB(CBCrystalNeighbours(i,9)), 
			Neighbour10 => HitPatternVector_CB(CBCrystalNeighbours(i,10)), 
			Neighbour11 => HitPatternVector_CB(CBCrystalNeighbours(i,11)), 
			Neighbour12 => HitPatternVector_CB(CBCrystalNeighbours(i,12)), 
			ActualCrystalState => HitPatternVector_CB(i),
			LoadCrystalState => CompleteHitPatternRegister(i),
			ProcessingActive => CellProcessingActive,
         CellReadyStep2 => CellsReadyStep2(i),
			Reset => MultiplicityResetAndLoad, --Reset Load Data Into Cells
			clock => clock200,
			Rule5ActiveCell => Rule5ActiveCell
		);
	end generate cells;
	MultiplicityHitPatternAfterProcessing <= HitPatternVector_CB;
	------------------------------------------------------------------------------------------


	------------------------------------------------------------------------------------------------
	-- Control finite state machine
	------------------------------------------------------------------------------------------------
	FSM2_State: process (clock200)
	begin
		if rising_edge(clock200) then
			if (ResetFSM = '1') then			
				FSM2Step <= FSM2ResetANDLoad;
			elsif InterUsedTurnsForTrigger(4) = '1' then --too many FSM turns, using bit10 with 100MHz -> 10µs , 1,2µs with bit7
				FSM2Step <= FSM2TimeOut;
			else
				FSM2Step <= FSM2Step_Next;
			end if;
		end if;
	end process;
			
	process (clock200)
	begin
		if rising_edge(clock200) then
			if (FSM2Step = FSM2ResetANDLoad) or (FSM2Step = FSM2TimeOut) then
				InputPatternLeadingToSimpleTrigger <= (7*32-1 downto CompleteHitPatternRegister'high+1 => '0')&CompleteHitPatternRegister;
				InterUsedTurnsForTrigger <= (others => '0');
			elsif (FSM2Step = FSM2SecondStep) then --Used for the counting procedure after SecondStep
				HitPatternVector_Saved_CB <= HitPatternVector_CB;
				HitPatternVector_Saved_TAPS <= HitPatternVector_TAPS;
			elsif (FSM2Step = FSM2SaveResults) then --after the results is there
				ClusterCoutingResult_Saved <= ClusterCoutingResult;
			end if;

			if (FSM2Step = FSM2SecondStep) then
				InterUsedTurnsForTrigger <= InterUsedTurnsForTrigger + 1;
			end if;
			
		end if;
	end process;
	MultiplicityResetAndLoad <= '1' when FSM2Step = FSM2ResetANDLoad else '0'; --Reset Load Data Into Cells
	Rule5ActiveCell <= InterUsedTurnsForTrigger(0);
	MultiplicityUsedTurnsForTrigger <= InterUsedTurnsForTrigger;
	
	
	GCellsReadyStep2_Part1: for i in 0 to (CBCrystalsCount/NStep2Reduc-1) generate
		CellsReadyStep2_Part1(i) <= '1' when 
			(not (CellsReadyStep2((i+1)*NStep2Reduc-1 downto i*NStep2Reduc))) = "0" else '0';
	end generate;
	
	process (clock200)
	begin
		if rising_edge(clock200) then
			CellsReadyStep2_Part1_Saved <= CellsReadyStep2_Part1;
		end if;
	end process;
	CellsReadyStep2_Part2 <= '1' when (not CellsReadyStep2_Part1_Saved) = "0" else '0';
	
	FSM2_Next: process (FSM2Step)
	begin
		if (FSM2Step = FSM2ResetANDLoad) and (AllStrobe = '1') then
			FSM2Step_Next <= FSM2SecondStep;
		elsif (FSM2Step = FSM2ResetANDLoad) then
			FSM2Step_Next <= FSM2ResetANDLoad;

		--when FSM2SecondStep
		--elsif (FSM2Step = FSM2SecondStep) and (CellsReadyStep2 = (CellsReadyStep2'range => '1')) then
		elsif (FSM2Step = FSM2SecondStep) and (CellsReadyStep2_Part2 = '1') then
			FSM2Step_Next <= FSM2Counting1;
		elsif (FSM2Step = FSM2SecondStep) then
			FSM2Step_Next <= FSM2SecondStep;
			
		elsif (FSM2Step = FSM2Counting1) then --Wait until count of clusters processed
			FSM2Step_Next <= FSM2Counting2;
		elsif (FSM2Step = FSM2Counting2) then --Wait until count of clusters processed
			FSM2Step_Next <= FSM2SaveResults;
		elsif (FSM2Step = FSM2SaveResults) then
			FSM2Step_Next <= FSM2Ready;
		elsif (FSM2Step = FSM2Ready) then
			--FSM2Step_Next <= FSM2Ready;
			FSM2Step_Next <= FSM2ResetANDLoad;
		elsif (FSM2Step = FSM2Recovery) then
			FSM2Step_Next <= FSM2ResetANDLoad;
		elsif (FSM2Step = FSM2TimeOut) then
			FSM2Step_Next <= FSM2ResetANDLoad;
		else
			FSM2Step_Next <= FSM2Recovery;
		end if;
	end process;
	
	MultiplicityResetDueError_Out <= '1' when (FSM2Step = FSM2Recovery) or (FSM2Step = FSM2TimeOut) else '0';

	
	-- Enable Cell Processing
	CellProcessingActive <= '1' when (FSM2Step = FSM2SecondStep) else '0';

	------------------------------------------------------------------------------------------

	------------------------------------------------------------------------------------------
	-- Generate Counting Cells
	------------------------------------------------------------------------------------------
	-- Enable ClusterCouting
	EnableClusterCouting <= '1' when (FSM2Step = FSM2Counting1) or (FSM2Step = FSM2Counting2) or (FSM2Step = FSM2SaveResults) or (FSM2Step = FSM2Ready) else '0';

	--SpecificAdder1: SpecificAdder PORT MAP (Clock200, '1', HitPatternVector_Saved, ClusterCoutingResult);
	HitPatternVector_Saved_CBTAPS <= HitPatternVector_Saved_CB & HitPatternVector_Saved_TAPS;
	SpecificAdder1: SpecificAdder PORT MAP (Clock200, '1', HitPatternVector_Saved_CBTAPS, ClusterCoutingResult);

	MultiplicityNumberOfClusters <= ClusterCoutingResult_Saved;
	------------------------------------------------------------------------------------------



	------------------------------------------------------------------------------------------------
	
	TriggerBusy <= '0' when (FSM2Step = FSM2ResetANDLoad) else '1';

	---------------------------------------------------------------------------------------------------------	

	------------------------------------------------------------------------------------------------
	-- LEDs out
	------------------------------------------------------------------------------------------------
	led(1) <= '0';
	led(2) <= '1' when trig_in(32*1-1 downto 0+32*0) /= "0" else '0';
	led(3) <= '0';
	led(4) <= '1' when trig_in(32*2-1 downto 0+32*1) /= "0" else '0';
	led(5) <= '0';
	led(6) <= '1' when trig_in(32*3-1 downto 0+32*2) /= "0" else '0';
	led(8 downto 7) <= "00";
	pgxled(1) <= '0';
	pgxled(2) <= '1' when trig_in(32*4-1 downto 0+32*3) /= "0" else '0';
	pgxled(3) <= '0';
	pgxled(4) <= '1' when trig_in(32*5-1 downto 0+32*4) /= "0" else '0';
	pgxled(5) <= '0';
	pgxled(6) <= '1' when trig_in(32*6-1 downto 0+32*5) /= "0" else '0';
	pgxled(7) <= '0';
	pgxled(8) <= '1' when trig_in(32*7-1 downto 0+32*6) /= "0" else '0';
	------------------------------------------------------------------------------------------------
	

	-----------------------------------------------------------------------------------------------
	-- Produce Multiplicity Trigger Signals
	-----------------------------------------------------------------------------------------------
	GenMultiplicityTriggersOut: for i in 0 to NumberOfMultiplicityTriggers-3 generate begin
		MultiplicityTriggerOut(i) <= '1' when ( (FSM2Step = FSM2Ready) and 
			(MultiplicityNumberOfClusters(8 downto 0) = CONV_STD_LOGIC_VECTOR(i, 9)) ) else '0';
		end generate;
	MultiplicityTriggerOut(NumberOfMultiplicityTriggers-2) <= '1' when ( (FSM2Step = FSM2Ready) and 
		(MultiplicityNumberOfClusters(8 downto 2) /= "0") ) else '0';
	MultiplicityTriggerOut(NumberOfMultiplicityTriggers-1) <= '1' when ( (FSM2Step = FSM2Ready) and 
		(MultiplicityNumberOfClusters(8 downto 3) /= "0") ) else '0';
	-----------------------------------------------------------------------------------------------
	
	GateGen_MultiplicityTriggerOuts: for i in 0 to NumberOfMultiplicityTriggers-1 generate begin
		GateGen_MultiplicityTriggerOut: gate_by_shiftreg GENERIC MAP ( WIDTH => 35 	)
			PORT MAP( CLK => clock200, SIG_IN => MultiplicityTriggerOut(i), GATE_OUT => MultiplicityTriggerOutG(i)   );
	end generate;
		
	-----------------------------------------------------------------------------------------------


	ToOsziAndScaler_out(0) <= AllStrobe;
	ToOsziAndScaler_out(1) <= '1' when FSM2Step = FSM2Recovery else '0';
	ToOsziAndScaler_out(2) <= '1' when FSM2Step = FSM2ResetANDLoad else '0';
	ToOsziAndScaler_out(3) <= '1' when FSM2Step = FSM2SecondStep else '0';
	ToOsziAndScaler_out(4) <= '1' when FSM2Step = FSM2Counting1 else '0';
	ToOsziAndScaler_out(5) <= '1' when FSM2Step = FSM2Counting2 else '0';
	ToOsziAndScaler_out(6) <= '1' when FSM2Step = FSM2Ready else '0';
	ToOsziAndScaler_out(7) <= '1' when FSM2Step = FSM2TimeOut else '0';
	ToOsziAndScaler_out(8) <= '1' when FSM2Step = FSM2SaveResults else '0';
	ToOsziAndScaler_out(9) <= Rule5ActiveCell;
	ToOsziAndScaler_out(10) <= TAPS_AllOR;
	ToOsziAndScaler_out(11) <= TriggerBusy;
	ToOsziAndScaler_out(12+2 downto 12) <= ClusterCoutingResult_Saved(2 downto 0);
	ToOsziAndScaler_out(15+9 downto 15) <= MultiplicityTriggerOutG;
	ToOsziAndScaler_out(25+2 downto 25) <= FSM2Step;
	ToOsziAndScaler_out(28) <= '0';
	ToOsziAndScaler_out(29) <= '0';
	ToOsziAndScaler_out(30) <= CBStrobe_delayed;
	ToOsziAndScaler_out(31) <= CBStrobe;

	--ToOsziAndScaler_out(255 downto 32) <= trig_in;

	
--	ToOsziAndScaler_out(255 downto 32) <= trig_in(7*32-1 downto 6*32)&(6*32-1 downto CBCrystalsCount => '1')& CompleteHitPatternRegister; --before 14.2.2013
	ToOsziAndScaler_out(255 downto 32) <= tapsmaster_in_delayed_gated&(6*32-1 downto CBCrystalsCount => '1')& CompleteHitPatternRegister;
	
	
	--debug out
	trig_out(0) <= CBStrobe;
	trig_out(1) <= '1' when FSM2Step = FSM2Recovery else '0';
	trig_out(2) <= '1' when FSM2Step = FSM2ResetANDLoad else '0';
	trig_out(3) <= '1' when FSM2Step = FSM2SecondStep else '0';
	trig_out(4) <= '1' when FSM2Step = FSM2Counting1 else '0';
	trig_out(5) <= '1' when FSM2Step = FSM2Counting2 else '0';
	trig_out(6) <= '1' when FSM2Step = FSM2Ready else '0';
	trig_out(7) <= '1' when FSM2Step = FSM2TimeOut else '0';
	trig_out(8) <= '1' when FSM2Step = FSM2SaveResults else '0';
	trig_out(9) <= Rule5ActiveCell;
	trig_out(10) <= AllStrobe;
	trig_out(11) <= TriggerBusy;
	trig_out(12+2 downto 12) <= ClusterCoutingResult_Saved(2 downto 0);
	trig_out(15+9 downto 15) <= MultiplicityTriggerOutG;
	
	trig_out(30 downto 27) <= Debug_ActualState;
	
	trig_out(31) <= CB_AllOR;
	
	
	---------------------------------------------------------------------------------------------------------	
	-- Code for VME handling / access
	-- decoder for data registers
	-- handle write commands from vmebus
	---------------------------------------------------------------------------------------------------------	
	process(clock50, ckcsr, u_ad_reg)
	begin
		if (clock50'event and clock50 ='1') then
			ResetFSM_Via_VME <= '0';
			if (ckcsr='1' and u_ad_reg(11 downto 4)= BASE_TRIG_ResetFSM_Via_VME  ) then
				ResetFSM_Via_VME <= '1';
			end if;
			
			Simulate_Strobe_Via_VME <= '0';
			if (ckcsr='1' and u_ad_reg(11 downto 4)= BASE_TRIG_Simulate_Strobe_Via_VME  ) then
				Simulate_Strobe_Via_VME <= '1';
			end if;
			
			if ckcsr='1' then
				case u_ad_reg(11 downto 4) is
					when BASE_TRIG_HitPattern_Simulation1 => 
						HitPatternRegister_Simulation(32*0+31 downto 32*0+0) <= u_dat_in(31 downto 0);
					when BASE_TRIG_HitPattern_Simulation2 => 
						HitPatternRegister_Simulation(32*1+31 downto 32*1+0) <= u_dat_in(31 downto 0);
					when BASE_TRIG_HitPattern_Simulation3 => 
						HitPatternRegister_Simulation(32*2+31 downto 32*2+0) <= u_dat_in(31 downto 0);
					when BASE_TRIG_HitPattern_Simulation4 => 
						HitPatternRegister_Simulation(32*3+31 downto 32*3+0) <= u_dat_in(31 downto 0);
					when BASE_TRIG_HitPattern_Simulation5 => 
						HitPatternRegister_Simulation(32*4+31 downto 32*4+0) <= u_dat_in(31 downto 0);
					when BASE_TRIG_HitPattern_Simulation6 => 
						HitPatternRegister_Simulation(32*5+19 downto 32*5+0) <= u_dat_in(19 downto 0);
						
					--debug
					when BASE_TRIG_SelectedDebugInput_1 => 
						SelectedDebugInput(8*1-1 downto 8*0) <= u_dat_in(7 downto 0); 
					when BASE_TRIG_SelectedDebugInput_2 => 
						SelectedDebugInput(8*2-1 downto 8*1) <= u_dat_in(7 downto 0); 
					when BASE_TRIG_SelectedDebugInput_3 => 
						SelectedDebugInput(8*3-1 downto 8*2) <= u_dat_in(7 downto 0); 
					when BASE_TRIG_SelectedDebugInput_4 => 
						SelectedDebugInput(8*4-1 downto 8*3) <= u_dat_in(7 downto 0); 

					when others =>
						null;
				end case;
			end if;

		end if;
	end process;
	

	---------------------------------------------------------------------------------------------------------	
	-- Code for VME handling / access
	-- handle read commands from vmebus
	---------------------------------------------------------------------------------------------------------	
	process(clock50, oecsr, u_ad_reg)
	begin
		if (clock50'event and clock50 ='1') then
			if (oecsr ='1') then
				u_data_o(31 downto 0) <= (others => '0');
				case u_ad_reg(11 downto 4) is
					when BASE_TRIG_HitPattern_AfterPro1 => 
						u_data_o(31 downto 0) <= MultiplicityHitPatternAfterProcessing(32*0+31 downto 32*0+0);
					when BASE_TRIG_HitPattern_AfterPro2 => 
						u_data_o(31 downto 0) <= MultiplicityHitPatternAfterProcessing(32*1+31 downto 32*1+0);
					when BASE_TRIG_HitPattern_AfterPro3 => 
						u_data_o(31 downto 0) <= MultiplicityHitPatternAfterProcessing(32*2+31 downto 32*2+0);
					when BASE_TRIG_HitPattern_AfterPro4 => 
						u_data_o(31 downto 0) <= MultiplicityHitPatternAfterProcessing(32*3+31 downto 32*3+0);
					when BASE_TRIG_HitPattern_AfterPro5 => 
						u_data_o(31 downto 0) <= MultiplicityHitPatternAfterProcessing(32*4+31 downto 32*4+0);
					when BASE_TRIG_HitPattern_AfterPro6 => 
						u_data_o(19 downto 0) <= MultiplicityHitPatternAfterProcessing(32*5+19 downto 32*5+0);
					
					---
					
					when BASE_TRIG_HitPattern_Simulation1 => 
						u_data_o(31 downto 0) <= HitPatternRegister_Simulation(32*0+31 downto 32*0+0);
					when BASE_TRIG_HitPattern_Simulation2 => 
						u_data_o(31 downto 0) <= HitPatternRegister_Simulation(32*1+31 downto 32*1+0);
					when BASE_TRIG_HitPattern_Simulation3 => 
						u_data_o(31 downto 0) <= HitPatternRegister_Simulation(32*2+31 downto 32*2+0);
					when BASE_TRIG_HitPattern_Simulation4 => 
						u_data_o(31 downto 0) <= HitPatternRegister_Simulation(32*3+31 downto 32*3+0);
					when BASE_TRIG_HitPattern_Simulation5 => 
						u_data_o(31 downto 0) <= HitPatternRegister_Simulation(32*4+31 downto 32*4+0);
					when BASE_TRIG_HitPattern_Simulation6 => 
						u_data_o(19 downto 0) <= HitPatternRegister_Simulation(32*5+19 downto 32*5+0);

					--
					
					when BASE_TRIG_HitPattern_LeadingToTrigger_1 =>
						u_data_o <= InputPatternLeadingToSimpleTrigger(31+0*32 downto 0+0*32);
					when BASE_TRIG_HitPattern_LeadingToTrigger_2 =>
						u_data_o <= InputPatternLeadingToSimpleTrigger(31+1*32 downto 0+1*32);
					when BASE_TRIG_HitPattern_LeadingToTrigger_3 =>
						u_data_o <= InputPatternLeadingToSimpleTrigger(31+2*32 downto 0+2*32);
					when BASE_TRIG_HitPattern_LeadingToTrigger_4 =>
						u_data_o <= InputPatternLeadingToSimpleTrigger(31+3*32 downto 0+3*32);
					when BASE_TRIG_HitPattern_LeadingToTrigger_5 =>
						u_data_o <= InputPatternLeadingToSimpleTrigger(31+4*32 downto 0+4*32);
					when BASE_TRIG_HitPattern_LeadingToTrigger_6 =>
						u_data_o <= InputPatternLeadingToSimpleTrigger(31+5*32 downto 0+5*32);
					when BASE_TRIG_HitPattern_LeadingToTrigger_7 =>
						u_data_o <= InputPatternLeadingToSimpleTrigger(31+6*32 downto 0+6*32);
						
					--
						
					when BASE_TRIG_FIXED => 
						u_data_o(31 downto 0) <= TRIG_FIXED;
					when BASE_TRIG_MultiplicityNumberOfClusters => 
						u_data_o(8 downto 0) <= MultiplicityNumberOfClusters;
					when BASE_TRIG_GetFSMState =>
						u_data_o(2 downto 0) <= FSM2Step;
					when BASE_TRIG_MultiplicityUsedTurnsForTrigger =>
						u_data_o(10 downto 0) <= MultiplicityUsedTurnsForTrigger;
						
						
					--
					--debug
					when BASE_TRIG_SelectedDebugInput_1 => 
						u_data_o(7 downto 0) <= SelectedDebugInput(8*1-1 downto 8*0);
					when BASE_TRIG_SelectedDebugInput_2 => 
						u_data_o(7 downto 0) <= SelectedDebugInput(8*2-1 downto 8*1); 
					when BASE_TRIG_SelectedDebugInput_3 => 
						u_data_o(7 downto 0) <= SelectedDebugInput(8*3-1 downto 8*2); 
					when BASE_TRIG_SelectedDebugInput_4 => 
						u_data_o(7 downto 0) <= SelectedDebugInput(8*4-1 downto 8*3);
					when BASE_TRIG_Debug_ActualState => 
						u_data_o(NDebugSignalOutputs-1 downto 0) <= Debug_ActualState; 

						
					when others =>
						u_data_o(31 downto 0) <= (others => '0');
				end case;
			end if;
		end if;
	end process;

end RTL;
