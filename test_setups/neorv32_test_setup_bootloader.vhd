-- ================================================================================ --
-- NEORV32 - Test Setup Using The UART-Bootloader To Upload And Run Executables     --
-- -------------------------------------------------------------------------------- --
-- The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32              --
-- Copyright (c) NEORV32 contributors.                                              --
-- Copyright (c) 2020 - 2024 Stephan Nolting. All rights reserved.                  --
-- Licensed under the BSD-3-Clause license, see LICENSE for details.                --
-- SPDX-License-Identifier: BSD-3-Clause                                            --
-- ================================================================================ --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library neorv32;
use neorv32.neorv32_package.all;

entity neorv32_test_setup_bootloader is
  generic (
    -- adapt these for your setup --
    CLOCK_FREQUENCY   : natural := 100000000; -- clock frequency of clk_i in Hz
    MEM_INT_IMEM_SIZE : natural := 16*1024;   -- size of processor-internal instruction memory in bytes
    MEM_INT_DMEM_SIZE : natural := 8*1024     -- size of processor-internal data memory in bytes
  );
  port (
    -- Global control --
    clk_i       : in  std_ulogic; -- global clock, rising edge
    reset      : in  std_ulogic; -- global reset, high-active, async
    -- GPIO --
    gpio_o      : out std_ulogic_vector(7 downto 0); -- parallel output
    -- UART0 --
    uart0_txd_o : out std_ulogic; -- UART0 send data
    uart0_rxd_i : in  std_ulogic;  -- UART0 receive data
    -- JTAG -- 
    jtag_tck_i  : in  std_logic;
    jtag_tdi_i  : in  std_logic;
    jtag_tdo_o  : out std_logic;
    jtag_tms_i  : in  std_logic
  );
end entity;

architecture neorv32_test_setup_bootloader_rtl of neorv32_test_setup_bootloader is

  signal con_gpio_out : std_ulogic_vector(63 downto 0);
  signal reset_inv: std_logic; 

begin

  -- The Core Of The Problem ----------------------------------------------------------------
  ---------------------------------------------------------------------------------------------
  neorv32_top_inst: neorv32_top
  generic map (
    -- Clocking --
    CLOCK_FREQUENCY   => CLOCK_FREQUENCY,   -- clock frequency of clk_i in Hz
    -- Boot Configuration --
    BOOT_MODE_SELECT  => 0,                 -- boot via internal bootloader
    -- RISC-V CPU Extensions --
    RISCV_ISA_C       => true,              -- implement compressed extension?
    RISCV_ISA_M       => true,              -- implement mul/div extension?
    RISCV_ISA_Zicntr  => true,              -- implement base counters?
    -- Internal Instruction memory --
    MEM_INT_IMEM_EN   => true,              -- implement processor-internal instruction memory
    MEM_INT_IMEM_SIZE => MEM_INT_IMEM_SIZE, -- size of processor-internal instruction memory in bytes
    -- Internal Data memory --
    MEM_INT_DMEM_EN   => true,              -- implement processor-internal data memory
    MEM_INT_DMEM_SIZE => MEM_INT_DMEM_SIZE, -- size of processor-internal data memory in bytes
    -- Processor peripherals --
    IO_GPIO_NUM       => 8,                 -- number of GPIO input/output pairs (0..64)
    IO_MTIME_EN       => true,              -- implement machine system timer (MTIME)?
    IO_UART0_EN       => true,               -- implement primary universal asynchronous receiver/transmitter (UART0)?
    -- jtag
    OCD_EN            => true
  )
  port map (
    -- Global control --
    clk_i       => clk_i,        -- global clock, rising edge
    rstn_i      => reset_inv,       -- global reset, low-active, async
    -- GPIO (available if IO_GPIO_NUM > 0) --
    gpio_o      => con_gpio_out, -- parallel output
    -- primary UART0 (available if IO_UART0_EN = true) --
    uart0_txd_o => uart0_txd_o,  -- UART0 send data
    uart0_rxd_i => uart0_rxd_i,   -- UART0 receive data
    
    jtag_tck_i => jtag_tck_i,     -- serial clock
    jtag_tdi_i => jtag_tdi_i,     -- serial data input
    jtag_tdo_o => jtag_tdo_o,     -- serial data output
    jtag_tms_i => jtag_tms_i   
  );

  -- GPIO output --
  gpio_o <= con_gpio_out(7 downto 0);
  reset_inv <= NOT reset;

end architecture;
