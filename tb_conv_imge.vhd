library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use std.textio.ALL;
use work.konvolusyon_imge_paket.all;

entity tb_conv_imge is
end tb_conv_imge;

architecture Behavioral of tb_conv_imge is

    component konvolusyon_imge
    port( 
        i_clk           : in std_logic;
        i_rst           : in std_logic;
        i_en            : in std_logic;
        i_start         : in std_logic;
        i_data          : in std_logic_vector(VERI_UZUNLUGU - 1 downto 0);
        i_data_valid    : in std_logic;
        i_kernel        : in std_logic_vector(2 downto 0);
        o_addr          : out std_logic_vector(log2_int(IMGE_SATIR * IMGE_SUTUN) - 1 downto 0);
        o_addr_vld      : out std_logic;
        o_data          : out std_logic_vector(7 downto 0);
        o_data_vld      : out std_logic;
        o_OK         : out std_logic                
    );        
    end component;
        
    component block_ram 
    generic(
        VERI_UZUNLUGU : integer := 8;
        RAM_DERINLIGI : integer := 110
    );
    port(
        i_clk       : in std_logic;
        i_rst       : in std_logic;
        i_ram_en    : in std_logic;
        i_wr_en     : in std_logic;
        i_read_en   : in std_logic;
        i_data_addr : in std_logic_vector(log2_int(RAM_DERINLIGI) - 1 downto 0);
        i_data      : in std_logic_vector(VERI_UZUNLUGU - 1 downto 0);
        o_data      : out std_logic_vector(VERI_UZUNLUGU - 1 downto 0);
        o_data_vld  : out std_logic
    );
    end component;
    
    constant CLK_PERIOD  : time := 20 ns;
    constant IMG_PATH    : string := "C:\i_img.txt";
    constant IMG_WR_PATH : string := "D:\o_img.txt";
  
   
    type t_Konvolusyon_Imge  is (RAM_READ, RAM_WRITE, OK);
    signal r_Konvolusyon_Imge : t_Konvolusyon_Imge := RAM_WRITE;
    
    signal i_clk : std_logic := '0';
    signal i_rst : std_logic := '0';
    signal i_start : std_logic := '0';
    signal i_ram_en : std_logic := '1';
    signal o_data_vld : std_logic := '0';
    signal o_data : std_logic_vector(7 downto 0) := (others => '0');
    signal i_ram_data : std_logic_vector(VERI_UZUNLUGU - 1 downto 0) := (others => '0'); 
    signal i_ram_data_addr : std_logic_vector(log2_int(IMGE_SATIR * IMGE_SUTUN) - 1 downto 0) := (others => '0');
    signal o_ram_data : std_logic_vector(VERI_UZUNLUGU - 1 downto 0) := (others => '0'); 
    signal o_data_addr : std_logic_vector(log2_int(IMGE_SATIR * IMGE_SUTUN) - 1 downto 0) := (others => '0');
    signal o_ram_data_vld : std_logic := '0';        
    signal i_en : std_logic := '0';
    signal i_wr_en : std_logic := '0';
    signal i_read_en : std_logic := '0';        
    signal data_counter : integer := 0;
    signal o_data_addr_vld : std_logic := '0';  
    signal r_proc_ok : std_logic := '0';  

begin

    process
    begin
        i_clk <= '1';
        wait for CLK_PERIOD / 2;
        i_clk <= '0';
        wait for CLK_PERIOD / 2;
    end process;  

    process
        begin
        i_start <= '1';
        wait for CLK_PERIOD;
        i_start <= '0'; wait;
    end process;     
    
    process(i_clk)
        file dosya_okuma : text open read_mode is IMG_PATH;
        file dosya_yazma : text open write_mode is IMG_WR_PATH;
        variable satir_okuma : line;
        variable satir_yazma : line;
        variable data_okuma : integer;      
    begin
        if rising_edge(i_clk) then
            if o_data_vld = '1' then
                write(satir_yazma, conv_integer(o_data)); 
                writeline(dosya_yazma, satir_yazma);                
            end if;
            case r_Konvolusyon_Imge is
                when RAM_WRITE => 
                    if not endfile(dosya_okuma) then
                        readline(dosya_okuma, satir_okuma);
                        read(satir_okuma, data_okuma);
                        i_ram_data <= conv_std_logic_vector(data_okuma, VERI_UZUNLUGU);
                        i_ram_data_addr <= conv_std_logic_vector(data_counter, i_ram_data_addr'length);
                        i_en <= '0';
                        i_wr_en <= '1';
                        data_counter <= data_counter + 1;
                    else
                        r_Konvolusyon_Imge <= RAM_READ; 
                        i_wr_en <= '0';  
                    end if; 
                                   
                when RAM_READ => 
                    i_en <= '1';
                    i_ram_data_addr <= o_data_addr; 
                    i_read_en <= o_data_addr_vld ;
                    if r_proc_ok = '1' then
                        r_Konvolusyon_Imge <= OK; 
                    end if;
                    
                when OK => null;
                    
                when others => NULL;
            end case;
            
        end if;
    end process;     

    konvolusyon_imge_map : konvolusyon_imge
    port map( 
        i_clk => i_clk,
        i_rst => i_rst,
        i_en => i_en,
        i_start => i_start,
        i_data => o_ram_data, 
        i_data_valid => o_ram_data_vld,
        i_kernel => GAUSS,
        o_addr => o_data_addr,
        o_addr_vld => o_data_addr_vld,  
        o_data => o_data,
        o_data_vld => o_data_vld,
        o_OK => r_proc_ok                
    );   

    block_ram_map : block_ram 
    generic map(
        VERI_UZUNLUGU => VERI_UZUNLUGU,
        RAM_DERINLIGI => IMGE_SATIR * IMGE_SUTUN
    )
    port map(
        i_clk => i_clk,
        i_rst => i_rst,
        i_ram_en => i_ram_en,
        i_wr_en => i_wr_en,
        i_read_en => i_read_en,
        i_data_addr => i_ram_data_addr,
        i_data => i_ram_data,
        o_data => o_ram_data,
        o_data_vld => o_ram_data_vld
    );

end Behavioral;
