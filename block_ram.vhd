library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.convolution_pkg.all;

entity block_ram_0 is
  generic(
    DATA_WIDTH : integer := 8;
    RAM_DEPTH  : integer := 110
  );
  port(
    i_clk : in std_logic;
    i_rst : in std_logic;
    i_ram_en : in std_logic;
    i_wr_en : in std_logic;
    i_read_en : in std_logic;
    i_data_addr : in std_logic_vector(log2_int(RAM_DEPTH) - 1 downto 0);
    i_data : in std_logic_vector(DATA_WIDTH - 1 downto 0);
    o_data : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    o_data_vld : out std_logic
  );
end block_ram_0;
	
architecture Behavioral of block_ram_0 is
	
  type BRAM_DATA_t is array (0 to RAM_DEPTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0) ; 
  signal BRAM_DATA : BRAM_DATA_t := (others =>(others => '0'));
	
begin
	
  process(i_clk, i_rst)
  begin
    if i_rst = '1' then
      BRAM_DATA <= (others =>(others => '0'));

    elsif rising_edge(i_clk) then
      if i_ram_en = '1' then
        if i_read_en = '1' then
          o_data <= BRAM_DATA( conv_integer( i_data_addr));
          o_data_vld <= '1';
        else
          o_data_vld <= '0';
        end if;
        if i_wr_en = '1' then
          BRAM_DATA(conv_integer(i_data_addr)) <= i_data;
        end if;
      end if;
    end if;
  end process;
end Behavioral;
