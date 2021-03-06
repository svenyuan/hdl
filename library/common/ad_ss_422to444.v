// ***************************************************************************
// ***************************************************************************
// Copyright 2011(c) Analog Devices, Inc.
//
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//     - Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     - Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in
//       the documentation and/or other materials provided with the
//       distribution.
//     - Neither the name of Analog Devices, Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//     - The use of this software may or may not infringe the patent rights
//       of one or more patent holders.  This license does not release you
//       from the requirement that you obtain separate licenses from these
//       patent holders to use this software.
//     - Use of the software either in source or binary form, must be run
//       on or directly connected to an Analog Devices Inc. component.
//
// THIS SOFTWARE IS PROVIDED BY ANALOG DEVICES "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
// INCLUDING, BUT NOT LIMITED TO, NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
// PARTICULAR PURPOSE ARE DISCLAIMED.
//
// IN NO EVENT SHALL ANALOG DEVICES BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, INTELLECTUAL PROPERTY
// RIGHTS, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
// THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ***************************************************************************
// ***************************************************************************
// ***************************************************************************
// ***************************************************************************
// Input must be RGB or CrYCb in that order, output is CrY/CbY

module ad_ss_422to444 (

  // 422 inputs

  clk,
  s422_de,
  s422_sync,
  s422_data,

  // 444 outputs

  s444_sync,
  s444_data);

  // parameters

  parameter   CR_CB_N = 0;
  parameter   DELAY_DATA_WIDTH = 16;
  localparam  DW = DELAY_DATA_WIDTH - 1;

  // 422 inputs

  input           clk;
  input           s422_de;
  input   [DW:0]  s422_sync;
  input   [15:0]  s422_data;

  // 444 inputs

  output  [DW:0]  s444_sync;
  output  [23:0]  s444_data;

  // internal registers

  reg             cr_cb_sel = 'd0;
  reg             s422_de_d = 'd0;
  reg     [DW:0]  s422_sync_d = 'd0;
  reg             s422_de_2d = 'd0;
  reg      [7:0]  s422_Y_d;
  reg      [7:0]  s422_CbCr_d;
  reg      [7:0]  s422_CbCr_2d;
  reg     [DW:0]  s444_sync = 'd0;
  reg     [23:0]  s444_data = 'd0;
  reg     [ 8:0]  s422_CbCr_avg;

  // internal wires

  wire    [ 7:0]  s422_Y;
  wire    [ 7:0]  s422_CbCr;

  // Input format is
  // [15:8] Cb/Cr
  // [ 7:0] Y
  //
  // Output format is
  // [23:15] Cr
  // [16: 8] Y
  // [ 7: 0] Cb

  assign s422_Y = s422_data[7:0];
  assign s422_CbCr = s422_data[15:8];


  // first data on de assertion is cb (0x0), then cr (0x1).
  // previous data is held when not current

  always @(posedge clk) begin
    if (s422_de_d == 1'b1) begin
      cr_cb_sel <= ~cr_cb_sel;
    end else begin
      cr_cb_sel <= CR_CB_N;
    end
  end

  // pipe line stages

  always @(posedge clk) begin
    s422_de_d <= s422_de;
    s422_sync_d <= s422_sync;
    s422_de_2d <= s422_de_d;
    s422_Y_d <= s422_Y;

    s422_CbCr_d <= s422_CbCr;
    s422_CbCr_2d <= s422_CbCr_d;
  end

  // If both the left and the right sample are valid do the average, otherwise
  // use the only valid.
  always @(s422_de_2d, s422_de, s422_CbCr, s422_CbCr_2d)
  begin
    if (s422_de == 1'b1 && s422_de_2d)
      s422_CbCr_avg <= s422_CbCr + s422_CbCr_2d;
    else if (s422_de == 1'b1)
      s422_CbCr_avg <= {s422_CbCr, 1'b0};
    else
      s422_CbCr_avg <= {s422_CbCr_2d, 1'b0};
  end

  // 444 outputs

  always @(posedge clk) begin
    s444_sync <= s422_sync_d;
    s444_data[15:8] <= s422_Y_d;
    if (cr_cb_sel) begin
      s444_data[23:16] <= s422_CbCr_d;
      s444_data[ 7: 0] <= s422_CbCr_avg[8:1];
    end else begin
      s444_data[23:16] <= s422_CbCr_avg[8:1];
      s444_data[ 7: 0] <= s422_CbCr_d;
    end
  end

endmodule

// ***************************************************************************
// ***************************************************************************
