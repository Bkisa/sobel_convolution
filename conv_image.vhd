library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.convolution_pkg.all;

entity conv_image is
  port( 
    i_clk : in std_logic;
    i_rst : in std_logic;
    i_en  : in std_logic;
    i_start : in std_logic;
    i_data : in std_logic_vector(DATA_WIDTH - 1 downto 0);
    i_data_valid : in std_logic;
    i_kernel : in std_logic_vector(2 downto 0);
    o_addr : out std_logic_vector(log2_int(IMG_ROW * IMG_COLUNM) - 1 downto 0);
    o_addr_vld : out std_logic;
    o_data : out std_logic_vector(7 downto 0);
    o_data_vld : out std_logic;
    o_ok : out std_logic                
  );
end conv_image;

architecture Behavioral of conv_image is

  type processState_t is (IDLE, RAM_READ, WAIT_READ, SHIFT_MATRIX, CALC_CONV, CNT_CHECK, OK );  
  signal convImg : processState_t := RAM_READ; 

  signal s_data   : DATA_MATRIX := (others => (others => (others => '0')));   
  signal s_colunm : DATA_t := (others => (others => '0'));       

  signal n_i : integer := 0;
  signal n_j : integer := 0;
  signal n_k : integer := 0;
  signal n_s : integer := 0;
  
  signal r_addr : std_logic_vector(log2_int(IMG_ROW * IMG_COLUNM) - 1 downto 0) := (others => '0');    
  signal r_addr_vld : std_logic := '0';
  signal r_data : std_logic_vector(7 downto 0) := (others => '0');   
  signal r_data_vld : std_logic := '0';
  signal r_flag : std_logic := '0';
  signal r_sobel_ok : std_logic := '0';   
  signal r_OK : std_logic := '0';
   
begin

  o_addr <= r_addr;
  o_addr_vld <= r_addr_vld;
  o_data <= r_data;
  o_data_vld <= r_data_vld;
  o_ok <= r_OK;

  process(i_clk, i_rst, i_en)
  begin
    if i_rst = '1' then
      s_colunm <= (others => (others => '0'));  
      n_s <= 0;
      r_flag <= '0';
   elsif rising_edge(i_clk) then
      if i_en = '1' then
        if i_data_valid = '1' then
          s_colunm(n_s) <= i_data;
          n_s <= n_s + 1;
          if n_s = 2 then
            n_s <= 0; 
            r_flag <= '1';
          end if;
        else
          r_flag <= '0'; 
        end if;
            
      end if;
      
    end if;
  end process;
  
  process(i_clk, i_rst)
  begin
    if i_rst = '1' then
      s_data <= (others => (others => (others => '0'))); 
      convImg <= IDLE;
      n_i <= 0;
      n_j <= 0;  
      r_addr <= (others => '0');
      r_addr_vld <= '0';
      r_data <= (others => '0');
      r_data_vld <= '0'; 
      r_OK <= '0';  
      n_k <= 0;  
      
    elsif rising_edge(i_clk) then
      if i_en = '1' then
        r_addr_vld <= '0';
        r_data_vld <= '0';
        r_OK <= '0';   
        case convImg is
          when IDLE => 
            if i_start = '1' then
              convImg <= RAM_READ;
            end if;

          when RAM_READ =>
            r_addr <= conv_std_logic_vector((n_i + n_k) * IMG_COLUNM + n_j,  r_addr'length);
            r_addr_vld <= '1';
            n_k <= n_k + 1;
            if n_k = 2 then
              convImg <= WAIT_READ;  
            end if;
             
          when WAIT_READ =>  
            n_k <= 0;
            if r_flag = '1' then
              convImg <= SHIFT_MATRIX;  
            end if;
          when SHIFT_MATRIX =>
            n_j <= n_j + 1;
            s_data <= f_matrixShift(s_data, s_colunm);
            if n_j < 2 then
              convImg <= RAM_READ;    
            else
              convImg <= CALC_CONV;  
            end if;
            
          when CALC_CONV => 
            r_data <=  f_convImage(s_data, KERNEL_LIST(conv_integer(i_kernel)));
            r_data_vld <= '1'; 
            convImg <= CNT_CHECK;
            if n_j = IMG_COLUNM then
              n_i <= n_i + 1;
              n_j <= 0;
            end if;
    
          when CNT_CHECK => 
            r_data_vld <= '0';
            if n_i < IMG_ROW - 2 then
              convImg <= RAM_READ;
            else
              n_i <= 0;
              convImg <= OK;                               
            end if;
            
          when OK =>
            r_OK <= '1';  
            convImg <= IDLE;
          when others => NULL;                
        end case;
      end if;
    end if;        
  end process;
end Behavioral;
