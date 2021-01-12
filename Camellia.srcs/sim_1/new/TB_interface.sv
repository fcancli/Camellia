`timescale 1ns/1ps 

module tb_camellia_interface();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------

  parameter CLK_HALF_PERIOD = 5;
  parameter CLK_PERIOD      = 2 * CLK_HALF_PERIOD;

  // The DUT address map.
  parameter ADDR_NAME0       = 8'h00;
  parameter ADDR_NAME1       = 8'h01;
  parameter ADDR_VERSION     = 8'h02;

  parameter ADDR_CTRL        = 8'h08;
  parameter CTRL_INIT_BIT    = 0;
  parameter CTRL_NEXT_BIT    = 1;
  parameter CTRL_ENCDEC_BIT  = 2;
  parameter CTRL_KEYLEN_BIT  = 3;

  parameter ADDR_STATUS      = 8'h09;
  parameter STATUS_READY_BIT = 0;
  parameter STATUS_VALID_BIT = 1;

  parameter ADDR_CONFIG      = 8'h0a;

  parameter ADDR_KEY0        = 8'h10;
  parameter ADDR_KEY1        = 8'h11;
  parameter ADDR_KEY2        = 8'h12;
  parameter ADDR_KEY3        = 8'h13;
  parameter ADDR_KEY4        = 8'h14;
  parameter ADDR_KEY5        = 8'h15;
  parameter ADDR_KEY6        = 8'h16;
  parameter ADDR_KEY7        = 8'h17;

  parameter ADDR_BLOCK0      = 8'h20;
  parameter ADDR_BLOCK1      = 8'h21;
  parameter ADDR_BLOCK2      = 8'h22;
  parameter ADDR_BLOCK3      = 8'h23;

  parameter ADDR_RESULT0     = 8'h30;
  parameter ADDR_RESULT1     = 8'h31;
  parameter ADDR_RESULT2     = 8'h32;
  parameter ADDR_RESULT3     = 8'h33;

  parameter AES_128_BIT_KEY = 0;
  parameter AES_256_BIT_KEY = 1;

  parameter AES_DECIPHER = 1'b0;
  parameter AES_ENCIPHER = 1'b1;


  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [31 : 0]  cycle_ctr;
  reg [31 : 0]  error_ctr;
  reg [31 : 0]  tc_ctr;

  reg [31 : 0]  read_data;
  reg [127 : 0] result_data;

  reg           tb_clk;
  reg           tb_reset_n;
  reg           tb_cs;
  reg           tb_we;
  reg [7  : 0]  tb_address;
  reg [31 : 0]  tb_write_data;
  wire [31 : 0] tb_read_data;


  //----------------------------------------------------------------
  // Device Under Test.
  //----------------------------------------------------------------
  Camellia_interface dut(
           .clk(tb_clk),
           .reset_n(tb_reset_n),
           .cs(tb_cs),
           .we(tb_we),
           .address(tb_address),
           .write_data(tb_write_data),
           .read_data(tb_read_data)
          );


  //----------------------------------------------------------------
  // clk_gen
  //
  // Always running clock generator process.
  //----------------------------------------------------------------
  always
    begin : clk_gen
      #CLK_HALF_PERIOD;
      tb_clk = !tb_clk;
    end // clk_gen


  //----------------------------------------------------------------
  // sys_monitor()
  //
  // An always running process that creates a cycle counter and
  // conditionally displays information about the DUT.
  //----------------------------------------------------------------
  always
    begin : sys_monitor
      cycle_ctr = cycle_ctr + 1;

      #(CLK_PERIOD);
    end




  //----------------------------------------------------------------
  // reset_dut()
  //
  // Toggle reset to put the DUT into a well known state.
  //----------------------------------------------------------------
  task reset_dut;
    begin
      $display("*** Toggle reset.");
      tb_reset_n = 0;

      #(10 * CLK_PERIOD);
      tb_reset_n = 1;
      $display("");
    end
  endtask // reset_dut


  //----------------------------------------------------------------
  // display_test_results()
  //
  // Display the accumulated test results.
  //----------------------------------------------------------------
  task display_test_results;
    begin
      if (error_ctr == 0)
        begin
          $display("*** All %02d test cases completed successfully", tc_ctr);
        end
      else
        begin
          $display("*** %02d tests completed - %02d test cases did not complete successfully.",
                   tc_ctr, error_ctr);
        end
    end
  endtask // display_test_results


  //----------------------------------------------------------------
  // init_sim()
  //
  // Initialize all counters and testbed functionality as well
  // as setting the DUT inputs to defined values.
  //----------------------------------------------------------------
  task init_sim;
    begin
      cycle_ctr     = 0;
      error_ctr     = 0;
      tc_ctr        = 0;

      tb_clk        = 0;
      tb_reset_n    = 1;

      tb_cs         = 0;
      tb_we         = 0;
      tb_address    = 8'h0;
      tb_write_data = 32'h0;
    end
  endtask // init_sim


  //----------------------------------------------------------------
  // write_word()
  //
  // Write the given word to the DUT using the DUT interface.
  //----------------------------------------------------------------
  task write_word(input [11 : 0] address,
                  input [31 : 0] word);
    begin
      tb_address = address;
      tb_write_data = word;
      tb_cs = 1;
      tb_we = 1;
      #(2 * CLK_PERIOD);
      tb_cs = 0;
      tb_we = 0;
    end
  endtask // write_word


  //----------------------------------------------------------------
  // write_block()
  //
  // Write the given block to the dut.
  //----------------------------------------------------------------
  task write_block(input [127 : 0] block);
    begin
      write_word(ADDR_BLOCK0, block[127  :  96]);
      write_word(ADDR_BLOCK1, block[95   :  64]);
      write_word(ADDR_BLOCK2, block[63   :  32]);
      write_word(ADDR_BLOCK3, block[31   :   0]);
    end
  endtask // write_block


  //----------------------------------------------------------------
  // read_word()
  //
  // Read a data word from the given address in the DUT.
  // the word read will be available in the global variable
  // read_data.
  //----------------------------------------------------------------
  task read_word(input [11 : 0]  address);
    begin
      tb_address = address;
      tb_cs = 1;
      tb_we = 0;
      #(CLK_PERIOD);
      read_data = tb_read_data;
      tb_cs = 0;
    end
  endtask // read_word


  //----------------------------------------------------------------
  // read_result()
  //
  // Read the result block in the dut.
  //----------------------------------------------------------------
  task read_result;
    begin
      read_word(ADDR_RESULT0);
      result_data[127 : 096] = read_data;
      read_word(ADDR_RESULT1);
      result_data[095 : 064] = read_data;
      read_word(ADDR_RESULT2);
      result_data[063 : 032] = read_data;
      read_word(ADDR_RESULT3);
      result_data[031 : 000] = read_data;
    end
  endtask // read_result


  //----------------------------------------------------------------
  // init_key()
  //
  // init the key in the dut by writing the given key and
  // key length and then trigger init processing.
  //----------------------------------------------------------------
  task init_key(input [255 : 0] key, input key_length);
    begin

      write_word(ADDR_KEY0, key[255  : 224]);
      write_word(ADDR_KEY1, key[223  : 192]);
      write_word(ADDR_KEY2, key[191  : 160]);
      write_word(ADDR_KEY3, key[159  : 128]);
      write_word(ADDR_KEY4, key[127  :  96]);
      write_word(ADDR_KEY5, key[95   :  64]);
      write_word(ADDR_KEY6, key[63   :  32]);
      write_word(ADDR_KEY7, key[31   :   0]);

      if (key_length)
        begin
          write_word(ADDR_CONFIG, 8'h02);
        end
      else
        begin
          write_word(ADDR_CONFIG, 8'h00);
        end

      write_word(ADDR_CTRL, 8'h01);

      #(100 * CLK_PERIOD);
    end
  endtask // init_key


  //----------------------------------------------------------------
  // ecb_mode_single_block_test()
  //
  // Perform ECB mode encryption or decryption single block test.
  //----------------------------------------------------------------
  task single_block_test(input [7 : 0]   tc_number,
                                  input           encdec,
                                  input [255 : 0] key,
                                  input           key_length,
                                  input [127 : 0] block,
                                  input [127 : 0] expected);
    begin
      $display("*** TC %0d ECB mode test started.", tc_number);
      tc_ctr = tc_ctr + 1;

      init_key(key, key_length);
      write_block(block);

      write_word(ADDR_CONFIG, (8'h00 + (key_length << 1)+ encdec));
      write_word(ADDR_CTRL, 8'h02);

      #(100 * CLK_PERIOD);

      read_result();

      if (result_data == expected)
        begin
          $display("*** TC %0d successful.", tc_number);
          $display("");
        end
      else
        begin
          $display("*** ERROR: TC %0d NOT successful.", tc_number);
          $display("Expected: 0x%032x", expected);
          $display("Got:      0x%032x", result_data);
          $display("");

          error_ctr = error_ctr + 1;
        end
    end
  endtask // ecb_mode_single_block_test


  //----------------------------------------------------------------
  // aes_test()
  //
  // Main test task will perform complete NIST test of AES.
  //----------------------------------------------------------------
  task aes_test;
    reg [255 : 0] camellia_128_key;

    reg [127 : 0] plaintext0;
    reg [127 : 0] plaintext1;
    reg [127 : 0] plaintext2;
    reg [127 : 0] plaintext3;

    reg [127 : 0] enc_128_expected0;
    reg [127 : 0] enc_128_expected1;
    reg [127 : 0] enc_128_expected2;
    reg [127 : 0] enc_128_expected3;


    begin
      camellia_128_key = 256'hFEDCBA98765432100123456789ABCDEF00000000000000000000000000000000;

      plaintext0 = 128'h00000000000000000000000000040000;
      plaintext1 = 128'h00000000000000000000000000008000;
      plaintext2 = 128'h00000000000000000000000000004000;
      plaintext3 = 128'h00000000000000000000000000002000;

      enc_128_expected0 = 128'hE9F1FEB03648C01C0F3BBD8749094395;
      enc_128_expected1 = 128'h4D73D3048D85C10557DD0170D910F393;
      enc_128_expected2 = 128'h9D031BC46ACDD2FBB009C2D2AF06D66A;
      enc_128_expected3 = 128'h7DC1AA8EB13C4130F7F63CFDEAA0A670;


      $display("ECB 128 bit key tests");
      $display("---------------------");
     single_block_test(8'h01, AES_ENCIPHER, camellia_128_key, AES_128_BIT_KEY,
                       plaintext0, enc_128_expected0);

     single_block_test(8'h02, AES_ENCIPHER, camellia_128_key, AES_128_BIT_KEY,
                      plaintext1, enc_128_expected1);

     single_block_test(8'h03, AES_ENCIPHER, camellia_128_key, AES_128_BIT_KEY,
                       plaintext2,enc_128_expected2);

     single_block_test(8'h04, AES_ENCIPHER, camellia_128_key, AES_128_BIT_KEY,
                       plaintext3, enc_128_expected3);


     single_block_test(8'h05, AES_DECIPHER, camellia_128_key, AES_128_BIT_KEY,
                      enc_128_expected0, plaintext0);

     single_block_test(8'h06, AES_DECIPHER, camellia_128_key, AES_128_BIT_KEY,
                       enc_128_expected1, plaintext1);

     single_block_test(8'h07, AES_DECIPHER, camellia_128_key, AES_128_BIT_KEY,
                       enc_128_expected2, plaintext2);

     single_block_test(8'h08, AES_DECIPHER, camellia_128_key, AES_128_BIT_KEY,
                                 enc_128_expected3, plaintext3);

    end
  endtask // aes_test


  //----------------------------------------------------------------
  // main
  //
  // The main test functionality.
  //----------------------------------------------------------------
  initial
    begin : main
      $display("   -= Testbench for AES started =-");
      $display("    ==============================");
      $display("");

      init_sim();
      reset_dut();
      aes_test();

      display_test_results();

      $display("");
      $display("*** AES simulation done. ***");
      $finish;
    end // main
endmodule // tb_aes