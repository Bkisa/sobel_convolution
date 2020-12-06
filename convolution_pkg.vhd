library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

package convolution_pkg is

  constant IMG_ROW    : integer := 256;
  constant IMG_COLUNM : integer := 256;
  constant DATA_WIDTH : integer := 8;

  type DATA_t is array (0 to 2) of std_logic_vector(DATA_WIDTH - 1 downto 0);
  type DATA_MATRIX is array (0 to 2) of DATA_t;
    
  type KERNEL_ARRAY is array (0 to 2) of integer;
  type KERNEL_MATRIX is array (0 to 2) of KERNEL_ARRAY;   
  
  type KERNEL_LIST_t is array (0 to 7) of KERNEL_MATRIX;
  constant KERNEL_LIST : KERNEL_LIST_t := 
          (((1, 2, 1), (0, 0, 0), (-1, -2, -1)),
           ((1, 0, -1), (2, 0, -2), (1, 0, -1)),
           ((1, 1, 1), (0, 0, 0), (-1, -1, -1)),
           ((1, 0, -1), (2, 0, -2), (1, 0, -1)),
           ((0, 0, 0), (0, 1, 0), (0, 0, -1)),
           ((0, 1, 0), (1, 0, 1), (0, 1, 0)),
           ((-1, -1, -1), (-1, 8, -1), (-1, -1, -1)),
           ((1, 2, 1), (2, 4, 2), (1, 2, 1)));                                             
                                                 
  constant HORIZONTAL_SOBEL     : std_logic_vector(2 downto 0) := "000";    
  constant VERTICAL_SOBEL       : std_logic_vector(2 downto 0) := "001"; 
  constant HORIZONTAL_PREWIT    : std_logic_vector(2 downto 0) := "010"; 
  constant VERTICAL_PREWIT      : std_logic_vector(2 downto 0) := "011";  
  constant SHIFT_OUT            : std_logic_vector(2 downto 0) := "100";   
  constant LOW_PASS             : std_logic_vector(2 downto 0) := "101";     
  constant HIGH_PASS            : std_logic_vector(2 downto 0) := "110";  
  constant GAUSS                : std_logic_vector(2 downto 0) := "111";  
  
  function log2_int(in_giris : integer) return integer;
  function f_matrixShift(Kernel : DATA_MATRIX; Tek_Sutun : DATA_t) return DATA_MATRIX;
  function f_convImage(VERI : DATA_MATRIX; KERNEL : KERNEL_MATRIX) return std_logic_vector;

end convolution_pkg;
	
package body convolution_pkg is

  function f_convImage(VERI : DATA_MATRIX; KERNEL : KERNEL_MATRIX) return std_logic_vector is
    variable Toplam : integer;
  begin
    Toplam := 0;
    for n_i in 0 to 2 loop
      for n_j in 0 to 2 loop
        Toplam := Toplam +  conv_integer(VERI(n_i)(n_j)) * KERNEL(2 - n_i)(2 - n_j);  
      end loop;
    end loop;
    if Toplam > 255 then
      Toplam := 255;
    elsif Toplam < 0 then
      Toplam := 0;
    end if;
    return conv_std_logic_vector(Toplam, 8);        
  end f_convImage;

  function f_matrixShift(Kernel : DATA_MATRIX; Tek_Sutun : DATA_t) return DATA_MATRIX is
    variable Kernel_v : DATA_MATRIX;
    variable Tek_Sutun_v : DATA_t;
  begin
    Kernel_v := Kernel;
    Tek_Sutun_v := Tek_Sutun;        
    for n_j in 0 to 1 loop
      for n_i in 0 to 2 loop
        Kernel_v(n_i)(n_j) := Kernel_v(n_i)(n_j + 1); 
      end loop;
    end loop;
    for n_j in 0 to 2 loop
      Kernel_v(n_j)(2) := Tek_Sutun_v(n_j); 
    end loop;
    return Kernel_v;        
  end f_matrixShift;   

  function log2_int(in_giris : integer) return integer is
    variable sonuc : integer;
  begin
    for n_i in 0 to 31 loop
      if (in_giris <= (2 ** n_i)) then
        sonuc := n_i;
        exit;
      end if;
    end loop;
    return sonuc;
  end function;
end package body;
